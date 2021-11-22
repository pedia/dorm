import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart' as ffi;
import 'package:path/path.dart' as p;
import '../lib/_sqlparser_ffi.dart';
import '../lib/sqlparser.dart';
import 'package:test/test.dart';

String _getPath() {
  final cjsonExamplePath = Directory.current.absolute.path;
  var path = p.join(cjsonExamplePath, 'rslib/target/debug');
  if (Platform.isMacOS) {
    path = p.join(path, 'libsqlparser_ffi.dylib');
  } else if (Platform.isWindows) {
    path = p.join(path, 'Debug', 'sqlparser_ffi.dll');
  } else {
    path = p.join(path, 'libsqlparser_ffi.so');
  }
  return path;
}

void main() {
  test('RawTest', () {
    final lib = DynamicLibrary.open(_getPath());
    expect(lib, isNotNull);

    final parser = SqlParserFfi(lib);
    expect(parser, isNotNull);

    final errorOut = ffi.malloc<Pointer<Int8>>();

    final res = parser.parseAsJson('select 1'.toNativeUtf8().cast(), errorOut);
    expect(res, 0);

    final ptr = errorOut.value;
    ffi.malloc.free(errorOut);

    if (ptr.address == 0) {
      return;
    }

    final js = errorOut.value.cast<ffi.Utf8>().toDartString();
    expect(js, isNotEmpty);
    expect(json.decode(js), isNotNull);
  });

  test('MySQLTest', () {
    final parser = SqlParser();
    parser.extract('show databases');
    parser.extract('show tables');
  });

  test('WrapTest', () {
    final parser = SqlParser();

    {
      final rlist = parser.extract('select 1');
      expect(rlist.length, 1);
      expect(rlist[0], isNotNull);
      expect(rlist[0].columns[0].expr!.value, '1');
    }

    {
      final rlist = parser.extract('select "s"');
      expect(rlist[0].columns[0].name, 's');
    }

    {
      final rlist = parser.extract('select 1 a');
      expect(rlist[0].columns[0].name, 'a');
    }

    {
      final rlist = parser.extract('select a, b from c');
      expect(rlist[0].columns[0].name, 'a');
      expect(rlist[0].columns[1].name, 'b');
      expect(rlist[0].tables[0].names, ['c']);
    }

    {
      final rlist = parser.extract('select f(a)');
      expect(rlist[0].columns[0].expr!.name, 'f');
      expect(rlist[0].columns[0].expr!.args![0], 'a');
    }

    {
      final rlist = parser.extract('select f(a, b)');
      expect(rlist[0].columns[0].expr!.name, 'f');
      expect(rlist[0].columns[0].expr!.args, ['a', 'b']);
    }
    // parser.extract('select f(a) from c');
    // parser.extract('select f(a) as e from c');
  });

  test('TpchSQLTest', () {
    final fns = [
      'tpch/01.sql.json',
      'tpch/02.sql.json',
      'tpch/03.sql.json',
      'tpch/04.sql.json',
      'tpch/05.sql.json',
      'tpch/06.sql.json',
      'tpch/07.sql.json',
      'tpch/08.sql.json',
      'tpch/09.sql.json',
      'tpch/10.sql.json',
      'tpch/11.sql.json',
      'tpch/12.sql.json',
      'tpch/13.sql.json',
      'tpch/14.sql.json',
      'tpch/15.sql.json',
      'tpch/16.sql.json',
      'tpch/17.sql.json',
      'tpch/18.sql.json',
      'tpch/19.sql.json',
      'tpch/19_1.sql.json',
      'tpch/20.sql.json',
      'tpch/21.sql.json',
      'tpch/22.sql.json',
    ];
    for (final fn in fns) {
      final js = File(fn).readAsStringSync();
      final jm = json.decode(js);
      final rs = SqlParser().convert(jm);
      expect(rs, isList);
      expect(rs, isNotEmpty);
    }
  });
}

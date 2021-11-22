import 'dart:ffi';
import 'dart:io';
import 'dart:convert';

import 'package:ffi/ffi.dart' as ffi;
import 'package:path/path.dart' as p;
import '_sqlparser_ffi.dart';
import 'statement.dart';
export 'statement.dart';

///
class SqlParser {
  static String libPath() {
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

  final _ffi = SqlParserFfi(DynamicLibrary.open(libPath()));

  String? parse(String sql) {
    final out = ffi.malloc<Pointer<Int8>>();

    final res = _ffi.parseAsJson(sql.toNativeUtf8().cast(), out);
    if (res != 0) {
      return null;
    }

    final ptr = out.value;
    ffi.malloc.free(out);

    if (ptr.address == 0) {
      return null;
    }

    final js = out.value.cast<ffi.Utf8>().toDartString();
    return js;
  }

  List<Statement> convert(Object o) {
    return (o as List)
        .map((i) => Statement.from(i))
        .where((stmt) => stmt != null)
        .whereType<Statement>()
        .toList();
  }

  List<Statement> extract(String sql) {
    final js = parse(sql);
    if (js == null) {
      return [];
    }
    return convert(json.decode(js));
  }
}

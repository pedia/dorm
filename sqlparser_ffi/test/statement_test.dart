import 'dart:convert';
import 'dart:io';

import '../lib/statement.dart';
import 'package:test/test.dart';

main() {
  test('StatementTest', () {
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
      final jm = json.decode(File(fn).readAsStringSync());

      final stmt = Statement.from((jm as List).first);
      expect(stmt, isNotNull);
      expect(stmt is Query, isTrue);

      Query q = stmt as Query;
      expect(q.body, isNotNull);
      expect(q.body.select, isNotNull);
      expect(q.body.select!.from_.isNotEmpty, isTrue);
    }
  });
}

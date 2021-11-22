import 'package:mysqldb/mysqldb_server.dart';
import 'package:test/test.dart';

class MockDb with Database {}

main() {
  test('DBTest', () {
    final db = MockDb();
    final rs = db.query('select a from b');
    print(rs!.encode());
    print(rs.toString());
  });
}

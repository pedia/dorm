import 'package:mysqldb/impl.dart';

import 'package:mysqldb/src/stream.dart';
import 'package:test/test.dart';
import 'hexstring.dart';

main() {
  test('QueryTest', () {
    // 0700 0002 00fb fb02 0000 00                   ...........
    final showdb = bytesFromHexed(
        '0f00 0000 0373 686f 7720 6461 7461 6261' //   .....show databa
        '7365 73'); //                                 ses

    final p = Packet.parse(InputStream.from(showdb));

    final q = QueryCommand.parse(p.inputStream);
    expect(q.sql, 'show databases');
    expect(q.command, Command.query);

    final dest = Packet(0, q.encode()).encode();
    expect(dest, showdb);
  });

  // 0c00 0000 0373 686f 7720 7461 626c 6573   .....show tables
  // 0700 0000 0468 656c 6c6f 00                   .....hello.
  test('ExecuteStatementTest', () {
    final e = bytesFromHexed(
        '1200 0000 1701 0000    0000 01 00 00 00 00 01' // ................
        '0f 00 03 66 6f 6f');
    expect(e.length, 0x12 + 4);
    final p = Packet.parse(InputStream.from(e));

    // final q = ExecuteStatement.parse(p.inputStream);
    // expect(q.command, Command.stmtExecute);
  });
}

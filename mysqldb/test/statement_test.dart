import 'package:mysqldb/impl.dart';
import 'package:mysqldb/src/debug.dart';

import 'package:test/test.dart';

main() {
  test('QueryTest', () {
    // 0700 0002 00fb fb02 0000 00                   ...........
    final showdb = bytesFromHexed(
        '0f00 0000 0373 686f 7720 6461 7461 6261' //   .....show databa
        '7365 73'); //                                 ses

    final p = Packet.parse(InputStream.from(showdb));

    final q = CommandPacket.parse(p.inputStream);
    expect((q as QueryCommand).sql, 'show databases');
    expect(q.command, Command.query);

    final dest = Packet(0, q.encode()).encode();
    expect(dest, showdb);

    // demo:
    CommandPacket.parse(Packet.parse(
            InputStream.from(bytesFromHexed('05 00 00 00 02 74 65 73 74')))
        .inputStream);

    final t = CommandPacket.parse(
      Packet.parse(
        InputStream.from(
          bytesFromHexed('05 00 00 00 02 74 65 73 74'),
        ),
      ).inputStream,
    );

    expect(t.command, Command.initDb);
    expect((t as QueryCommand).sql, 'test');

    // 07 00 00 01 00 00 00 02    00 00 00
  });

  test('PrepareResponseTest', () {
    final bytes = bytesFromHexed(''
        '0c 00 00 01 00 01 00 00    00 01 00 02 00 00 00 00' // ................
        '17 00 00 02 03 64 65 66    00 00 00 01 3f 00 0c 3f' // .....def....?..?
        '00 00 00 00 00 fd 80 00    00 00 00 17 00 00 03 03' // ................
        '64 65 66 00 00 00 01 3f    00 0c 3f 00 00 00 00 00' // def....?..?.....
        'fd 80 00 00 00 00 05 00    00 04 fe 00 00 02 00 1a' // ................
        '00 00 05 03 64 65 66 00    00 00 04 63 6f 6c 31 00' // ....def....col1.
        '0c 3f 00 00 00 00 00 fd    80 00 1f 00 00 05 00 00' // .?..............
        '06 fe 00 00 02 00' //                                   ......
        );
    final res = PrepareStatementResponse.parse(InputStream.from(bytes));
    expect(res.status, 0);
    expect(res.stmtId, 1);
    expect(res.numColumns, 1);
    expect(res.numParams, 2);
    expect(res.warningCount, 0);
    expect(res.params[0].name, '?');
    expect(res.params[0].columnType, Field.typeVarString);
    expect(res.params[0].flags, 128); // ?

    expect(res.params[1].name, '?');

    expect(res.cols[0].name, 'col1');
    expect(res.encode(), bytes);

    // an empty response
    final bytes2 = bytesFromHexed(''
        '0c 00 00 01 00 01 00 00    00 00 00 00 00 00 00 00');
    final psr2 = PrepareStatementResponse.parse(InputStream.from(bytes2));
    expect(psr2.status, 0);
    expect(psr2.stmtId, 1);
    expect(psr2.numColumns, 0);
    expect(psr2.numParams, 0);
    expect(psr2.encode(), bytes2);
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

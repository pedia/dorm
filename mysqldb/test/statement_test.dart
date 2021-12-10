import 'dart:typed_data';
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

  test('ExecuteStatementTest', () {
    {
      final e = bytesFromHexed(
          '1200 0000 1701 0000    0000 01 00 00 00 00 01' // ................
          '0f 00 03 66 6f 6f' //                             ...foo
          );
      final psr = PrepareStatementResponse(
        status: 0,
        stmtId: 1,
        numParams: 1,
        params: [
          ColumnDefinition.varString(table: 'table', name: '', columnLength: 81)
        ],
        cols: [],
      );

      final es = ExecuteStatement.parse(InputStream.from(e), psr);
      expect(es.command, Command.stmtExecute);
    }

    {
      final e = bytesFromHexed(''
          '0f 00 00 00 17 01 00 00    00 00 01 00 00 00 00 01' // ................
          '01 80 01' //                                              ...
          );
      final psr = PrepareStatementResponse(
        status: 0,
        stmtId: 1,
        numParams: 1,
        params: [
          ColumnDefinition.varString(table: 'table', name: '', columnLength: 81)
        ],
        cols: [],
      );

      final es = ExecuteStatement.parse(InputStream.from(e), psr);
      expect(es.command, Command.stmtExecute);
    }
  });

  test('BinaryValueTest', () {
    {
      final bytes = bytesFromHexed('66 66 66 66 66 66 24 40');
      // InputStream.from(bytes);
      final d = ByteData.view(bytes.buffer).getFloat64(0);
      // expect(d, 10.2);
    }

    {
      final bytes = bytesFromHexed('33 33 23 41');
      final d = ByteData.view(bytes.buffer).getFloat32(0);
      // expect(d, 10.2);
    }
  });

  test('BinaryResultSetTest', () {
    final bytes = bytesFromHexed(''
        '01 00 00 01 01|1a 00 00    02 03 64 65 66 00 00 00' // ..........def...
        '04 63 6f 6c 31 00 0c 08    00 06 00 00 00 fd 00 00' // .col1...........
        '1f 00 00|05 00 00 03 fe    00 00 02 00|09 00 00 04' // ................
        '00 00 06 66 6f 6f 62 61    72|05 00 00 05 fe 00 00' // ...foobar.......
        '02 00');
    final brs = BinaryResultSet.parse(InputStream.from(bytes));
    expect(brs, isNotNull);
    expect(brs.rows.first.values.first, 'foobar');
  });

  test('ConcatStatementTest', () {
    // concat(?, ?), 'a', 'bc'
    final preresp = bytesFromHexed(''
        '0c 00 00 01 00 03 00 00    00 01 00 02 00 00 00 00' // ................
        '17 00 00 02 03 64 65 66    00 00 00 01 3f 00 0c 3f' // .....def....?..?
        '00 00 00 00 00 fd 80 00    00 00 00 17 00 00 03 03' // ................
        '64 65 66 00 00 00 01 3f    00 0c 3f 00 00 00 00 00' // def....?..?.....
        'fd 80 00 00 00 00 05 00    00 04 fe 00 00 01 00 17' // ................
        '00 00 05 03 64 65 66 00    00 00 01 63 00 0c 3f 00' // ....def....c..?.
        '00 00 00 00 fd 80 00 1f    00 00 05 00 00 06 fe 00' // ................
        '00 01 00' //                                           ...
        );

    final e17 = bytesFromHexed(''
        '15 00 00 00 17 03 00 00    00 00 01 00 00 00 00 01' // ................
        '0f 00 0f 00 01 61 02 62    63' //                      .....a.bc
        );

    final e17resp = bytesFromHexed(''
        '01 00 00 01 01 17 00 00    02 03 64 65 66 00 00 00' // ..........def...
        '01 63 00 0c 2d 00 0c 00    00 00 fd 00 00 1f 00 00' // .c..-...........
        '05 00 00 03 fe 00 00 01    00 06 00 00 04 00 00 03' // ................
        '61 62 63 05 00 00 05 fe    00 00 01 00' //             abc.........
        );

    final psr = PrepareStatementResponse.parse(InputStream.from(preresp));
    final es = ExecuteStatement.parse(InputStream.from(e17), psr);
    expect(es.command, Command.stmtExecute);
    expect(es.values.length, psr.numParams);
    expect(es.values[0].value, 'a');
    expect(es.values[1].value, 'bc');

    final rs = BinaryResultSet.parse(InputStream.from(e17resp));
    expect(rs, isNotNull);
    expect(rs.rows.length, 1);
    expect(rs.rows.first.values.length, 1);
    expect(rs.rows.first.values.first, 'abc');
  });

  test('PlusStatementTest', () {
    // ?+?, 1, 3.14
    final preresp = bytesFromHexed(''
        '0c 00 00 01 00 02 00 00    00 01 00 02 00 00 00 00' //  ................
        '17 00 00 02 03 64 65 66    00 00 00 01 3f 00 0c 3f' //  .....def....?..?
        '00 00 00 00 00 fd 80 00    00 00 00 17 00 00 03 03' //  ................
        '64 65 66 00 00 00 01 3f    00 0c 3f 00 00 00 00 00' //  def....?..?.....
        'fd 80 00 00 00 00 05 00    00 04 fe 00 00 01 00 17' //  ................
        '00 00 05 03 64 65 66 00    00 00 01 63 00 0c 3f 00' //  ....def....c..?.
        '11 00 00 00 05 80 00 00    00 00 05 00 00 06 fe 00' //  ................
        '00 01 00' //                                            ...
        );

    final e17 = bytesFromHexed(''
        '19 00 00 00 17 02 00 00    00 00 01 00 00 00 00 01' // ................
        '01 80 05 00 01 1f 85 eb    51 b8 1e 09 40' //          ........Q...@
        );
    final e17resp = bytesFromHexed(''
        '01 00 00 01 01 17 00 00    02 03 64 65 66 00 00 00' // ..........def...
        '01 63 00 0c 3f 00 17 00    00 00 05 80 00 1f 00 00' // .c..?...........
        '05 00 00 03 fe 00 00 01    00 0a 00 00 04 00 00 90' // ................
        'c2 f5 28 5c 8f 10 40 05    00 00 05 fe 00 00 01 00' // ..(\..@.........
        );
    final psr = PrepareStatementResponse.parse(InputStream.from(preresp));
    final es = ExecuteStatement.parse(InputStream.from(e17), psr);
    expect(es.command, Command.stmtExecute);

    final rs = BinaryResultSet.parse(InputStream.from(e17resp));
    expect(rs, isNotNull);
  });

  test('StatementCloseTest', () {
    final bytes = bytesFromHexed('05 00 00 00 19 02 00 00    00');
    final p = Packet.parse(InputStream.from(bytes));
    final rs = CommandPacket.parse(p.inputStream);
    expect(rs is CloseStatement, isTrue);
    expect((rs as CloseStatement).stmtId, 2);
  });

  test('EmptyQuestionMarkTest', () {
// select curdate() as dt, empty cds
    final bytes = bytesFromHexed(''
        '01 00 00 01 01|18 00 00    02 03 64 65 66 00 00 00' // ..........def...
        '02 64 74 00 0c 3f 00 0a    00 00 00 0a 81 00 00 00' // .dt..?..........
        '00 05 00 00 03 fe 00 00    00 00 07 00 00 04 00 00' // ................
        '04 e5 07 0c 0a 05 00 00    05 fe 00 00 00 00' //       ..............
        );
    final rs = BinaryResultSet.parse(InputStream.from(bytes));
    expect(rs.cds[0].columnType, Field.typeDate);
    expect(rs.rows[0].values.first, DateTime(2021, 12, 10));

// ##
// T 127.0.0.1:58820 -> 127.0.0.1:3337 [AP] #1911
//   05 00 00 00 1a 01 00 00    00                         .........
  });

  test('WithTypesStatementTest', () {
// cur.execute("select ?, ?, ?, ?, curdate() as dt", [None, 1, 3.14, 'foo'])
    final preresp = bytesFromHexed(''
        '0c 00 00 01 00 01 00 00    00 05 00 04 00 00 00 00' // ................
        '17 00 00 02 03 64 65 66    00 00 00 01 3f 00 0c 3f' // .....def....?..?
        '00 00 00 00 00 fd 80 00    00 00 00 17 00 00 03 03' // ................
        '64 65 66 00 00 00 01 3f    00 0c 3f 00 00 00 00 00' // def....?..?.....
        'fd 80 00 00 00 00 17 00    00 04 03 64 65 66 00 00' // ...........def..
        '00 01 3f 00 0c 3f 00 00    00 00 00 fd 80 00 00 00' // ..?..?..........
        '00 17 00 00 05 03 64 65    66 00 00 00 01 3f 00 0c' // ......def....?..
        '3f 00 00 00 00 00 fd 80    00 00 00 00 05 00 00 06' // ?...............
        'fe 00 00 00 00 17 00 00    07 03 64 65 66 00 00 00' // ..........def...
        '01 3f 00 0c 3f 00 00 00    00 00 fd 80 00 00 00 00' // .?..?...........
        '17 00 00 08 03 64 65 66    00 00 00 01 3f 00 0c 3f' // .....def....?..?
        '00 00 00 00 00 fd 80 00    00 00 00 17 00 00 09 03' // ................
        '64 65 66 00 00 00 01 3f    00 0c 3f 00 00 00 00 00' // def....?..?.....
        'fd 80 00 00 00 00 17 00    00 0a 03 64 65 66 00 00' // ...........def..
        '00 01 3f 00 0c 3f 00 00    00 00 00 fd 80 00 00 00' // ..?..?..........
        '00 18 00 00 0b 03 64 65    66 00 00 00 02 64 74 00' // ......def....dt.
        '0c 3f 00 0a 00 00 00 0a    81 00 00 00 00 05 00 00' // .?..............
        '0c fe 00 00 00 00' //                                    ......
        );
// ##
// T 127.0.0.1:59180 -> 127.0.0.1:3337 [AP] #2227
//   05 00 00 00 1a 01 00 00    00                         .........
// ##
// T 127.0.0.1:3337 -> 127.0.0.1:59180 [AP] #2229
//   07 00 00 01 00 00 00 00    00 00 00                   ...........
// ##
// T 127.0.0.1:59180 -> 127.0.0.1:3337 [AP] #2231
//   21 00 00 00 17 01 00 00    00 00 01 00 00 00 01 01    !...............
//   06 00 01 80 05 00 0f 00    01 1f 85 eb 51 b8 1e 09    ............Q...
//   40 03 66 6f 6f                                        @.foo
// ##
// T 127.0.0.1:3337 -> 127.0.0.1:59180 [AP] #2233
    final e17resp = bytesFromHexed(''
        '01 00 00 01 05 17 00 00    02 03 64 65 66 00 00 00' // ..........def...
        '01 3f 00 0c 3f 00 00 00    00 00 06 80 00 00 00 00' // .?..?...........
        '17 00 00 03 03 64 65 66    00 00 00 01 3f 00 0c 3f' // .....def....?..?
        '00 04 00 00 00 01 a1 00    00 00 00 17 00 00 04 03' // ................
        '64 65 66 00 00 00 01 3f    00 0c 3f 00 17 00 00 00' // def....?..?.....
        '05 81 00 1f 00 00 17 00    00 05 03 64 65 66 00 00' // ...........def..
        '00 01 3f 00 0c 2d 00 0c    00 00 00 fd 01 00 1f 00' // ..?..-..........
        '00 18 00 00 06 03 64 65    66 00 00 00 02 64 74 00' // ......def....dt.
        '0c 3f 00 0a 00 00 00 0a    81 00 00 00 00 05 00 00' // .?..............
        '07 fe 00 00 00 00 14 00    00 08 00 04 01 1f 85 eb' // ................
        '51 b8 1e 09 40 03 66 6f    6f 04 e5 07 0c 09 05 00' // Q...@.foo.......
        '00 09 fe 00 00 00 00' //                               .......
        );

    final rs = BinaryResultSet.parse(InputStream.from(e17resp));
    expect(rs.cds.length, 5);
    expect(rs.cds[0].columnType, Field.typeNull);
    expect(rs.cds[1].columnType, Field.typeTiny);
    expect(rs.cds[2].columnType, Field.typeDouble);
    expect(rs.cds[3].columnType, Field.typeVarString);
    expect(rs.cds[4].columnType, Field.typeDate);

    // None, 1, 3.14, 'foo', curdate
    expect(rs.rows.first.values.first, isNull);
    expect(rs.rows.first.values[1], 1);
    expect(rs.rows.first.values[2], 3.14);
    expect(rs.rows.first.values[3], 'foo');
    expect(rs.rows.first.values[4], DateTime(2021, 12, 09));
  });
}

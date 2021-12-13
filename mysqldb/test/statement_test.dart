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
    // TODO: https://dev.mysql.com/doc/internals/en/binary-protocol-value.html
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
    expect(brs.rows.first.values.first.value, 'foobar');
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
    expect(rs.rows.first.values[0].value, 'abc');
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

    final dest = Packet.build(0, rs).encode();
    expect(dest, bytes);
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
    expect(rs.rows[0].values.first.value, DateTime(2021, 12, 10));

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
    expect(rs.rows.first.values[0].value, isNull);
    expect(rs.rows.first.values[1].value, 1);
    expect(rs.rows.first.values[2].value, 3.14);
    expect(rs.rows.first.values[3].value, 'foo');
    expect(rs.rows.first.values[4].value, DateTime(2021, 12, 09));
  });

  test('TimesTest', () {
    /// SELECT MAKETIME(12,15,?), UNIX_TIMESTAMP(), UTC_TIME(),
    /// STR_TO_DATE('2003-01-02 10:30:00.000123', '%Y-%m-%d %H:%i:%s.%f')", [0]
    final e17resp = bytesFromHexed(''
        '01 00 00 01 07 27 00 00    02 03 64 65 66 00 00 00' // .....'....def...
        '11 4d 41 4b 45 54 49 4d    45 28 31 32 2c 31 35 2c' // .MAKETIME(12,15,
        '3f 29 00 0c 3f 00 0a 00    00 00 0b 80 00 00 00 00' // ?)..?...........
        '17 00 00 03 03 64 65 66    00 00 00 01 41 00 0c 2d' // .....def....A..-
        '00 04 00 00 00 fd 01 00    1f 00 00 26 00 00 04 03' // ...........&....
        '64 65 66 00 00 00 10 55    4e 49 58 5f 54 49 4d 45' // def....UNIX_TIME
        '53 54 41 4d 50 28 29 00    0c 3f 00 0b 00 00 00 08' // STAMP()..?......
        '81 00 00 00 00 18 00 00    05 03 64 65 66 00 00 00' // ..........def...
        '02 41 41 00 0c 2d 00 08    00 00 00 fd 01 00 1f 00' // .AA..-..........
        '00 20 00 00 06 03 64 65    66 00 00 00 0a 55 54 43' // . ....def....UTC
        '5f 54 49 4d 45 28 29 00    0c 3f 00 08 00 00 00 0b' // _TIME()..?......
        '81 00 00 00 00 19 00 00    07 03 64 65 66 00 00 00' // ..........def...
        '03 41 41 41 00 0c 2d 00    0c 00 00 00 fd 01 00 1f' // .AAA..-.........
        '00 00 57 00 00 08 03 64    65 66 00 00 00 41 53 54' // ..W....def...AST
        '52 5f 54 4f 5f 44 41 54    45 28 27 32 30 30 33 2d' // R_TO_DATE('2003-
        '30 31 2d 30 32 20 31 30    3a 33 30 3a 30 30 2e 30' // 01-02 10:30:00.0
        '30 30 31 32 33 27 2c 20    27 25 59 2d 25 6d 2d 25' // 00123', '%Y-%m-%
        '64 20 25 48 3a 25 69 3a    25 73 2e 25 66 27 29 00' // d %H:%i:%s.%f').
        '0c 3f 00 1a 00 00 00 0c    80 00 06 00 00 05 00 00' // .?..............
        '09 fe 00 00 00 00 32 00    00 0a 00 00 00 08 00 00' // ......2.........
        '00 00 00 0c 0f 00 01 41    2e f0 b2 61 00 00 00 00' // .......A..a....
        '02 41 41 08 00 00 00 00    00 06 0e 06 03 41 41 41' // .AA..........AAA
        '0b d3 07 01 02 0a 1e 00    7b 00 00 00 05 00 00 0b' // ........{.......
        'fe 00 00 00 00' //                                      .....
        );
    final rs = BinaryResultSet.parse(InputStream.from(e17resp));
    expect(rs.cds.length, 7);
    expect(rs.cds[0].columnType, Field.typeTime);
    expect(rs.cds[2].columnType, Field.typeLonglong);
    expect(rs.cds[4].columnType, Field.typeTime);
    expect(rs.cds[6].columnType, Field.typeDatetime);

    /// (datetime.timedelta(seconds=44100), 1639116846,
    /// datetime.timedelta(seconds=22446),
    /// datetime.datetime(2003, 1, 2, 10, 30, 0, 123))
    expect(rs.rows.first.values[0].value, Duration(seconds: 44100));
    expect(rs.rows.first.values[1].value, 'A');
    expect(rs.rows.first.values[2].value, 1639116846);
    expect(rs.rows.first.values[3].value, 'AA');
    expect(rs.rows.first.values[4].value, Duration(seconds: 22446));
    expect(rs.rows.first.values[5].value, 'AAA');
    expect(rs.rows.first.values[6].value,
        DateTime.parse('2003-01-02 10:30:00.000123'));
    // TODO: more test
  });
}

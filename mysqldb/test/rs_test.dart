import 'package:mysqldb/impl.dart';
import 'package:mysqldb/src/debug.dart';
import 'package:test/test.dart';
import 'hexstring.dart';

main() {
  /// show databases
  test('ResultSetTest0', () {
    final rsbytes = bytesFromHexed(''
        '01 00 00 01 01 4b 00 00    02 03 64 65 66 12 69 6e' // .....K....def.in
        '66 6f 72 6d 61 74 69 6f    6e 5f 73 63 68 65 6d 61' // formation_schema
        '08 53 43 48 45 4d 41 54    41 08 53 43 48 45 4d 41' // .SCHEMATA.SCHEMA
        '54 41 08 44 61 74 61 62    61 73 65 0b 53 43 48 45' // TA.Database.SCHE
        '4d 41 5f 4e 41 4d 45 0c    21 00 c0 00 00 00 fd 01' // MA_NAME.!.......
        '00 00 00 00 05 00 00 03    fe 00 00 22 00 13 00 00' // ..........."....
        '04 12 69 6e 66 6f 72 6d    61 74 69 6f 6e 5f 73 63' // ..information_sc
        '68 65 6d 61 06 00 00 05    05 6d 79 73 71 6c 13 00' // hema.....mysql..
        '00 06 12 70 65 72 66 6f    72 6d 61 6e 63 65 5f 73' // ...performance_s
        '63 68 65 6d 61 04 00 00    07 03 73 79 73 05 00 00' // chema.....sys...
        '08 04 74 65 73 74 05 00    00 09 fe 00 00 22 00' //     ..test.......".
        );
    final rs = ResultSet.parse(InputStream.from(rsbytes));
    expect(
      rs.serverStatus,
      ServerStatus.statusAutocommit | ServerStatus.statusNoIndexUsed,
    );
    expect(rs.columns.length, 1);
    expect(rs.columns.first.catalog, 'def');
    expect(rs.columns.first.charset, Charset.utf8);
    expect(rs.columns.first.columnLength, 192);
    expect(rs.columns.first.columnType, Field.typeVarString);
    expect(rs.columns.first.decimals, 0);
    expect(rs.columns.first.name, 'Database');
    expect(rs.columns.first.nextLength, 12);
    expect(rs.columns.first.orgName, 'SCHEMA_NAME');
    expect(rs.columns.first.orgTable, 'SCHEMATA');
    expect(rs.columns.first.schema, 'information_schema');
    expect(rs.columns.first.table, 'SCHEMATA');
    expect(rs.rows.length, 5);
  });

  /// select @@version_comment limit 1
  test('ResultSetTest1', () {
    final bytes = bytesFromHexed(''
        '01 00 00 01 01 27 00 00    02 03 64 65 66 00 00 00' // .....'....def...
        '11 40 40 76 65 72 73 69    6f 6e 5f 63 6f 6d 6d 65' // .@@version_comme
        '6e 74 00 0c 21 00 54 00    00 00 fd 00 00 1f 00 00' // nt..!.T.........
        '05 00 00 03 fe 00 00 02    00 1d 00 00 04 1c 4d 79' // ..............My
        '53 51 4c 20 43 6f 6d 6d    75 6e 69 74 79 20 53 65' // SQL Community Se
        '72 76 65 72 20 28 47 50    4c 29 05 00 00 05 fe 00' // rver (GPL)......
        '00 02 00' //                                           ...
        );

    final rs = ResultSet.parse(InputStream.from(bytes));
    expect(rs.encode(), bytes);

    expect(rs.serverStatus, ServerStatus.statusAutocommit);
    expect(rs.columns.length, 1);
    expect(rs.columns.first.catalog, 'def');
    expect(rs.columns.first.charset, Charset.utf8);
    expect(rs.columns.first.columnLength, 84);
    expect(rs.columns.first.columnType, Field.typeVarString);
    expect(rs.columns.first.decimals, 31);
    expect(rs.columns.first.name, '@@version_comment');
    expect(rs.columns.first.nextLength, 12);
    expect(rs.columns.first.orgName, '');
    expect(rs.columns.first.orgTable, '');
    expect(rs.columns.first.schema, '');
    expect(rs.columns.first.table, '');
    expect(rs.rows.length, 1);
  });

  /// show tables
  test('ResultSetTest2', () {
    final bytes = bytesFromHexed(''
        '01 00 00 01 01 56 00 00    02 03 64 65 66 12 69 6e' // .....V....def.in
        '66 6f 72 6d 61 74 69 6f    6e 5f 73 63 68 65 6d 61' // formation_schema
        '0b 54 41 42 4c 45 5f 4e    41 4d 45 53 0b 54 41 42' // .TABLE_NAMES.TAB
        '4c 45 5f 4e 41 4d 45 53    0e 54 61 62 6c 65 73 5f' // LE_NAMES.Tables_
        '69 6e 5f 74 65 73 74 0a    54 41 42 4c 45 5f 4e 41' // in_test.TABLE_NA
        '4d 45 0c 21 00 c0 00 00    00 fd 01 00 00 00 00 05' // ME.!............
        '00 00 03 fe 00 00 22 00    04 00 00 04 03 66 6f 6f' // ......"......foo
        '06 00 00 05 05 74 61 62    6c 65 06 00 00 06 05 74' // .....table.....t
        '79 70 65 73 05 00 00 07    fe 00 00 22 00' //          ypes.......".
        );

    final rs = ResultSet.parse(InputStream.from(bytes));
    expect(rs.encode(), bytes);

    expect(rs.columns.length, 1);
    expect(rs.columns.first.catalog, 'def');
    expect(rs.columns.first.charset, Charset.utf8);
    expect(rs.columns.first.columnLength, 192);
    expect(rs.columns.first.columnType, Field.typeVarString);
    expect(rs.columns.first.decimals, 0);
    expect(rs.columns.first.name, 'Tables_in_test');
    expect(rs.columns.first.nextLength, 12);
    expect(rs.columns.first.orgName, 'TABLE_NAME');
    expect(rs.columns.first.orgTable, 'TABLE_NAMES');
    expect(rs.columns.first.schema, 'information_schema');
    expect(rs.columns.first.table, 'TABLE_NAMES');
    expect(rs.rows.length, 3);
  });

  test('ResultSetTest4', () {
    final rsbytes = bytesFromHexed(''
        '0100 0001 0d29 0000 0203 6465' //  .j.......)....de
        '6605 6d79 7371 6c05 7479 7065 7305 7479' //  f.mysql.types.ty 1
        '7065 7302 6964 0269 640c 3f00 0b00 0000' //  pes.id.id.?.....
        '0303 5000 0000 2900 0003 0364 6566 056d' //  ..P...)....def.m
        '7973 716c 0574 7970 6573 0574 7970 6573' //  ysql.types.types
        '0276 7302 7673 0c21 002c 0100 00fd 0000' //  .vs.vs.!.,......
        '0000 0029 0000 0403 6465 6605 6d79 7371' //  ...)....def.mysq
        '6c05 7479 7065 7305 7479 7065 7302 6373' //  l.types.types.cs
        '0263 730c 2100 0f00 0000 fe00 0000 0000' //  .cs.!...........
        '2900 0005 0364 6566 056d 7973 716c 0574' //  )....def.mysql.t
        '7970 6573 0574 7970 6573 0274 6902 7469' //  ypes.types.ti.ti 10
        '0c3f 0004 0000 0001 0000 0000 0029 0000' //  .?...........)..
        '0603 6465 6605 6d79 7371 6c05 7479 7065' //  ..def.mysql.type
        '7305 7479 7065 7302 7369 0273 690c 3f00' //  s.types.si.si.?.
        '0600 0000 0200 0000 0000 2900 0007 0364' //  ..........)....d
        '6566 056d 7973 716c 0574 7970 6573 0574' //  ef.mysql.types.t
        '7970 6573 026c 6902 6c69 0c3f 000b 0000' //  ypes.li.li.?....
        '0003 0000 0000 0029 0000 0803 6465 6605' //  .......)....def.
        '6d79 7371 6c05 7479 7065 7305 7479 7065' //  mysql.types.type
        '7302 6269 0262 690c 3f00 1400 0000 0800' //  s.bi.bi.?....... 20
        '0000 0000 2900 0009 0364 6566 056d 7973' //  ....)....def.mys
        '716c 0574 7970 6573 0574 7970 6573 0264' //  ql.types.types.d
        '6902 6469 0c3f 000c 0000 00f6 0000 0400' //  i.di.?..........
        '0029 0000 0a03 6465 6605 6d79 7371 6c05' //  .)....def.mysql.
        '7479 7065 7305 7479 7065 7302 6474 0264' //  types.types.dt.d
        '740c 3f00 1300 0000 0c80 0000 0000 2900' //  t.?...........).
        '000b 0364 6566 056d 7973 716c 0574 7970' //  ...def.mysql.typ
        '6573 0574 7970 6573 0273 7402 7374 0c3f' //  es.types.st.st.?
        '0013 0000 0007 8124 0000 0027 0000 0c03' //  .......$...'.... 30
        '6465 6605 6d79 7371 6c05 7479 7065 7305' //  def.mysql.types.
        '7479 7065 7301 6501 650c 2100 0300 0000' //  types.e.e.!.....
        'fe00 0100 0000 2700 000d 0364 6566 056d' //  ......'....def.m
        '7973 716c 0574 7970 6573 0574 7970 6573' //  ysql.types.types
        '0162 0162 0c3f 00ff ff00 00fc 9000 0000' //  .b.b.?..........
        '0027 0000 0e03 6465 6605 6d79 7371 6c05' //  .'....def.mysql. 36
        '7479 7065 7305 7479 7065 7301 6701 670c' //  types.types.g.g.
        '3f00 ffff ffff ff90 0000 0000 0500 000f' //  ?...............
        'fe00 0022 0021 0000 1001 31fb fbfb fbfb' //  ...".!....1.....
        'fbfb fb13 3230 3231 2d31 312d 3037 2031' //  ....2021-11-07.1
        '333a 3138 3a35 36fb fbfb 4c00 0011 0132' //  3:18:56...L....2
        '0568 656c 6c6f 0463 6363 6301 3101 3301' //  .hello.cccc.1.3.
        '3501 3806 332e 3134 3030 1332 3032 312d' //  5.8.3.1400.2021-
        '3131 2d30 3720 3133 3a32 303a 3430 1332' //  11-07.13:20:40.2
        '3032 312d 3131 2d30 3720 3133 3a32 303a' //  021-11-07.13:20:
        '3430 0179 0462 6262 62fb 3f00 0012 0133' //  40.y.bbbb.?....3
        '0000 0131 0133 0135 0138 0633 2e31 3430' //  ...1.3.5.8.3.140
        '3013 3230 3231 2d31 312d 3037 2031 333a' //  0.2021-11-07.13:
        '3332 3a35 3713 3230 3231 2d31 312d 3037' //  32:57.2021-11-07
        '2031 333a 3332 3a35 3701 6e00 fb05 0000' //  .13:32:57.n.....
        '13fe 0000 2200' //   ....".
        );

    final rs = ResultSet.parse(InputStream.from(rsbytes));

    expect(
      rs.serverStatus,
      ServerStatus.statusAutocommit | ServerStatus.statusNoIndexUsed,
    );
    expect(rs.columns.length, 13);

    final c0 = rs.columns[0];
    expect(c0.columnType, 3);
    expect(c0.columnLength, 11);

    expect(rs.rows.length, 3);
    expect(rs.rows[0][0].value, 1);

    // null string
    expect(rs.rows[0][1].value, isNull);
    expect(rs.rows[0][1].encode(), [0xfb]);
    expect(rs.rows[0][1].def.columnType, Field.typeVarString);

    expect(rs.rows[0][2].value, isNull);
    expect(rs.rows[0][2].def.columnType, Field.typeString);

    // empty string
    expect(rs.rows[2][1].value, '');
    expect(rs.rows[2][1].encode(), [0]);
    expect(rs.rows[2][2].value, '');

    final dest = rs.encode();
    expect(dest.length, rsbytes.length);
    expect(dest, rsbytes);
  });

  test('ResultSetTest5', () {
    final bytes = bytesFromHexed(''
        '01 00 00 01 03 26 00 00    02 03 64 65 66 04 74 65' //  .....&....def.te
        '73 74 03 66 6f 6f 03 66    6f 6f 03 62 61 72 03 62' //  st.foo.foo.bar.b
        '61 72 0c 21 00 f4 02 00    00 fd 00 00 00 00 00 26' //  ar.!. ... .....&
        '00 00 03 03 64 65 66 04    74 65 73 74 03 66 6f 6f' //  ....def.test.foo
        '03 66 6f 6f 03 7a 65 67    03 7a 65 67 0c 21 00 f1' //  .foo.zeg.zeg.!.
        '02 00 00 fd 00 00 00 00    00 26 00 00 04 03 64 65' //  ... .....&....de
        '66 04 74 65 73 74 03 66    6f 6f 03 66 6f 6f 03 6d' //  f.test.foo.foo.m
        '65 64 03 6d 65 64 0c 3f    00 0b 00 00 00 03 00 00' //  ed.med.?........
        '00 00 00 05 00 00 05 fe    00 00 22 00 01 02 00 06' //  ....... ..".....
        'fc fc 00 61 61 61 61 61    61 61 61 61 61 61 61 61' //    .aaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 31 32 33 34 35' //  aaaaaaaaaaa12345
        '36 37 38 39 30 31 32 33    34 35 36 37 38 39 30 31' //  6789012345678901
        '32 33 34 35 36 37 38 39    30 31 32 33 34 35 36 37' //  2345678901234567
        '38 39 30 31 32 33 34 35    36 37 38 39 30 31 32 fc' //  890123456789012
        'fb 00 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //   .aaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 61 61 61 61 61 61' //  aaaaaaaaaaaaaaaa
        '61 61 61 61 61 61 61 61    61 61 31 32 33 34 35 36' //  aaaaaaaaaa123456
        '37 38 39 30 31 32 33 34    35 36 37 38 39 30 31 32' //  7890123456789012
        '33 34 35 36 37 38 39 30    31 32 33 34 35 36 37 38' //  3456789012345678
        '39 30 31 32 33 34 35 36    37 38 39 30 31 03 32 35' //  9012345678901.25
        '31 08 00 00 07 01 62 01    63 03 32 35 30 08 00 00' //  1.....b.c.250...
        '08 01 62 01 64 03 32 35    31 08 00 00 09 01 62 01' //  ..b.d.251.....b.
        '65 03 32 35 32 05 00 00    0a fe 00 00 22 00'); //      e.252...."..".

    final rs = ResultSet.parse(InputStream.from(bytes));
    // print(rs);

    expect(rs.rows[0][0].value,
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1234567890123456789012345678901234567890123456789012');
    expect(rs.rows[0][1].value,
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa123456789012345678901234567890123456789012345678901');
    expect(rs.rows[0][2].value, 251);

    expect(rs.rows[1][0].value, 'b');
    expect(rs.rows[1][1].value, 'c');
    expect(rs.rows[1][2].value, 250);

    expect(rs.rows[2][0].value, 'b');
    expect(rs.rows[2][1].value, 'd');
    expect(rs.rows[2][2].value, 251);

    expect(rs.rows[3][0].value, 'b');
    expect(rs.rows[3][1].value, 'e');
    expect(rs.rows[3][2].value, 252);

    expect(rs.encode(), bytes);
  });

  test('FieldListResponseTest', () {
    final bytes = bytesFromHexed(''
        '31 00 00 01 03 64 65 66    04 74 65 73 74 05 74 61' // 1....def.test.ta
        '62 6c 65 05 74 61 62 6c    65 06 63 6f 6c 75 6d 6e' // ble.table.column
        '06 63 6f 6c 75 6d 6e 0c    21 00 2c 01 00 00 fd 00' // .column.!.,.....
        '00 00 00 00 fb 05 00 00    02 fe 00 00 02 00' //       ..............
        );
    // desc `table`;
    // +--------+--------------+------+-----+---------+-------+
    // | Field  | Type         | Null | Key | Default | Extra |
    // +--------+--------------+------+-----+---------+-------+
    // | column | varchar(100) | YES  |     | NULL    |       |
    // +--------+--------------+------+-----+---------+-------+
    final cd = ColumnDefinition.parse(
        Packet.parse(InputStream.from(bytes)).inputStream, true);
    expect(cd.catalog, 'def');
    expect(cd.schema, 'test');
    expect(cd.table, 'table');
    expect(cd.orgTable, 'table');
    expect(cd.name, 'column');
    expect(cd.columnType, Field.typeVarString);

    final i1 = InputStream.from(bytes);
    final fds = FieldListResponse.parse(i1);
    expect(fds.defs.length, 1);
    expect(i1.byteLeft, 0);
  });

  test('MultipleCDFieldListResponseTest', () {
    final bytes = bytesFromHexed(''
        '27 00 00 01 03 64 65 66    04 74 65 73 74 03 66 6f' // '....def.test.fo
        '6f 03 66 6f 6f 03 62 61    72 03 62 61 72 0c 21 00' // o.foo.bar.bar.!.
        'f4 02 00 00 fd 00 00 00    00 00 fb 27 00 00 02 03' // ...........'....
        '64 65 66 04 74 65 73 74    03 66 6f 6f 03 66 6f 6f' // def.test.foo.foo
        '03 7a 65 67 03 7a 65 67    0c 21 00 f1 02 00 00 fd' // .zeg.zeg.!......
        '00 00 00 00 00 fb 27 00    00 03 03 64 65 66 04 74' // ......'....def.t
        '65 73 74 03 66 6f 6f 03    66 6f 6f 03 6d 65 64 03' // est.foo.foo.med.
        '6d 65 64 0c 3f 00 0b 00    00 00 03 00 00 00 00 00' // med.?...........
        'fb 05 00 00 04 fe 00 00    02 00' //                   ..........
        );
    // desc foo;
    // +-------+--------------+------+-----+---------+-------+
    // | Field | Type         | Null | Key | Default | Extra |
    // +-------+--------------+------+-----+---------+-------+
    // | bar   | varchar(252) | YES  |     | NULL    |       |
    // | zeg   | varchar(251) | YES  |     | NULL    |       |
    // | med   | int(11)      | YES  |     | NULL    |       |
    // +-------+--------------+------+-----+---------+-------+
    final i1 = InputStream.from(bytes);
    final fds = FieldListResponse.parse(i1);
    expect(fds.defs.length, 3);
    expect(i1.byteLeft, 0);

    expect(fds.encode(), bytes);
  });

  test('CDWithDefaultValueFieldListResponseTest', () {
    final bytes = bytesFromHexed(''
        '27 00 00 01 03 64 65 66    04 74 65 73 74 03 66 6f' // '....def.test.fo
        '6f 03 66 6f 6f 03 62 61    72 03 62 61 72 0c 21 00' // o.foo.bar.bar.!.
        'f4 02 00 00 fd 00 00 00    00 00 fb 2b 00 00 02 03' // ...........+....
        '64 65 66 04 74 65 73 74    03 66 6f 6f 03 66 6f 6f' // def.test.foo.foo
        '03 7a 65 67 03 7a 65 67    0c 21 00 f1 02 00 00 fd' // .zeg.zeg.!......
        '00 00 00 00 00 04 7a 65    65 65 27 00 00 03 03 64' // ......zeee'....d
        '65 66 04 74 65 73 74 03    66 6f 6f 03 66 6f 6f 03' // ef.test.foo.foo.
        '6d 65 64 03 6d 65 64 0c    3f 00 0b 00 00 00 03 00' // med.med.?.......
        '00 00 00 00 fb 05 00 00    04 fe 00 00 02 00' //       ..............
        );
    // mysql> desc foo;
    // +-------+--------------+------+-----+---------+-------+
    // | Field | Type         | Null | Key | Default | Extra |
    // +-------+--------------+------+-----+---------+-------+
    // | bar   | varchar(252) | YES  |     | NULL    |       |
    // | zeg   | varchar(251) | YES  |     | zeee    |       |
    // | med   | int(11)      | YES  |     | NULL    |       |
    // +-------+--------------+------+-----+---------+-------+
    final i1 = InputStream.from(bytes);
    final fds = FieldListResponse.parse(i1);
    expect(fds.defs.length, 3);
    expect(i1.byteLeft, 0);

    expect(fds.encode(), bytes);
  });
}

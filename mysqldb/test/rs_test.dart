import 'package:mysqldb/impl.dart';

import 'package:mysqldb/src/stream.dart';
import 'package:mysqldb/src/debug.dart';
import 'package:test/test.dart';
import 'hexstring.dart';

main() {
  test('ResultSetTest1', () {
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
    print(rs);

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

  test('ResultSetTest2', () {
    final bytes = bytesFromHexed(''
        '01 00 00 01 01 30 00 00    02 03 64 65 66 04 74 65' //  .....0....def.te
        '73 74 05 74 61 62 6c 65    05 74 61 62 6c 65 06 63' //  st.table.table.c
        '6f 6c 75 6d 6e 06 63 6f    6c 75 6d 6e 0c 21 00 2c' //  olumn.column.!.,
        '01 00 00 fd 00 00 00 00    00 05 00 00 03 fe 00 00' //  ... ......... ..
        '22 00 04 00 00 04 03 66    6f 6f 04 00 00 05 03 62' //  "......foo.....b
        '61 72 05 00 00 06 fe 00    00 22 00'); //               ar.... ..".

    final rs = ResultSet.parse(InputStream.from(bytes));
    expect(rs.encode(), bytes);
  });

  test('ResultSetTest3', () {
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
}

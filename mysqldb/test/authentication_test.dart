import 'dart:typed_data';

import 'package:mysqldb/impl.dart';
import 'package:mysqldb/src/flag.dart';

import 'package:mysqldb/src/debug.dart';
import 'package:test/test.dart';

main() {
  test('HexedStringTest', () {
    expect(bytesFromHexed('4b54 1815'), [0x4b, 0x54, 0x18, 0x15]);
    expect(bytesFromHexed('4b541815'), [0x4b, 0x54, 0x18, 0x15]);
  });

  test('PacketInstreamTest', () {
    final p = Packet(1, Uint8List.fromList([]));
    expect(identical(p.inputStream, p.inputStream), isTrue);
  });

  test('mysql-5.8-authentication-test', () {
    final scramble = Uint8List.fromList([
      67, 98, 15, 90, 72, 93, 46, 103, //
      97, 52, 64, 30, 73, 17, 20, 8,
      98, 27, 123, 1
    ]);

    final dest = bytesFromHexed(''
        '8da6 ff01 0000 0001 ff00 0000'
        '0000 0000 0000 0000 0000 0000 0000 0000'
        '0000 0000 6d6d 6d6d 6d00 204b 155f ada9'
        '783b d1ca 2633 8754 0e25 928c 6dd1 80c0'
        '1d54 8211 30e3 e005 f7c3 cb66 6666 6666'
        '0063 6163 6869 6e67 5f73 6861 325f 7061'
        '7373 776f 7264 0077 035f 6f73 086f 7378'
        '3130 2e31 3609 5f70 6c61 7466 6f72 6d06'
        '7838 365f 3634 0f5f 636c 6965 6e74 5f76'
        '6572 7369 6f6e 0638 2e30 2e32 320c 5f63'
        '6c69 656e 745f 6e61 6d65 086c 6962 6d79'
        '7371 6c04 5f70 6964 0532 3738 3930 076f'
        '735f 7573 6572 056d 6f72 646f 0c70 726f'
        '6772 616d 5f6e 616d 6505 6d79 7371 6c');

    final sa = ServerAuthentication.parse(InputStream.fromList(dest));

    expect(sa.clientFlag, Flag(33531533));
    expect(sa.maxPacketSize, 16777216);
    expect(sa.charset, 0xff);
    expect(sa.user, 'mmmmm');
    expect(sa.scramble, [
      75, 21, 95, 173, 169, 120, 59, 209, //
      202, 38, 51, 135, 84, 14, 37, 146, 140,
      109, 209, 128, 192, 29, 84, 130,
      17, 48, 227, 224, 5, 247, 195, 203
    ]);
    expect(sa.db, 'fffff');
    expect(sa.authPlugin, 'caching_sha2_password');
    expect(sa.options, {
      'program_name': 'mysql',
      'os_user': 'mordo',
      '_pid': '27890',
      '_client_name': 'libmysql',
      '_client_version': '8.0.22',
      '_platform': 'x86_64',
      '_os': 'osx10.16'
    });

    final hash = Sha256Password().scramble(scramble, 'aaaaaa');
    expect(hash, sa.scramble);
  });

  test('mysql-client-5.7-authentication-test', () {
    final s2c1 = '4a00 0000 0a35 2e37 2e33 3600' // ....5.7.36.
        '0300 0000 7a2a 7b0a 7c35 4863 00ff ff08' //  ....z*{.|5Hc....
        '0200 ffc1 1500 0000 0000 0000 0000 0028' //  ...............(
        '685b 4138 3004 303e 6a38 2f00 6d79 7371' //  h[A80.0>j8/.mysq
        '6c5f 6e61 7469 7665 5f70 6173 7377 6f72' //  l_native_passwor
        '6400'; // d.
    var p = Packet.parse(InputStream.from(bytesFromHexed(s2c1)));
    final h1 = Handshake.parse(p.inputStream);
    expect(h1, isNotNull);
    expect(h1.authPlugin, 'mysql_native_password');
    expect(h1.scramble, [
      122, 42, 123, 10, 124, 53, 72, 99, //
      40, 104, 91, 65, 56, 48, 4, 48, 62, 106, 56, 47
    ]);
    expect(h1.serverCharset, 8);
    expect(h1.serverCapability.value, 3254779903);
    expect(h1.serverStatus, 2);
    expect(h1.version, '5.7.36');
    expect(h1.threadId, 3);

    // c2s1
    final c2s1 = '2000 0001 85ae ff01 0000 0001' // ..G{............
        'ff00 0000 0000 0000 0000 0000 0000 0000' // ................
        '0000 0000 0000 0000'; // ........
    p = Packet.parse(InputStream.from(bytesFromHexed(c2s1)));
    final r = SslRequest.parse(p.inputStream);
    expect(r.clientFlag, Capability(33533573));
    expect(r.maxPaketSize, 16777216);
    expect(r.charset, 0xff);
  });

  test('mysql-client-5.6-to-server-5.7', () {
    final s2c1 = '4a00 0000 0a35 2e37 2e33 3600' //  ...}J....5.7.36.
        '1100 0000 1245 6c4e 1d3f 0116 00ff ff08' //  .....ElN.?......
        '0200 ffc1 1500 0000 0000 0000 0000 0012' //  ................
        '3776 3609 063b 6d49 1a04 7200 6d79 7371' //  7v6..;mI..r.mysq
        '6c5f 6e61 7469 7665 5f70 6173 7377 6f72' //  l_native_passwor
        '6400'; // d.
    var p = Packet.parse(InputStream.from(bytesFromHexed(s2c1)));
    final h1 = Handshake.parse(p.inputStream);
    expect(h1, isNotNull);
    expect(h1.authPlugin, 'mysql_native_password');
    expect(h1.scramble, [
      18, 69, 108, 78, 29, 63, 1, 22, //
      18, 55, 118, 54, 9, 6, 59, 109, 73, 26, 4, 114
    ]);
    expect(h1.serverCharset, 8);
    expect(h1.serverCapability.value, 3254779903);
    expect(h1.serverStatus, 2);
    expect(h1.version, '5.7.36');
    expect(h1.threadId, 17);

    final c2s1 = bytesFromHexed(''
        'bf00 0001 8da6 7f00 0000 0001' //  ................
        '2100 0000 0000 0000 0000 0000 0000 0000' //  !...............
        '0000 0000 0000 0000 726f 6f74 0014 fae7' //  ........root....
        'c22a ce1d 758e ec5c 15c7 93a0 f772 0baa' //  .*..u..\.....r..
        'e8b9 7465 7374 006d 7973 716c 5f6e 6174' //  ..test.mysql_nat
        '6976 655f 7061 7373 776f 7264 0069 035f' //  ive_password.i._
        '6f73 086f 7378 3130 2e31 360c 5f63 6c69' //  os.osx10.16._cli
        '656e 745f 6e61 6d65 086c 6962 6d79 7371' //  ent_name.libmysq
        '6c04 5f70 6964 0536 3733 3933 0f5f 636c' //  l._pid.67393._cl
        '6965 6e74 5f76 6572 7369 6f6e 0635 2e36' //  ient_version.5.6
        '2e35 3009 5f70 6c61 7466 6f72 6d06 7838' //  .50._platform.x8
        '365f 3634 0c70 726f 6772 616d 5f6e 616d' //  6_64.program_nam
        '6505 6d79 7371 6c' //                        e.mysql
        );
    p = Packet.parse(InputStream.from(c2s1));
    final sa1 = ServerAuthentication.parse(p.inputStream);
    print(sa1.clientFlag.setted);

    {
      final ca = ClientAuthentication(
        h1,
        user: 'root',
        password: 'example',
        db: 'test',
        options: sa1.options,
        clientCapability: sa1.clientFlag,
      );
      Uint8List buf = Packet.build(p.packetId!, ca).encode();
      print('d : ${hexed(buf)}');

      expect(buf, c2s1);
    }

    final s2c2 =
        bytesFromHexed('0700 0002 0000 0002 0000 00'); //  .C.............
    p = Packet.parse(InputStream.from(s2c2));
    final ok = OkPacket.parse(p.inputStream, sa1.clientFlag);
    expect(ok.affectedRows, 0);
    expect(ok.lastInsertId, 0);
    expect(ok.serverStatus, 2);
    expect(ok.warningCount, 0);

    expect(Packet.build(2, OkPacket(serverStatus: 2)).encode(), s2c2);

    final c2s2 = '2100 0000 0373 656c 6563 7420' // .C..!....select.
        '4040 7665 7273 696f 6e5f 636f 6d6d 656e' // @@version_commen
        '7420 6c69 6d69 7420 31'; // t.limit.1

    final s2c3 =
        bytesFromHexed('0100 0001 0127 0000 0203 6465' // .C.......'....de
            '6600 0000 1140 4076 6572 7369 6f6e 5f63' //  f....@@version_c
            '6f6d 6d65 6e74 000c 2100 5400 0000 fd00' //  omment..!.T.....
            '001f 0000 0500 0003 fe00 0002 001d 0000' //  ................
            '041c 4d79 5351 4c20 436f 6d6d 756e 6974' //  ..MySQL.Communit
            '7920 5365 7276 6572 2028 4750 4c29 0500' //  y.Server.(GPL)..
            '0005 fe00 0002 00'); // .......

    {
      final rs = ResultSet.parse(InputStream.from(s2c3));
      final dest = rs.encode();
      expect(dest, s2c3);
    }
  });

  test('mysql-5.6-default-authentication-plugin=mysql_native_password', () {
    // handshake
    final s2c1 = '4a00 0000 0a35 2e36 2e35 3100' //  D...J....5.6.51.
        '0100 0000 7a5a 363a 615a 2132 00ff f708' //  ....zZ6:aZ!2....
        '0200 7f80 1500 0000 0000 0000 0000 0077' //  ...............w
        '2344 6c74 224a 304c 7173 6f00 6d79 7371' //  #Dlt"J0Lqso.mysq
        '6c5f 6e61 7469 7665 5f70 6173 7377 6f72' //  l_native_passwor
        '6400'; //  d.

    var p = Packet.parse(InputStream.from(bytesFromHexed(s2c1)));
    final h1 = Handshake.parse(p.inputStream);
    expect(h1, isNotNull);
    expect(h1.authPlugin, 'mysql_native_password');
    expect(h1.scramble, [
      122, 90, 54, 58, 97, 90, 33, 50, //
      119, 35, 68, 108, 116, 34, 74, 48, //
      76, 113, 115, 111
    ]);
    expect(h1.serverCharset, 8);
    expect(h1.serverCapability.value, 2155870207);
    expect(h1.serverStatus, 2);
    expect(h1.version, '5.6.51');
    expect(h1.threadId, 1);

    // authentication
    final c2s1 = 'b300 0001 05a6 ff01 0000 0001' //  D...............
        'ff00 0000 0000 0000 0000 0000 0000 0000' //  ................
        '0000 0000 0000 0000 726f 6f74 0000 6361' //  ........root..ca
        '6368 696e 675f 7368 6132 5f70 6173 7377' //  ching_sha2_passw
        '6f72 6400 7603 5f6f 7307 6f73 7831 312e' //  ord.v._os.osx11.
        '3009 5f70 6c61 7466 6f72 6d06 7838 365f' //  0._platform.x86_
        '3634 0f5f 636c 6965 6e74 5f76 6572 7369' //  64._client_versi
        '6f6e 0638 2e30 2e31 370c 5f63 6c69 656e' //  on.8.0.17._clien
        '745f 6e61 6d65 086c 6962 6d79 7371 6c04' //  t_name.libmysql.
        '5f70 6964 0536 3937 3731 076f 735f 7573' //  _pid.69771.os_us
        '6572 056d 6f72 646f 0c70 726f 6772 616d' //  er.mordo.program
        '5f6e 616d 6505 6d79 7371 6c'; // _name.mysql

    p = Packet.parse(InputStream.from(bytesFromHexed(c2s1)));
    final sa1 = ServerAuthentication.parse(p.inputStream);
    expect(sa1, isNotNull);

    // ?
    // TODO: OldAuthSwitchRequest
    // https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::HandshakeResponse
    final s2c2 = '2c00 0002 fe6d 7973 716c 5f6e' // .....mysql_n
        '6174 6976 655f 7061 7373 776f 7264 007a' // ative_password.z
        '5a36 3a61 5a21 3277 2344 6c74 224a 304c' // Z6:aZ!2w#Dlt"J0L
        '7173 6f00'; // qso.
    final eof = Packet.parse(InputStream.from(bytesFromHexed(s2c2)));
    expect(eof, isNotNull);

    // ? 这明显是
    final c2s2 = '1400 0003 2139 472c 6999 1b08' // D.......!9G,i...
        'a42a f9bd 8118 432a ba69 2a4b'; // .*....C*.i*K
    p = Packet.parse(InputStream.from(bytesFromHexed(c2s2)));
    expect(p, isNotNull);

    // ok
    final s2c3 = '0700 0004 0000 0002 0000 00'; // D..............

    //
    final s2c4 = '2100 0000 0373 656c 6563 7420' // D...!....select.
        '4040 7665 7273 696f 6e5f 636f 6d6d 656e' // @@version_commen
        '7420 6c69 6d69 7420 31'; //        t.limit.1

    final s2c5 = '0100 0001 0127 0000 0203 6465' // D........'....de
        '6600 0000 1140 4076 6572 7369 6f6e 5f63' // f....@@version_c
        '6f6d 6d65 6e74 000c 0800 1c00 0000 fd00' // omment..........
        '001f 0000 0500 0003 fe00 0002 001d 0000' // ................
        '041c 4d79 5351 4c20 436f 6d6d 756e 6974' // ..MySQL.Communit
        '7920 5365 7276 6572 2028 4750 4c29 0500' // y.Server.(GPL)..
        '0005 fe00 0002 00'; // .......
  });

  test('Sha2Test', () {
    final scramble = Uint8List.fromList([
      67, 98, 15, 90, 72, 93, 46, 103, //
      97, 52, 64, 30, 73, 17, 20, 8,
      98, 27, 123, 1
    ]);
    expect(scramble.length, Salt.length);

    final hashedPassword = [
      75, 21, 95, 173, 169, 120, 59, 209, //
      202, 38, 51, 135, 84, 14, 37, 146, 140,
      109, 209, 128, 192, 29, 84, 130,
      17, 48, 227, 224, 5, 247, 195, 203
    ];
    expect(hashedPassword.length, 32);

    final h2 = bytesFromHexed('4b 155f ada9'
        '783b d1ca 2633 8754 0e25 928c 6dd1 80c0'
        '1d54 8211 30e3 e005 f7c3 cb');
    expect(h2, hashedPassword);

    expect(Sha256Password().scramble(scramble, 'aaaaaa'), hashedPassword);
  });

  test('ValidateScrambleTest', () {
    final source = 'password';
    final rnd = Salt(0x237d29ef).generate();
    expect(
        bytesFromHexed('4105 7d4f 3d46 3f19 737d 5b5e 0f1e 3127'
            '235c 0e66'),
        rnd);

    final scramble = Sha256Password().scramble(rnd, source);
    expect(
        bytesFromHexed('5492 857c 4abd 20ab 7a5f 1d35 218d 0ee4'
            'ada2 aadb 5773 a802 31ad e411 48f5 f6c2'),
        scramble);

    final stage2 = Sha256Password.digestTwice(source);

    expect(Sha256Password().validate(rnd, scramble, stage2.bytes), isTrue);
  });

  test('NativePasswordTest', () {
    final source = 'example';
    final rnd = bytesFromHexed('2c38 586e 1151 4c5a 2f34 141b 0c18 6f66'
        '3a7c 4854');

    final scramble = NativePassword().scramble(rnd, source);
    expect(
        bytesFromHexed('0005 e072 b14b c6c2 94b5 9adc 0fa4 c549'
            'fcb4 6be4'),
        scramble);

    final stage2 = NativePassword.digestTwice(source);

    // final known1 = makeMysqlNativePassword(rnd, source);
    // expect(known1, scramble);
    // makeMysqlNativePassword wrong!!!

    expect(NativePassword().validate(rnd, scramble, stage2.bytes), isTrue);
  });

  // 0x0020:  8018 18e8 fe75 0000 0101 080a 0ba5 8cbd  .....u..........
  // 0x0030:  0ba5 8cbc 4900 0002 ff15 0423 3238 3030  ....I......#2800
  // 0x0040:  3041 6363 6573 7320 6465 6e69 6564 2066  0Access.denied.f
  // 0x0050:  6f72 2075 7365 7220 2772 6f6f 7427 4027  or.user.'root'@'
  // 0x0060:  3137 322e 3138 2e30 2e31 2720 2875 7369  172.18.0.1'.(usi
  // 0x0070:  6e67 2070 6173 7377 6f72 643a 2059 4553  ng.password:.YES
  // 0x0080:  29                                       )

  test('PasswordWrongTest', () {
    final bytes = bytesFromHexed('4900 0002 ff15 0423 3238 3030'
        '3041 6363 6573 7320 6465 6e69 6564 2066'
        '6f72 2075 7365 7220 2772 6f6f 7427 4027'
        '3137 322e 3138 2e30 2e31 2720 2875 7369'
        '6e67 2070 6173 7377 6f72 643a 2059 4553'
        '29');
    ErrorPacket err = Packet.parse(InputStream.from(bytes)) as ErrorPacket;
    expect(err, isNotNull);
    expect(err.code, 1045);
    expect(err.state, '28000');
    expect(err.message,
        '''Access denied for user 'root'@'172.18.0.1' (using password: YES)''');
  });

  // show databases
  // '0f00 0000 0373 686f 7720 6461 7461 6261 7365 73'

  // 0x0030:  0ba2 d018 0100 0001 014b 0000 0203 6465  .........K....de
  // 0x0040:  6612 696e 666f 726d 6174 696f 6e5f 7363  f.information_sc
  // 0x0050:  6865 6d61 0853 4348 454d 4154 4108 5343  hema.SCHEMATA.SC
  // 0x0060:  4845 4d41 5441 0844 6174 6162 6173 650b  HEMATA.Database.
  // 0x0070:  5343 4845 4d41 5f4e 414d 450c 2100 c000  SCHEMA_NAME.!...
  // 0x0080:  0000 fd01 0000 0000 0500 0003 fe00 0022  ..............."
  // 0x0090:  0013 0000 0412 696e 666f 726d 6174 696f  ......informatio
  // 0x00a0:  6e5f 7363 6865 6d61 0600 0005 056d 7973  n_schema.....mys
  // 0x00b0:  716c 1300 0006 1270 6572 666f 726d 616e  ql.....performan
  // 0x00c0:  6365 5f73 6368 656d 6104 0000 0703 7379  ce_schema.....sy
  // 0x00d0:  7305 0000 0804 7465 7374 0500 0009 fe00  s.....test......
  // 0x00e0:  0022 00                                  .".

  // show tables;
  // '0c00 0000 0373 686f 7720 7461 626c 6573'

  // 0x0020:  8018 18e8 fe99 0000 0101 080a 0ba2 d01b  ................
  // 0x0030:  0ba2 d01a 0100 0001 0156 0000 0203 6465  .........V....de
  // 0x0040:  6612 696e 666f 726d 6174 696f 6e5f 7363  f.information_sc
  // 0x0050:  6865 6d61 0b54 4142 4c45 5f4e 414d 4553  hema.TABLE_NAMES
  // 0x0060:  0b54 4142 4c45 5f4e 414d 4553 0e54 6162  .TABLE_NAMES.Tab
  // 0x0070:  6c65 735f 696e 5f74 6573 740a 5441 424c  les_in_test.TABL
  // 0x0080:  455f 4e41 4d45 0c21 00c0 0000 00fd 0100  E_NAME.!........
  // 0x0090:  0000 0005 0000 03fe 0000 2200 0500 0004  ..........".....
  // 0x00a0:  fe00 0022 00                             ...".

  test('CachingStoreTest', () {
    {
      final store = CachingSha2Password();
      store.add('root', '38e423hs');
      store.add('empty', '');
      store.store('test-passwd');
    }
    {
      final store = CachingSha2Password.load('test-passwd');
      expect(store.cache.containsKey('root'), isTrue);
      expect(store.cache.containsKey('empty'), isTrue);
    }
  });
}

import 'package:test/test.dart';

import 'package:mysqldb/impl.dart';
import 'package:mysqldb/src/flag_mirror.dart';

class Aflag extends Flag {
  Aflag(int v) : super(v);

  static const int tv = 1;
  static const int fv = 2;
}

void main() {
  test('RawFlagTest', () {
    var v1 = Flag(0x22, 0xff);

    expect(v1.has(2), isTrue);
    expect(v1.has(1), isFalse);

    v1.unset(2);
    expect(v1.value, 0x20);
    expect(v1.has(0x2), isFalse);

    expect(v1.has(0), isTrue);
    expect(v1.has(0x20), isTrue);
  });

  test('ExtendedFlagTest', () {
    final c = Capability(Capability.longFlag | Capability.longPassword);
    expect(c.setted, ['longPassword', 'longFlag', 'allZeros']);

    final d = Aflag(1);
    expect(d.items, {'tv': 1, 'fv': 2});
    expect(d.setted, {'tv'});
  }, skip: true);
}

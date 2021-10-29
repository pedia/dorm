import 'package:test/test.dart';
import 'package:dorm/dorm.dart';

void main() {
  test('DbUriTest', () {
    final u1 = DbUri(
      scheme: 'mysql',
      host: '127.0.0.1',
      database: 'test',
      user: 'root',
      password: '38e423hs',
      args: {'encoding': 'utf-8'},
    );
    final s1 = 'mysql://root:38e423hs@127.0.0.1/test?encoding=utf-8';
    expect(DbUri.parse(s1), u1);
    expect(u1.toString(), s1);

    //
    final u2 = DbUri(
      scheme: 'sqlite',
      database: 'test.db',
      args: {'encoding': 'utf-8'},
    );
    final s2 = 'sqlite:///test.db?encoding=utf-8';
    expect(DbUri.parse(s2), u2);
    expect(u2.toString(), s2);

    //
    final u3 = DbUri(
      scheme: 'mysql',
      host: '127.0.0.1',
      database: 'test',
      user: 'root',
      args: {'encoding': 'utf-8'},
    );
    final s3 = 'mysql://root@127.0.0.1/test?encoding=utf-8';
    expect(DbUri.parse(s3), u3);
    expect(u3.toString(), s3);

    //
    final u4 = DbUri(scheme: 'sqlite', database: ':memory:');
    expect(DbUri.parse('sqlite:///:memory:'), u4);
    expect(u4.toString(), 'sqlite:///:memory:');
  });
}

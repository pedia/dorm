import 'package:reflection_factory/reflection_factory.dart';
import 'package:test/test.dart';

import 'package:dorm/dorm.dart';
import 'package:dorm/annotation.dart' as dorm;

part 'reflection_test.reflection.g.dart';

class Payload {
  @override
  String toString() => 'payload';
}

class ann1 {
  const ann1();
}

class ann2 {
  const ann2();
}

@ann1()
@ann2()
@dorm.table('t_user')
@EnableReflection()
class User {
  @dorm.field(unique: true)
  String? email;

  @dorm.field()
  String pass;

  @dorm.field()
  final int age;

  final Payload payload = Payload();

  User(this.email, this.pass, this.age);
  User.empty() : this(null, '', 0);

  bool get hasEmail => email != null;

  bool checkPassword(String pass) {
    return this.pass == pass;
  }
}

main() {
  test('model', () {
    final user = User('joe@mail.com', '123', 23);

    // constructorsNames
    // constructor
    user.reflection;

    final cas = user.reflection.classAnnotations;
    expect(cas.first is ann1, isTrue);

    final sts = user.reflection.supperTypes;
    final a2 = user.reflection.fieldsNames;
    final a3 = user.reflection.staticFieldsNames;
    final a4 = user.reflection.methodsNames;
    final a5 = user.reflection.staticMethodsNames;

    // expect(user.fields, ['age', 'email', 'pass', 'payload']);
  });

  test('UserReflection', () {
    final user = User('joe@mail.com', '123', 23);
    expect(user.toJsonEncoded(),
        '{"age":23,"email":"joe@mail.com","foo":"foo","pass":"123"}');
    final fields = user.toJsonFromFields() as Map;
    expect(fields.length, 4);
  });

  test('DefaultBridge', () {
    var u = User$reflection().createInstance();

    expect(u!.email, isNull);
    u.email = 'a@b.com';
    expect(u.email, 'a@b.com');

    expect(u.age, 0);
    expect(u.pass, '');

    {
      final m = Model(User$reflection());
      final table = m.table;
      expect(table, isNotNull);
      expect(table!.fields.length, 3);
      expect(m.table!.fields[0].name, 'age');
      expect(m.valueOf(m.table!.fields[0]), isNull);
    }

    {
      final m = Model(User$reflection(u));
      expect(m.table!.fields[0].name, 'age');
      expect(m.valueOf(m.table!.fields[0]), 0);

      expect(m.table!.fields[1].name, 'email');
      expect(m.valueOf(m.table!.fields[1]), 'a@b.com');

      expect(m.insertSql,
          'INSERT INTO `t_user`(age, email, pass) VALUES (0, "a@b.com", "")');
    }
  });
}

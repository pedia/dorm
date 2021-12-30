import 'package:reflection_factory/reflection_factory.dart';
import 'package:test/test.dart';

part 'reflection_test.reflection.g.dart';

class Foo {
  @override
  String toString() => 'foo';
}

abstract class Model {
  dynamic get fields;
}

class ann1 {
  const ann1();
}

class ann2 {
  const ann2();
}

@ann1()
@ann2()
@EnableReflection()
class User extends Model {
  String? email;

  String pass;
  final int age;
  final Foo foo = Foo();

  User(this.email, this.pass, this.age);

  User.empty() : this(null, '', 0);

  bool get hasEmail => email != null;

  bool checkPassword(String pass) {
    return this.pass == pass;
  }

  dynamic get fields {
    return (toJsonFromFields() as Map).keys;
  }
}

@EnableReflection()
class AdminUser extends User {
  AdminUser() : super('admin@foo.com', '', 33);
}

@ReflectionBridge([User, AdminUser])
class UserBridge {}

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

    expect(user.fields, ['age', 'email', 'foo', 'pass']);
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
  });

  test('Bridge', () {
    // final ref1 = ClassReflection<User>([User]);

    final ref2 = UserBridge().reflection<User>();
    final u = ref2.createInstance();
    expect(u!.age, 0);
  });
}

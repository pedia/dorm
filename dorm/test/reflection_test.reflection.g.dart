//
// GENERATED CODE - DO NOT MODIFY BY HAND!
// BUILDER: reflection_factory/1.0.19
// BUILD COMMAND: dart run build_runner build
//

// ignore_for_file: unnecessary_const

part of 'reflection_test.dart';

// ignore: non_constant_identifier_names
AdminUser AdminUser$fromJson(Map<String, Object?> map) =>
    AdminUser$reflection.staticInstance.fromJson(map);
// ignore: non_constant_identifier_names
AdminUser AdminUser$fromJsonEncoded(String jsonEncoded) =>
    AdminUser$reflection.staticInstance.fromJsonEncoded(jsonEncoded);
// ignore: non_constant_identifier_names
User User$fromJson(Map<String, Object?> map) =>
    User$reflection.staticInstance.fromJson(map);
// ignore: non_constant_identifier_names
User User$fromJsonEncoded(String jsonEncoded) =>
    User$reflection.staticInstance.fromJsonEncoded(jsonEncoded);

class AdminUser$reflection extends ClassReflection<AdminUser> {
  AdminUser$reflection([AdminUser? object]) : super(AdminUser, object);

  static bool _registered = false;
  @override
  void register() {
    if (!_registered) {
      _registered = true;
      super.register();
      _registerSiblingsReflection();
    }
  }

  @override
  Version get languageVersion => Version.parse('2.12.0');

  @override
  Version get reflectionFactoryVersion => Version.parse('1.0.19');

  @override
  AdminUser$reflection withObject([AdminUser? obj]) =>
      AdminUser$reflection(obj);

  static AdminUser$reflection? _withoutObjectInstance;
  @override
  AdminUser$reflection withoutObjectInstance() => _withoutObjectInstance ??=
      super.withoutObjectInstance() as AdminUser$reflection;

  static AdminUser$reflection get staticInstance =>
      _withoutObjectInstance ??= AdminUser$reflection();

  @override
  bool get hasDefaultConstructor => true;
  @override
  AdminUser? createInstanceWithDefaultConstructor() => AdminUser();

  @override
  bool get hasEmptyConstructor => false;
  @override
  AdminUser? createInstanceWithEmptyConstructor() => null;
  @override
  bool get hasNoRequiredArgsConstructor => false;
  @override
  AdminUser? createInstanceWithNoRequiredArgsConstructor() => null;

  @override
  List<String> get constructorsNames => const <String>[''];

  @override
  ConstructorReflection<AdminUser>? constructor<R>(String constructorName) {
    var lc = constructorName.trim().toLowerCase();

    switch (lc) {
      case '':
        return ConstructorReflection<AdminUser>(this, AdminUser, '',
            () => () => AdminUser(), null, null, null, null);
      default:
        return null;
    }
  }

  @override
  List<Object> get classAnnotations => List<Object>.unmodifiable(<Object>[]);

  @override
  List<ClassReflection> siblingsClassReflection() =>
      _siblingsReflection().whereType<ClassReflection>().toList();

  @override
  List<Reflection> siblingsReflection() => _siblingsReflection();

  @override
  List<Type> get supperTypes => const <Type>[User, Model];

  @override
  bool get hasMethodToJson => false;

  @override
  Object? callMethodToJson([AdminUser? obj]) => null;

  @override
  List<String> get fieldsNames =>
      const <String>['age', 'email', 'fields', 'foo', 'hasEmail', 'pass'];

  @override
  FieldReflection<AdminUser, T>? field<T>(String fieldName, [AdminUser? obj]) {
    obj ??= object;

    var lc = fieldName.trim().toLowerCase();

    switch (lc) {
      case 'email':
        return FieldReflection<AdminUser, T>(
          this,
          User,
          TypeReflection.tString,
          'email',
          true,
          (o) => () => o!.email as T,
          (o) => (T? v) => o!.email = v as String?,
          obj,
          false,
          false,
          null,
        );
      case 'pass':
        return FieldReflection<AdminUser, T>(
          this,
          User,
          TypeReflection.tString,
          'pass',
          false,
          (o) => () => o!.pass as T,
          (o) => (T? v) => o!.pass = v as String,
          obj,
          false,
          false,
          null,
        );
      case 'age':
        return FieldReflection<AdminUser, T>(
          this,
          User,
          TypeReflection.tInt,
          'age',
          false,
          (o) => () => o!.age as T,
          null,
          obj,
          false,
          true,
          null,
        );
      case 'foo':
        return FieldReflection<AdminUser, T>(
          this,
          User,
          TypeReflection(Foo),
          'foo',
          false,
          (o) => () => o!.foo as T,
          null,
          obj,
          false,
          true,
          null,
        );
      case 'hasemail':
        return FieldReflection<AdminUser, T>(
          this,
          User,
          TypeReflection.tBool,
          'hasEmail',
          false,
          (o) => () => o!.hasEmail as T,
          null,
          obj,
          false,
          false,
          null,
        );
      case 'fields':
        return FieldReflection<AdminUser, T>(
          this,
          User,
          TypeReflection.tDynamic,
          'fields',
          false,
          (o) => () => o!.fields as T,
          null,
          obj,
          false,
          false,
          null,
        );
      default:
        return null;
    }
  }

  @override
  List<String> get staticFieldsNames => const <String>[];

  @override
  FieldReflection<AdminUser, T>? staticField<T>(String fieldName) {
    return null;
  }

  @override
  List<String> get methodsNames => const <String>['checkPassword'];

  @override
  MethodReflection<AdminUser, R>? method<R>(String methodName,
      [AdminUser? obj]) {
    obj ??= object;

    var lc = methodName.trim().toLowerCase();

    switch (lc) {
      case 'checkpassword':
        return MethodReflection<AdminUser, R>(
            this,
            User,
            'checkPassword',
            TypeReflection.tBool,
            false,
            (o) => o!.checkPassword,
            obj,
            false,
            const <ParameterReflection>[
              ParameterReflection(
                  TypeReflection.tString, 'pass', false, true, null, null)
            ],
            null,
            null,
            null);
      default:
        return null;
    }
  }

  @override
  List<String> get staticMethodsNames => const <String>[];

  @override
  MethodReflection<AdminUser, R>? staticMethod<R>(String methodName) {
    return null;
  }
}

class User$reflection extends ClassReflection<User> {
  User$reflection([User? object]) : super(User, object);

  static bool _registered = false;
  @override
  void register() {
    if (!_registered) {
      _registered = true;
      super.register();
      _registerSiblingsReflection();
    }
  }

  @override
  Version get languageVersion => Version.parse('2.12.0');

  @override
  Version get reflectionFactoryVersion => Version.parse('1.0.19');

  @override
  User$reflection withObject([User? obj]) => User$reflection(obj);

  static User$reflection? _withoutObjectInstance;
  @override
  User$reflection withoutObjectInstance() => _withoutObjectInstance ??=
      super.withoutObjectInstance() as User$reflection;

  static User$reflection get staticInstance =>
      _withoutObjectInstance ??= User$reflection();

  @override
  bool get hasDefaultConstructor => false;
  @override
  User? createInstanceWithDefaultConstructor() => null;

  @override
  bool get hasEmptyConstructor => true;
  @override
  User? createInstanceWithEmptyConstructor() => User.empty();
  @override
  bool get hasNoRequiredArgsConstructor => true;
  @override
  User? createInstanceWithNoRequiredArgsConstructor() => User.empty();

  @override
  List<String> get constructorsNames => const <String>['', 'empty'];

  @override
  ConstructorReflection<User>? constructor<R>(String constructorName) {
    var lc = constructorName.trim().toLowerCase();

    switch (lc) {
      case '':
        return ConstructorReflection<User>(
            this,
            User,
            '',
            () =>
                (String? email, String pass, int age) => User(email, pass, age),
            const <ParameterReflection>[
              ParameterReflection(
                  TypeReflection.tString, 'email', true, true, null, null),
              ParameterReflection(
                  TypeReflection.tString, 'pass', false, true, null, null),
              ParameterReflection(
                  TypeReflection.tInt, 'age', false, true, null, null)
            ],
            null,
            null,
            null);
      case 'empty':
        return ConstructorReflection<User>(this, User, 'empty',
            () => () => User.empty(), null, null, null, null);
      default:
        return null;
    }
  }

  static const List<Object> _classAnnotations = [ann1(), ann2()];

  @override
  List<Object> get classAnnotations =>
      List<Object>.unmodifiable(_classAnnotations);

  @override
  List<ClassReflection> siblingsClassReflection() =>
      _siblingsReflection().whereType<ClassReflection>().toList();

  @override
  List<Reflection> siblingsReflection() => _siblingsReflection();

  @override
  List<Type> get supperTypes => const <Type>[Model];

  @override
  bool get hasMethodToJson => false;

  @override
  Object? callMethodToJson([User? obj]) => null;

  @override
  List<String> get fieldsNames =>
      const <String>['age', 'email', 'fields', 'foo', 'hasEmail', 'pass'];

  @override
  FieldReflection<User, T>? field<T>(String fieldName, [User? obj]) {
    obj ??= object;

    var lc = fieldName.trim().toLowerCase();

    switch (lc) {
      case 'email':
        return FieldReflection<User, T>(
          this,
          User,
          TypeReflection.tString,
          'email',
          true,
          (o) => () => o!.email as T,
          (o) => (T? v) => o!.email = v as String?,
          obj,
          false,
          false,
          null,
        );
      case 'pass':
        return FieldReflection<User, T>(
          this,
          User,
          TypeReflection.tString,
          'pass',
          false,
          (o) => () => o!.pass as T,
          (o) => (T? v) => o!.pass = v as String,
          obj,
          false,
          false,
          null,
        );
      case 'age':
        return FieldReflection<User, T>(
          this,
          User,
          TypeReflection.tInt,
          'age',
          false,
          (o) => () => o!.age as T,
          null,
          obj,
          false,
          true,
          null,
        );
      case 'foo':
        return FieldReflection<User, T>(
          this,
          User,
          TypeReflection(Foo),
          'foo',
          false,
          (o) => () => o!.foo as T,
          null,
          obj,
          false,
          true,
          null,
        );
      case 'hasemail':
        return FieldReflection<User, T>(
          this,
          User,
          TypeReflection.tBool,
          'hasEmail',
          false,
          (o) => () => o!.hasEmail as T,
          null,
          obj,
          false,
          false,
          null,
        );
      case 'fields':
        return FieldReflection<User, T>(
          this,
          User,
          TypeReflection.tDynamic,
          'fields',
          false,
          (o) => () => o!.fields as T,
          null,
          obj,
          false,
          false,
          null,
        );
      default:
        return null;
    }
  }

  @override
  List<String> get staticFieldsNames => const <String>[];

  @override
  FieldReflection<User, T>? staticField<T>(String fieldName) {
    return null;
  }

  @override
  List<String> get methodsNames => const <String>['checkPassword'];

  @override
  MethodReflection<User, R>? method<R>(String methodName, [User? obj]) {
    obj ??= object;

    var lc = methodName.trim().toLowerCase();

    switch (lc) {
      case 'checkpassword':
        return MethodReflection<User, R>(
            this,
            User,
            'checkPassword',
            TypeReflection.tBool,
            false,
            (o) => o!.checkPassword,
            obj,
            false,
            const <ParameterReflection>[
              ParameterReflection(
                  TypeReflection.tString, 'pass', false, true, null, null)
            ],
            null,
            null,
            null);
      default:
        return null;
    }
  }

  @override
  List<String> get staticMethodsNames => const <String>[];

  @override
  MethodReflection<User, R>? staticMethod<R>(String methodName) {
    return null;
  }
}

extension AdminUser$reflectionExtension on AdminUser {
  /// Returns a [ClassReflection] for type [AdminUser]. (Generated by [ReflectionFactory])
  ClassReflection<AdminUser> get reflection => AdminUser$reflection(this);

  /// Returns a JSON for type [AdminUser]. (Generated by [ReflectionFactory])
  Object? toJson() => reflection.toJson();

  /// Returns a JSON [Map] for type [AdminUser]. (Generated by [ReflectionFactory])
  Map<String, dynamic>? toJsonMap() => reflection.toJsonMap();

  /// Returns an encoded JSON [String] for type [AdminUser]. (Generated by [ReflectionFactory])
  String toJsonEncoded({bool pretty = false}) =>
      reflection.toJsonEncoded(pretty: pretty);

  /// Returns a JSON for type [AdminUser] using the class fields. (Generated by [ReflectionFactory])
  Object? toJsonFromFields() => reflection.toJsonFromFields();
}

extension User$reflectionExtension on User {
  /// Returns a [ClassReflection] for type [User]. (Generated by [ReflectionFactory])
  ClassReflection<User> get reflection => User$reflection(this);

  /// Returns a JSON for type [User]. (Generated by [ReflectionFactory])
  Object? toJson() => reflection.toJson();

  /// Returns a JSON [Map] for type [User]. (Generated by [ReflectionFactory])
  Map<String, dynamic>? toJsonMap() => reflection.toJsonMap();

  /// Returns an encoded JSON [String] for type [User]. (Generated by [ReflectionFactory])
  String toJsonEncoded({bool pretty = false}) =>
      reflection.toJsonEncoded(pretty: pretty);

  /// Returns a JSON for type [User] using the class fields. (Generated by [ReflectionFactory])
  Object? toJsonFromFields() => reflection.toJsonFromFields();
}

extension UserBridge$reflectionExtension on UserBridge {
  /// Returns a [ClassReflection] for type [T] or [obj]. (Generated by [ReflectionFactory])
  ClassReflection<T> reflection<T>([T? obj]) {
    switch (T) {
      case User:
        return User$reflection(obj as User?) as ClassReflection<T>;
      case AdminUser:
        return AdminUser$reflection(obj as AdminUser?) as ClassReflection<T>;
      default:
        throw UnsupportedError('<$runtimeType> No reflection for Type: $T');
    }
  }
}

List<Reflection> _listSiblingsReflection() => <Reflection>[
      User$reflection(),
      AdminUser$reflection(),
    ];

List<Reflection>? _siblingsReflectionList;
List<Reflection> _siblingsReflection() => _siblingsReflectionList ??=
    List<Reflection>.unmodifiable(_listSiblingsReflection());

bool _registerSiblingsReflectionCalled = false;
void _registerSiblingsReflection() {
  if (_registerSiblingsReflectionCalled) return;
  _registerSiblingsReflectionCalled = true;
  var length = _listSiblingsReflection().length;
  assert(length > 0);
}

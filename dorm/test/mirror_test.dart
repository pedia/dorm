import "dart:mirrors";
import "package:test/test.dart";

import 'package:dorm/dorm.dart';

import 'models.dart' as park;

@table('foo')
class Foo extends Model {
  @primaryKey
  late int id;

  @field(nullable: true, name: '_name')
  String? name;

  Foo(this.id, [this.name]);
}

@table('empty')
class EmptyTable extends Model {
  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter && invocation.memberName == #gaga) return 3;
    return super.noSuchMethod(invocation);
  }
}

main() {
  test('TypeReflectTest', () {
    expect(tableOf(Foo)!.name, 'foo');
  });

  test('ReflectTest', () {
    Foo foo = Foo(32, '33');
    final t1 = reflectClass(foo.runtimeType);
    expect(t1.metadata.first.hasReflectee, isTrue);
    expect((t1.metadata.first.reflectee as table).name, 'foo');

    // print(t1.getField(#name));

    //
    final im = reflect(foo);
    expect(im.getField(#id).reflectee, 32);
    expect(im.getField(Symbol('name')).reflectee, '33');

    final bar = Foo(424);
    expect(reflect(bar).getField(#name).reflectee, null);

    print(t1.declarations);

    print(foo.table.name);
    // print(foo.fields);
    print(foo.table.createSql);
    print(foo.insertSql);

    //
    final a = park.Article(
        id: 24, topic: 'book', author: 'andy', type: 'paper', cid: 2);
    print(a.table.createSql);
    print(a.insertSql);

    final e = EmptyTable();
    print(e.table.createSql);
    print(e.insertSql);
  });
}

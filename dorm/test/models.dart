import 'package:reflection_factory/reflection_factory.dart';
import 'package:dorm/dorm.dart';
import 'package:dorm/annotation.dart' as dorm;

part 'models.reflection.g.dart';

@EnableReflection()
@dorm.table('category', bind: 'test')
class Category {
  @primaryKey
  int? cid;

  @dorm.field(unique: true, index: true, maxLength: 100)
  String? name;

  @dorm.field(nullable: true)
  DateTime? ctime;

  @dorm.field(nullable: true)
  double? ratio;

  @dorm.field(enums: ['reserved', 'normal'], defaultValue: 'normal')
  String? type;

  Category({
    this.cid,
    this.name,
    this.ctime,
    this.ratio,
    this.type,
  });
}

@EnableReflection()
@dorm.table('article', bind: 'test')
class Article {
  @primaryKey
  int? id;

  @dorm.field(maxLength: 100)
  String? topic;

  @dorm.field(defaultValue: 'Mike', nullable: true)
  String? author;

  @dorm.field(defaultValue: 'paper', enums: ['paper', 'other'])
  String? type;

  @dorm.field(foreignKey: 'category.cid', nullable: true)
  int? cid;

  Category? category;

  static int foo = 3;

  int bar = 3;

  /// Must provide for creation in constructing in Query
  Article({
    this.id,
    this.topic,
    this.author,
    this.type,
    this.cid,
    this.category,
  });
}

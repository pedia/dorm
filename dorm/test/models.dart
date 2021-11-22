import 'package:dorm/dorm.dart';

@table('category', 'test')
class Category extends Model {
  @primaryKey
  int? cid;

  @field(unique: true, index: true, maxLength: 100)
  String name;

  @field(nullable: true)
  DateTime? ctime;

  @field(nullable: true)
  double? ratio;

  @field(enums: ['reserved', 'normal'], defaultValue: 'normal')
  String? type;

  Category({
    this.cid,
    required this.name,
    this.ctime,
    this.ratio,
    this.type,
  });
}

@table('article', 'test')
class Article extends Model {
  @primaryKey
  int? id;

  @field(maxLength: 100)
  String? topic;

  @field(defaultValue: 'Mike', nullable: true)
  String? author;

  @field(defaultValue: 'paper', enums: ['paper', 'other'])
  String type;

  @field(foreignKey: 'category.cid', nullable: true)
  int? cid;

  Category? category;

  static int foo = 3;

  int bar = 3;

  /// Must provide for creation in constructing in Query
  Article({
    this.id,
    this.topic,
    this.author,
    required this.type,
    this.cid,
    this.category,
  });
}

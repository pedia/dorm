import 'package:dorm/dorm.dart';
import 'package:sqlparser/sqlparser.dart';

@table('category', 'test')
class Category extends Model {
  @primaryKey
  late int cid;

  @field(nullable: false)
  String name;

  Category(this.cid, this.name);

  static query({
    String? filter = 'id=1',
    int? limit,
    join,
  }) =>
      Model.query(filter: filter, limit: limit);
}

@table('article', 'test')
class Article extends Model {
  @primaryKey
  int? id;

  @field(nullable: true)
  String? topic;

  @field(defaultValue: 'Mike', nullable: true)
  String? author;

  @field(foreignKey: 'category.cid')
  int cid;

  Category? category;

  static int foo = 3;

  int bar = 3;

  /// Must provide for creation in constructing in Query
  Article({
    this.id,
    this.topic,
    this.author,
    required this.cid,
    this.category,
  });

  ///
  static BaseQuery<Article> query({
    String? filter,
    int? limit,
    Type? joinable,
  }) =>
      Model.query<Article>(filter: filter, limit: limit);
}

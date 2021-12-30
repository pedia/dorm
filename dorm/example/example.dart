import 'package:dorm/annotation.dart';

@table('user', 'auth')
class User {
  @field(name: 'uid', primaryKey: true)
  final int? id;

  @field(index: true, unique: true)
  final String name;

  @field(nullable: false)
  final String password;

  User({this.id, required this.name, required this.password});
}

@table('article')
class Article {
  @primaryKey
  int? id;

  @field(nullable: false)
  String? topic;

  @field(defaultValue: 'Mike', nullable: true)
  String? author;

  static int foo = 3;

  int bar = 3;

  /// Must provide for creation in constructing in Query
  Article({this.id, this.topic, this.author});
}

void main() {
  // db.addAll({
  //   'default': 'sqlite:///:memory:',
  //   'auth': 'sqlite:///auth.db',
  // });
}

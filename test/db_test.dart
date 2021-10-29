import 'package:test/test.dart';

import 'package:dorm/dorm.dart';

import 'models.dart';

main() {
  test('QueryTest', () {
    Model.query<Category>(limit: 3);

    // Article.query(limit: 3, filter: 'id=3').join(Category);

    Category.query(limit: 3, filter: 'name like foo%');
  });

  test('SessionTest', () {
    db.add('test', 'sqlite:///:memory:');
    db.register(Article);
    db.register(Category);

    db.createAll();

    Session session = db.sessionOf('test')!;

    final rs = session.query('select * from article');
    expect(rs.isEmpty, isTrue);

    final a = Article(topic: 'book', author: 'Mike', cid: 1);

    session.execute(a.insertSql);

    session.add(a);
  });
}

import 'package:test/test.dart';

import 'package:dorm/dorm.dart';

import 'models.dart';

main() {
  test('QueryTest', () {
    Model.query<Category>(limit: 3);

    Category.query(limit: 3, filter: 'name like foo%');
  });

  setUp(() {
    db.add('test', 'sqlite:///:memory:');
    db.register(Article);
    db.register(Category);

    db.createAll();
  });

  tearDown(() {
    db.clear();
  });

  test('SessionTest', () {
    Session session = db.session('test')!;

    final rs = session.query('select * from article');
    expect(rs.isEmpty, isTrue);

    final a = Article(topic: 'book', author: 'Mike', cid: 1);

    session.execute(a.insertSql);
    session.add(a);
    session.commit();

    for (var i in Article.query()) {
      print(i);
    }
  });
}

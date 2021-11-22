import 'package:test/test.dart';

import 'package:dorm/dorm.dart';

import 'models.dart';

main() {
  test('QueryTest', () {
    // Model.query<Category>(limit: 3);

    Query<Category>(limit: 3, filter: 'name like foo%');
  });

  setUp(() {
    // db.add('test', 'mysql://test:Tt_gzS+0D<reS6Bk7fHn@127.0.0.1/test');
    // db.add('test', 'mysql://root:38e423hs@127.0.0.1/test');
    db.add('test', 'sqlite:///:memory:');
    db.register(Article);
    db.register(Category);

    db.createAll();
  });

  tearDown(() async {
    final session = db.session('test')!;
    await session.execute('drop table article');
    await session.execute('drop table category');
    db.clear();
  });

  test('SessionTest', () async {
    Session session = db.session('test')!;

    final q = await session.query('select * from article');
    expect(q.isEmpty, isTrue);

    final a = Article(topic: 'book', cid: 1, type: 'paper');

    await session
        .begin()
        .then((_) => session.add(a))
        .then((_) => session.add([a, a]))
        .then((_) => session.add([a, a]))
        .whenComplete(() => session.commit())
        .catchError((error, stackTrace) {
      session.rollback();
    });

    final rs = Query<Article>().toList();
    expect(rs[0].topic, 'book');
    expect(rs[0].author, 'Mike');
    expect(rs[0].id, isNotNull);
    expect(rs.length, 5);
  });
}

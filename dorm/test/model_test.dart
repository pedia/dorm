import 'package:test/test.dart';

import 'models.dart';

main() {
  test('FieldTest', () {
    final novel = Category(name: 'novel');
    expect(novel.table.name, 'category');
    expect(novel.table.bind, 'test');
    expect(novel.table.fields.length, 5);

    expect(novel.table.fields[0].name, 'cid');
    expect(novel.table.fields[0].typeName, 'int');
    expect(novel.table.fields[0].sqlClause(),
        'cid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL');
    expect(novel.table.fields[0].primaryKey, isTrue);
    expect(novel.table.fields[0].autoIncrement, isTrue);

    expect(novel.table.fields[1].name, 'name');
    expect(novel.table.fields[1].typeName, 'String');
    expect(novel.table.fields[1].sqlClause(), 'name TEXT NOT NULL');
    expect(novel.table.fields[1].unique, isTrue);
    expect(novel.table.fields[1].maxLength, 100);

    expect(novel.table.fields[2].name, 'ctime');
    expect(novel.table.fields[2].typeName, 'DateTime');
    expect(novel.table.fields[2].sqlClause(), 'ctime DATETIME');

    expect(novel.table.fields[3].name, 'ratio');
    expect(novel.table.fields[3].typeName, 'double');
    expect(novel.table.fields[3].sqlClause(), 'ratio DOUBLE');

    expect(novel.table.fields[4].name, 'type');
    expect(novel.table.fields[4].typeName, 'String');
    expect(novel.table.fields[4].sqlClause(),
        'type TEXT DEFAULT "normal" NOT NULL');
    expect(novel.table.fields[4].defaultValue, 'normal');
  });

  test('ModelSqlTest', () {
    final novel = Category(name: 'novel');

    expect(novel.valueOf(novel.table.fields[0]), isNull);
    expect(novel.valueOf(novel.table.fields[1]), 'novel');
    expect(novel.valueOf(novel.table.fields[4]), 'normal');

    expect(novel.table.indexes.length, 2);
    expect(novel.table.foreignKeys, isEmpty);

    expect(
        novel.insertSql,
        'INSERT INTO `category`(cid, name, ctime, ratio, type) '
        'VALUES (NULL, "novel", NULL, NULL, "normal")');
  });
}

import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:dorm/src/dburi.dart';
import 'package:dorm/src/database.dart';
import 'package:dorm/src/result_set.dart';

class SqliteConnection implements Connection {
  final sqlite3.Database db;
  SqliteConnection(this.db);

  static Connection create(DbUri uri) => SqliteConnection(
        uri.database == ':memory:'
            ? sqlite3.sqlite3.openInMemory()
            : sqlite3.sqlite3.open(uri.database),
      );

  @override
  Future<int> execute(String sql, [List<Object?> parameters = const []]) {
    db.execute(sql, parameters);
    return Future.value(db.getUpdatedRows());
  }

  @override
  Future<ResultSet> query(String sql, [List<Object?> parameters = const []]) {
    final rs = db.select(sql, parameters);
    return Future.value(SqliteResultSet(rs));
  }
}

class SqliteResultSet extends ResultSet {
  final sqlite3.ResultSet inner;
  SqliteResultSet(this.inner) : super(inner.columnNames);

  @override
  Iterator<Row> get iterator => _SqliteIterator(this);
}

class SqliteRow extends Row {
  final sqlite3.Row inner;
  SqliteRow(Cursor cursor, this.inner) : super(cursor);

  @override
  dynamic columnAt(int i) => inner.columnAt(i);
}

class _SqliteIterator extends Iterator<Row> {
  final SqliteResultSet result;
  int index = -1;

  _SqliteIterator(this.result);

  @override
  SqliteRow get current =>
      SqliteRow(result, sqlite3.Row(result.inner, result.inner.rows[index]));

  @override
  bool moveNext() {
    index++;
    return index < result.inner.length;
  }
}

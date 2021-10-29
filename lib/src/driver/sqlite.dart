part of dorm;

class SqliteConnection implements Connection {
  final sqlite3db.Database db;
  SqliteConnection(this.db);

  static Connection create(DbUri uri) => SqliteConnection(
        uri.database == ':memory:'
            ? sqlite3.openInMemory()
            : sqlite3.open(uri.database),
      );

  @override
  void execute(String sql, [List<Object?> parameters = const []]) =>
      db.execute(sql, parameters);

  @override
  ResultSet query(String sql, [List<Object?> parameters = const []]) {
    final rs = db.select(sql, parameters);
    return ResultSet(rs.columnNames, rs.tableNames, rs.rows);
  }

  @override
  int scalar(String sql, [List<Object?> parameters = const []]) {
    final rs = db.select(sql, parameters);
    return rs.first.columnAt(0) as int;
  }
}

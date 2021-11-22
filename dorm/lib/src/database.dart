part of dorm;

///
class Session {
  final DbUri uri;
  Future<Connection> _connection;

  Session(this.uri) : _connection = create(uri);

  /// SQL dialect for this session
  Dialect get dialect => Dialect();

  Future<ResultSet> query(String sql,
      [List<Object> parameters = const []]) async {
    final completer = Completer<ResultSet>();

    _connection.then((conn) {
      conn.query(sql, parameters).then((value) => completer.complete(value));
    });

    return completer.future;
  }

  Future<int> execute(String sql, [List<Object> parameters = const []]) {
    final completer = Completer<int>();

    _connection.then((conn) {
      conn.execute(sql, parameters).then((count) => completer.complete(count));
    });

    return completer.future;
  }

  /// Create [Model] or List<Model>.
  Session add(Object o) {
    if (o is List) {
      for (Model m in o.cast<Model>()) {
        execute(m.insertSql);
      }
    } else if (o is Model) {
      execute(o.insertSql);
    }
    return this;
  }

  Future begin() => execute('BEGIN');

  Future commit() => execute('COMMIT');

  Future rollback() async {
    await execute('ROLLBACK');
    return Future.value(this);
  }

  /// Update object in database as field from instance of model.
  void merge(Model model) {}

  static Future<Connection> create(DbUri uri) async {
    if (uri.scheme == 'sqlite') {
      return Future.value(SqliteConnection.create(uri));
    } else if (uri.scheme == 'mysql') {
      return MysqlConnection.create(uri);
    } else {
      throw UnimplementedError('schema ${uri.scheme}');
    }
  }
}

///
abstract class Connection {
  // static Connection create(DbUri uri);

  ///
  Future<int> execute(String sql, [List<Object> parameters = const []]);

  ///
  Future<ResultSet> query(String sql, [List<Object> parameters = const []]);
}

///
/// The most top class.
///   Database -> Session -> Query
class Database {
  final binds = <String, Session>{};
  final tables = <String, Table>{};

  void add(String bind, String uri) {
    binds[bind] = Session(DbUri.parse(uri));
  }

  void addAll(Map<String, String> map) =>
      map.forEach((bind, uri) => add(bind, uri));

  void register(Type model) {
    Table? table = tableOf(model);

    if (table != null) {
      // TODO: Log multiple retister
      assert(!tables.containsKey(table.name));

      tables[table.name] = table;
    }
  }

  ///
  createAll() {
    tables.forEach((name, atable) {
      if (atable.bind != null) {
        session(atable.bind!)?.execute(atable.createSql);
      }
    });
  }

  Session? session([String bind = 'default']) => binds[bind];

  /// Keep used in test only.
  void clear() {
    binds.clear();
    tables.clear();
  }
}

/// global instance.
final db = Database();

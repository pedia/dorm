part of dorm;

///
class Session {
  final String name;
  final DbUri uri;
  Connection? connection;

  Session(this.name, this.uri);

  /// SQL dialect for this session
  Dialect get dialect => Dialect();

  ResultSet query(String sql, [List<Object?> parameters = const []]) =>
      ensureOpen().query(sql, parameters);

  void execute(String sql, [List<Object?> parameters = const []]) =>
      ensureOpen().execute(sql, parameters);

  void begin() {}
  void commit() {}

  void add(Model model) {}
  void merge(Model model) {}

  Connection ensureOpen() {
    if (connection == null) {
      if (uri.scheme == 'sqlite') {
        // 2.14.0-271.0.dev cause error here
        // force 'as'
        connection = SqliteConnection.create(uri) as Connection;
      } else {
        throw UnimplementedError();
      }
    }
    return connection!;
  }
}

///
abstract class Connection {
  // static Connection create(DbUri uri);

  ///
  void execute(String sql, [List<Object?> parameters = const []]);

  ///
  ResultSet query(String sql, [List<Object?> parameters = const []]);

  /// select count(*) from table;
  int scalar(String sql, [List<Object?> parameters = const []]);
}

///
/// The most top class.
///   Database -> Session -> Query
class Database {
  final binds = <String, Session>{};
  final tables = <String, Table>{};

  add(String bind, String uri) {
    binds[bind] = Session(bind, DbUri.parse(uri));
  }

  register(Type model) {
    Table? table = tableOf(model);

    if (table != null) {
      // TODO: Log multiple retister
      assert(!tables.containsKey(table.name));

      tables[table.name] = table;
    }
  }

  void init(Map<String, String> map) =>
      map.forEach((bind, uri) => add(bind, uri));

  ///
  createAll() {
    tables.forEach((name, atable) {
      if (atable.bind != null) {
        session(atable.bind!)?.ensureOpen().execute(atable.createSql);
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

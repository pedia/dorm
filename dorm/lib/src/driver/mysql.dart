part of dorm;

// CREATE TABLE `bullet` (
//   `bid` int NOT NULL AUTO_INCREMENT,
//   `ctime` datetime DEFAULT NULL,
//   `close_time` datetime DEFAULT NULL,
//   `tid` int DEFAULT NULL,
//   `side` tinyint(1) NOT NULL,
//   `price` float NOT NULL,
//   `close_price` float NOT NULL,
//   `volume` int NOT NULL,
//   `close_volume` int NOT NULL,
//   PRIMARY KEY (`bid`),
//   KEY `tid` (`tid`),
//   CONSTRAINT `bullet_ibfk_1` FOREIGN KEY (`tid`) REFERENCES `trade` (`tid`)
// ) ENGINE=InnoDB AUTO_INCREMENT=287 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci

class MysqlConnection implements Connection {
  final my.Client db;
  MysqlConnection(this.db);

  static Future<Connection> create(DbUri uri) async {
    return MysqlConnection(
      await my.Client.connect(
        user: uri.user!,
        password: uri.password!,
        address: uri.address,
        db: uri.database,
      ),
    );
  }

  @override
  Future<int> execute(String sql, [List<Object> parameters = const []]) async {
    final ir = await db.query(sql, parameters.cast<dynamic>());
    return ir.affectedRows ?? 0;
  }

  @override
  Future<ResultSet> query(String sql,
      [List<Object?> parameters = const []]) async {
    final completer = Completer<ResultSet>();
    db.prepared(sql, parameters.cast<dynamic>()).then((ir) {
      ir.deStream().then((result) {
        final rs = _MyResultSet(result);
        completer.complete(rs);
      });
    });
    return completer.future;
  }
}

class _MyResultSet extends ResultSet {
  final my.ResultSet inner;
  _MyResultSet(this.inner) : super(inner.fields.map((f) => f.name!).toList());

  @override
  Iterator<_MyRow> get iterator => _MyIterator(this);
}

class _MyRow extends Row {
  final my.Row inner;
  _MyRow(Cursor cursor, this.inner) : super(cursor);

  @override
  dynamic columnAt(int i) => inner[i];
}

class _MyIterator extends Iterator<_MyRow> {
  final _MyResultSet result;
  Iterator<my.Row>? iterator;

  _MyIterator(this.result);

  @override
  _MyRow get current {
    iterator ??= result.inner.iterator;
    final c = iterator!.current;
    return _MyRow(result, c);
  }

  @override
  bool moveNext() {
    iterator ??= result.inner.iterator;
    return iterator!.moveNext();
  }
}

part of dorm;

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
    final ir = await db.execute(sql, parameters);
    return ir.affectedRows!;
  }

  @override
  Future<ResultSet> query(String sql,
      [List<Object?> parameters = const []]) async {
    final completer = Completer<ResultSet>();
    db.execute(sql, parameters).then((rs) {
      completer.complete(_MyResultSet(rs));
    });
    return completer.future;
  }
}

class _MyResultSet extends ResultSet {
  final my.BinaryResultSet inner;
  _MyResultSet(this.inner) : super(inner.cds.map((f) => f.name).toList());

  @override
  Iterator<_MyRow> get iterator => _MyIterator(this);
}

class _MyRow extends Row {
  final my.BinaryRow inner;
  _MyRow(Cursor cursor, this.inner) : super(cursor);

  @override
  dynamic columnAt(int i) => inner.values[i];
}

class _MyIterator extends Iterator<_MyRow> {
  final _MyResultSet result;
  Iterator<my.BinaryRow>? iterator;

  _MyIterator(this.result);

  @override
  _MyRow get current {
    iterator ??= result.inner.rows.iterator;
    final c = iterator!.current;
    return _MyRow(result, c);
  }

  @override
  bool moveNext() {
    iterator ??= result.inner.rows.iterator;
    return iterator!.moveNext();
  }
}

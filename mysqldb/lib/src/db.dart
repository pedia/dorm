part of mysql.server;

///
abstract class Database {
  Future<Packet> handle(CommandPacket cmd);
}

///
class MockDatabase extends Database {
  String? db;

  final _builtinDatabase = ResultSet([
    ColumnDefinition(
      schema: 'information_schema',
      table: 'SCHEMATA',
      orgTable: 'SCHEMATA',
      name: 'Database',
      orgName: 'SCHEMA_NAME',
      columnLength: 192,
      columnType: Field.typeVarString,
    )
  ], [
    [Field.string('mock')]
  ]);

  final _tables = ResultSet([
    ColumnDefinition(
      schema: 'information_schema',
      table: 'TABLE_NAMES',
      orgTable: 'TABLE_NAMES',
      name: 'Tables_in_test',
      orgName: 'TABLE_NAME',
      columnLength: 192,
      columnType: Field.typeVarString,
    )
  ], [
    [Field.string('types')]
  ]);

  final _columns = [
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'id',
      orgName: 'id',
      columnLength: 11,
      columnType: Field.typeLong,
      inComFieldList: true,
      decimals: 0,
      flags: 0x5003,
    ),
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'vs',
      orgName: 'vs',
      columnLength: 300,
      columnType: Field.typeVarString,
      inComFieldList: true,
      decimals: 0,
    ),
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'cs',
      orgName: 'cs',
      columnLength: 15,
      columnType: Field.typeString,
      inComFieldList: true,
      decimals: 0,
    ),
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'ti',
      orgName: 'ti',
      columnLength: 4,
      columnType: Field.typeTiny,
      inComFieldList: true,
      decimals: 0,
    ),
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'si',
      orgName: 'si',
      columnLength: 6,
      columnType: Field.typeShort,
      inComFieldList: true,
      decimals: 0,
    ),
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'li',
      orgName: 'li',
      columnLength: 11,
      columnType: Field.typeLong,
      inComFieldList: true,
      decimals: 0,
    ),
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'bi',
      orgName: 'bi',
      columnLength: 20,
      columnType: Field.typeLonglong,
      inComFieldList: true,
      decimals: 0,
    ),
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'di',
      orgName: 'di',
      columnLength: 12,
      columnType: Field.typeDecimal,
      inComFieldList: true,
      decimals: 4,
    ),
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'dt',
      orgName: 'dt',
      columnLength: 19,
      columnType: Field.typeDatetime,
      inComFieldList: true,
      decimals: 0,
      flags: 0x80,
    ),
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'st',
      orgName: 'st',
      columnLength: 19,
      columnType: Field.typeTimestamp,
      inComFieldList: true,
      decimals: 0,
      flags: 0x2481,
    ),
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'e',
      orgName: 'e',
      columnLength: 3,
      columnType: Field.typeEnum,
      inComFieldList: true,
      decimals: 0,
      flags: 0x100,
    ),
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'b',
      orgName: 'b',
      columnLength: 65535,
      columnType: Field.typeEnum,
      inComFieldList: true,
      decimals: 0,
      flags: 0x90,
    ),
    ColumnDefinition(
      schema: 'mock',
      table: 'types',
      orgTable: 'types',
      name: 'g',
      orgName: 'g',
      columnLength: 4294967295,
      columnType: Field.typeGeometry,
      inComFieldList: true,
      decimals: 0,
      flags: 0x90,
    ),
  ];

  Future<Packet> query(String sql) {
    if (sql == 'select @@version_comment limit 1') {
      return Future.value(ResultSet([
        ColumnDefinition.varString(
            table: '', name: '@@version_comment', columnLength: 84)
      ], [
        [Field.string('MySQL Community Server (GPL)')]
      ]));
    } else if (sql == 'SELECT DATABASE()' || sql.startsWith('show databases')) {
      return Future.value(_builtinDatabase);
    } else if (sql.startsWith('show tables')) {
      return Future.value(_tables);
    }
    // pymysql
    else if (sql.startsWith('SET AUTOCOMMIT =') ||
        sql == 'COMMIT' ||
        sql.startsWith('SET NAMES ') ||
        sql.startsWith('SET @@session.')) {
      return Future.value(OkPacket(serverStatus: 0));
    }
    // https://github.com/mysql/mysql-connector-python query begin with \x00\x01
    else if (sql.startsWith('\x00\x01')) {
      String left = sql.substring(2);
      if (left.startsWith('SET NAMES ') || left.startsWith('SET @@session.')) {
        return Future.value(OkPacket(serverStatus: 0));
      } else if (left == 'SELECT CURDATE()') {
        final now = DateTime.now();
        return Future.value(ResultSet([
          ColumnDefinition.varString(
              table: '', name: 'curdate()', columnLength: 19)
        ], [
          [
            Field(
              DateTime(now.year, now.day, now.day),
              Field.typeDate,
            )
          ]
        ]));
      }
    }

    return Future.value(ResultSet.empty());
  }

  @override
  Future<Packet> handle(CommandPacket cmd) {
    final c = Completer<Packet>();
    // MySQL 客户端发送 initdb, 改为 use xx 发送给 Dremio
    // 回复 MySQL 客户端 OkPacket
    if (cmd.command == Command.initDb) {
      final dbName = (cmd as QueryCommand).sql;
      if (dbName != 'mock') {
        return Future.value(ErrorPacket(
          code: 1049,
          state: '42000',
          message: "Unknown database '$dbName'",
        ));
      }

      db = dbName;
      return Future.value(OkPacket());
    } else if (cmd.command == Command.ping) {
      return Future.value(OkPacket());
    } else if (cmd.command == Command.fieldList) {
      if (db == null) {
        return Future.value(ErrorPacket(
          code: 1046,
          state: '3D000',
          message: 'No database selected',
        ));
      }

      final tableName = (cmd as FieldListCommand).table;
      if (tableName.toLowerCase() != 'types') {
        return Future.value(ErrorPacket(
          code: 1146,
          state: '42S02',
          message: "Table '$db!.$tableName' doesn't exist",
        ));
      }

      return Future.value(FieldListResponse(_columns));
    } else if (cmd.command == Command.query) {
      query((cmd as QueryCommand).sql).then((rs) {
        c.complete(rs);
      });
    }
    return c.future;
  }
}

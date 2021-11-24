part of mysql.server;

abstract class Database {
  Future<ResultSet?> query(String sql);
  // {
  //   return ResultSet.empty();
  // final rs = parser.extract(sql);

  // final coldefs = <ColumnDefinition>[];

  // for (var r in rs) {
  //   final ns = r.tables.map((t) => t.name).join(',');
  //   print('table: $ns');

  //   for (var col in r.columns) {
  //     print('col name: ${col.name}');

  //     coldefs.add(ColumnDefinition.varString(ns, col.name!, 32));
  //   }
  // }

  // if (coldefs.isEmpty) {
  //   coldefs.add(ColumnDefinition.varString('table', 'column', 32));
  // }

  // final rows = <Row>[
  //   [Field(value: 'foo', def: coldefs[0])],
  //   [Field(value: 'bar', def: coldefs[0])],
  // ];

  // final resultSet = ResultSet(coldefs, rows);
  // return resultSet;
  // }
}

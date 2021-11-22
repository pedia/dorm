// ignore_for_file: constant_identifier_names, hash_and_equals

class Ident {
  final String value;
  final String? quoteStyle;
  const Ident(this.value, {this.quoteStyle});

  factory Ident.from(Map jm) =>
      Ident(jm['value'], quoteStyle: jm['quote_style']);

  @override
  bool operator ==(Object other) => other is Ident && other.value == value;
}

/// `[ NOT ] IN (val1, val2, ...)`
class InList {
  final Expr expr;
  final List<Expr> list;
  final bool negated;
  const InList({required this.expr, required this.list, required this.negated});

  factory InList.from(Map jm) => InList(
        expr: Expr.from(jm['expr'])!,
        list: (jm['expr'] as List).map((i) => Expr.from(i)!).toList(),
        negated: jm['negated'],
      );
}

/// `[ NOT ] IN (SELECT ...)`
class InSubquery {
  final Expr expr;
  final Query subquery;
  final bool negated;
  InSubquery(
      {required this.expr, required this.subquery, required this.negated});
  factory InSubquery.from(Map jm) => InSubquery(
        expr: Expr.from(jm['expr'])!,
        subquery: Query.from(jm['subquery']),
        negated: jm['negated'],
      );
}

class Query extends Statement {
  /// WITH (common table expressions, or CTEs)
  final With? with_;

  /// SELECT or UNION / EXCEPT / INTERSECT
  final SetExpr body;

  /// ORDER BY
  final List<OrderByExpr> orderBy;

  /// `LIMIT { <N> | ALL }`
  final Expr? limit;

  /// `OFFSET <N> [ { ROW | ROWS } ]`
  final Offset? offset;

  /// `FETCH { FIRST | NEXT } <N> [ PERCENT ] { ROW | ROWS } | { ONLY | WITH TIES }`
  final Fetch? fetch;
  Query({
    this.with_,
    required this.body,
    required this.orderBy,
    this.limit,
    this.offset,
    this.fetch,
  });

  factory Query.from(Map jm) => Query(
        body: SetExpr.from(jm['body']),
        orderBy:
            (jm['order_by'] as List).map((i) => OrderByExpr.from(i)).toList(),
        limit: jm['limit'] != null ? Expr.from(jm['limit']) : null,
        offset: Offset.from(jm['offset']),
        fetch: Fetch.from(jm['fetch']),
      );
}

enum SetOperator {
  union,
  except,
  intersect,
}

/// UNION/EXCEPT/INTERSECT of two queries
class SetOperation {
  final SetOperator op;
  final bool all;
  final SetExpr left;
  final SetExpr right;
  const SetOperation(this.op, this.all, this.left, this.right);
}

class Select {
  final bool distinct;

  /// MSSQL syntax: `TOP (<N>) [ PERCENT ] [ WITH TIES ]`
  final Top? top;

  /// projection expressions
  final List<SelectItem> projection;

  /// FROM
  final List<TableWithJoins> from_;

  /// LATERAL VIEWs
  final List<LateralView> lateralViews;

  /// WHERE
  final Expr? selection;

  /// GROUP BY
  final List<Expr>? groupBy;

  /// CLUSTER BY (Hive)
  final List<Expr>? clusterBy;

  /// DISTRIBUTE BY (Hive)
  final List<Expr>? distributeBy;

  /// SORT BY (Hive)
  final List<Expr>? sortBy;

  /// HAVING
  final Expr? having;

  Select({
    required this.distinct,
    this.top,
    this.projection = const <SelectItem>[],
    this.from_ = const <TableWithJoins>[],
    this.lateralViews = const <LateralView>[],
    this.selection,
    this.groupBy,
    this.clusterBy,
    this.distributeBy,
    this.sortBy,
    this.having,
  });

  factory Select.from(Map jm) => Select(
        distinct: jm['distinct'],
        top: Top.from(jm['top']),
        projection:
            (jm['projection'] as List).map((i) => SelectItem.from(i)).toList(),
        from_: (jm['from'] as List).map((i) => TableWithJoins.from(i)).toList(),
        lateralViews: (jm['lateral_views'] as List)
            .map((i) => LateralView.from(i))
            .toList(),
      );
}

typedef ObjectName = List<Ident>;

class LateralView {
  /// LATERAL VIEW
  final Expr lateralView;

  /// LATERAL VIEW table name
  final ObjectName lateralViewName;

  /// LATERAL VIEW optional column aliases
  final List<Ident> lateralColAlias;

  /// LATERAL VIEW OUTER
  final bool outer;
  const LateralView({
    required this.lateralView,
    required this.lateralViewName,
    required this.lateralColAlias,
    required this.outer,
  });

  factory LateralView.from(Map jm) => LateralView(
        lateralView: Expr.from(jm['lateral_views'])!,
        lateralViewName: (jm['lateral_view_name'] as List)
            .map((i) => Ident.from(i))
            .toList(),
        lateralColAlias: (jm['lateral_col_alias'] as List)
            .map((i) => Ident.from(i))
            .toList(),
        outer: jm['outer'],
      );
}

class With {
  final bool recursive;
  final List<Cte> tables;
  const With(this.recursive, this.tables);
}

/// A single CTE (used after `WITH`): `alias [(col1, col2, ...)] AS ( query )`
/// The names in the column list before `AS`, when specified, replace the names
/// of the columns returned by the query. The parser does not validate that the
/// number of columns in the query matches the number of columns in the query.
class Cte {
  TableAlias alias;
  Query query;
  Ident? from_;
  Cte(this.alias, this.query, this.from_);
}

class ExprWithAlias {
  Expr expr;
  Ident alias;
  ExprWithAlias({required this.expr, required this.alias});
  factory ExprWithAlias.from(Map jm) => ExprWithAlias(
        expr: Expr.from(jm['expr'])!,
        alias: Ident.from(jm['alias']),
      );
}

class SelectItem {
  /// Any expression, not followed by `[ AS ] alias`
  Expr? unnamedExpr;

  /// An expression, followed by `[ AS ] alias`
  ExprWithAlias? exprWithAlias;

  /// `alias.*` or even `schema.table.*`
  ObjectName? qualifiedWildcard;

  /// An unqualified `*`
  bool? wildcard;

  SelectItem({
    this.unnamedExpr,
    this.exprWithAlias,
    this.qualifiedWildcard,
    this.wildcard,
  });

  factory SelectItem.from(Map jm) {
    if (jm.containsKey('UnnamedExpr')) {
      return SelectItem(unnamedExpr: Expr.from(jm['UnnamedExpr']));
    }

    if (jm.containsKey('ExprWithAlias')) {
      return SelectItem(exprWithAlias: ExprWithAlias.from(jm['ExprWithAlias']));
    }

    if (jm.containsKey('Wildcard')) {
      return SelectItem(wildcard: true);
    }

    throw Exception();
  }
}

class TableWithJoins {
  TableFactor relation;
  List<Join> joins;
  TableWithJoins({required this.relation, required this.joins});
  factory TableWithJoins.from(Map jm) => TableWithJoins(
        relation: TableFactor.from(jm['relation']),
        joins: (jm['joins'] as List).map((i) => Join.from(i)).toList(),
      );
}

class FunctionArg {
  final Ident? name;
  final Expr? arg;
  final Expr? unnamed;
  FunctionArg({this.name, this.arg, this.unnamed});
  factory FunctionArg.from(Map jm) => FunctionArg(
        unnamed: Expr.from(jm['Unnamed']),
      );
}

class Method {
  ObjectName name;
  List<FunctionArg> args;
  bool distinct;
  Method({required this.name, required this.args, required this.distinct});

  static Method? from(Map? jm) => jm == null
      ? null
      : Method(
          name: (jm['name'] as List).map((i) => Ident.from(i)).toList(),
          args: (jm['args'] as List).map((i) => FunctionArg.from(i)).toList(),
          distinct: jm['distinct'],
        );
}

/// A table name or a parenthesized subquery with an optional alias
class Table {
  ObjectName name;
  TableAlias? alias;

  /// Arguments of a table-valued function, as supported by Postgres
  /// and MSSQL. Note that deprecated MSSQL `FROM foo (NOLOCK)` syntax
  /// will also be parsed as `args`.
  List<FunctionArg> args;

  /// MSSQL-specific `WITH (...)` hints such as NOLOCK.
  List<Expr> withHints;

  Table({
    required this.name,
    this.alias,
    required this.args,
    required this.withHints,
  });

  static Table? from(Map? jm) => jm == null
      ? null
      : Table(
          name: (jm['name'] as List).map((i) => Ident.from(i)).toList(),
          alias: TableAlias.from(jm['alias']),
          args: (jm['args'] as List).map((i) => FunctionArg.from(i)).toList(),
          withHints:
              (jm['with_hints'] as List).map((i) => Expr.from(i)!).toList(),
        );
}

class Derived {
  bool lateral;
  Query subquery;
  TableAlias? alias;
  Derived({required this.lateral, required this.subquery, this.alias});
  static Derived? from(Map? jm) => jm == null
      ? null
      : Derived(
          lateral: jm['lateral'],
          subquery: Query.from(jm['subquery']),
          alias: TableAlias.from(jm['alias']),
        );
}

/// `TABLE(<expr>)[ AS <alias> ]`
class TableFunction {
  Expr expr;
  TableAlias? alias;
  TableFunction(this.expr, this.alias);
}

/// Represents a parenthesized table factor. The SQL spec only allows a
/// join expression (`(foo <JOIN> bar [ <JOIN> baz ... ])`) to be nested,
/// possibly several times.
///
/// The parser may also accept non-standard nesting of bare tables for some
/// dialects, but the information about such nesting is stripped from AST.
// TODO: NestedJoin(TableWithJoins),

class TableFactor {
  Table? table;
  Derived? derived;
  TableFunction? tableFunction;
  TableWithJoins? tableWithJoins;
  TableFactor({
    this.table,
    this.derived,
    this.tableFunction,
    this.tableWithJoins,
  });
  factory TableFactor.from(Map jm) => TableFactor(
        table: Table.from(jm['Table']),
        derived: Derived.from(jm['Derived']),
      );
}

class TableAlias {
  Ident name;
  List<Ident> columns;
  TableAlias({required this.name, required this.columns});
  static TableAlias? from(Map? jm) => jm == null
      ? null
      : TableAlias(
          name: Ident.from(jm['name']),
          columns: (jm['columns'] as List).map((i) => Ident.from(i)).toList(),
        );
}

class Join {
  final TableFactor relation;
  final JoinOperator joinOperator;
  Join({required this.relation, required this.joinOperator});
  factory Join.from(Map jm) => Join(
        relation: TableFactor.from(jm['relation']),
        joinOperator: JoinOperator.from(jm['join_operator']),
      );
}

enum JoinOperatorType {
  crossJoin,

  /// CROSS APPLY (non-standard)
  crossApply,

  /// OUTER APPLY (non-standard)
  outerApply,
}

class JoinOperator {
  JoinConstraint? inner;
  JoinConstraint? leftOuter;
  JoinConstraint? rightOuter;
  JoinConstraint? fullOuter;

  /// TODO:
  JoinOperatorType get joinType => JoinOperatorType.crossApply;

  JoinOperator({
    this.inner,
    this.leftOuter,
    this.rightOuter,
    this.fullOuter,
  });

  factory JoinOperator.from(Map jm) => JoinOperator(
        inner: jm['Inner'],
        leftOuter: JoinConstraint.from(jm['LeftOuter']),
        rightOuter: jm['RightOuter'],
        fullOuter: jm['FullOuter'],
      );
}

enum JoinConstraintType {
  natural,
  none,
}

class JoinConstraint {
  Expr? on_;
  List<Ident>? using;
  JoinConstraintType? type;
  JoinConstraint({this.on_, this.using, this.type});
  factory JoinConstraint.from(Map jm) => JoinConstraint(
        on_: Expr.from(jm['On']),
      );
}

class OrderByExpr {
  Expr expr;

  /// Optional `ASC` or `DESC`
  bool? asc;

  /// Optional `NULLS FIRST` or `NULLS LAST`
  bool? nullsFirst;
  OrderByExpr({
    required this.expr,
    this.asc,
    this.nullsFirst,
  });

  factory OrderByExpr.from(Map map) => OrderByExpr(
        expr: Expr.from(map['expr'])!,
      );
}

enum OffsetRows {
  /// Omitting ROW/ROWS is non-standard MySQL quirk.
  none,
  row,
  rows,
}

class Offset {
  final Expr value;
  final OffsetRows rows;
  const Offset({required this.value, required this.rows});
  static Offset? from(Map? jm) => jm == null
      ? null
      : Offset(
          value: Expr.from(jm['value'])!,
          rows: jm['rows'], // TODO: enum from String
        );
}

class Fetch {
  final bool withTies;
  final bool percent;
  final Expr? quantity;
  const Fetch({required this.withTies, required this.percent, this.quantity});
  static Fetch? from(Map? jm) => jm == null
      ? null
      : Fetch(
          withTies: jm['WithTies'],
          percent: jm['percent'],
          quantity: Expr.from(jm['quantity']),
        );
}

class Top {
  /// SQL semantic equivalent of LIMIT but with same structure as FETCH.
  final bool withTies;
  final bool percent;
  final Expr? quantity;
  const Top({required this.withTies, required this.percent, this.quantity});
  static Top? from(Map? jm) => jm == null
      ? null
      : Top(
          withTies: jm['WithTies'],
          percent: jm['percent'],
          quantity: Expr.from(jm['quantity']),
        );
}

typedef Values = List<List<Expr>>;

/// A node in a tree, representing a "query body" expression, roughly:
/// `SELECT ... [ {UNION|EXCEPT|INTERSECT} SELECT ...]`
class SetExpr {
  /// Restricted SELECT .. FROM .. HAVING (no ORDER BY or set operations)
  Select? select;

  /// Parenthesized SELECT subquery, which may include more set operations
  /// in its body and an optional ORDER BY / LIMIT.
  Query? query;

  Values? values;
  Statement? insert;
  SetExpr({this.select, this.query, this.values, this.insert});

  factory SetExpr.from(Map jm) => SetExpr(
        select: Select.from(jm['Select']),
      );
}

enum BinaryOperator {
  Plus,
  Minus,
  Multiply,
  Divide,
  Modulo,
  StringConcat,
  Gt,
  Lt,
  GtEq,
  LtEq,
  Spaceship,
  Eq,
  NotEq,
  And,
  Or,
  Xor,
  Like,
  NotLike,
  ILike,
  NotILike,
  BitwiseOr,
  BitwiseAnd,
  BitwiseXor,
  PGBitwiseXor,
  PGBitwiseShiftLeft,
  PGBitwiseShiftRight,
  PGRegexMatch,
  PGRegexIMatch,
  PGRegexNotMatch,
  PGRegexNotIMatch,
}

BinaryOperator binaryOperatorFromString(String s) {
  return BinaryOperator.values
      .where((i) => i.toString().split('.')[1] == s)
      .first;
}

class BinaryOp {
  Expr left;
  BinaryOperator op;
  Expr right;
  BinaryOp({required this.left, required this.op, required this.right});
  factory BinaryOp.from(Map jm) => BinaryOp(
        left: Expr.from(jm['left'])!,
        op: binaryOperatorFromString(jm['op']),
        right: Expr.from(jm['right'])!,
      );
}

class Expr {
  /// table name or column name
  final Ident? ident;

  final bool wildcard;

  /// `alias.*` or `schema.table.*`.
  final List<Ident>? qualifiedWildcard;

  /// `table_alias.column` or `schema.table.col`
  final List<Ident>? compounds;

  /// `IS NULL` operator
  final Expr? isNull;

  /// `IS NOT NULL` operator
  final Expr? isNotNull;

  /// `IS DISTINCT FROM` operator
  final List<Expr>? isDistinctFrom;

  /// `IS NOT DISTINCT FROM` operator
  final List<Expr>? isNotDistinctFrom;

  /// `[ NOT ] IN (val1, val2, ...)`
  final InList? inList;

  final InSubquery? inSubquery;

  final BinaryOp? binaryOp;

  // TODO: ...
  final Method? function;

  final Query? exists;
  final Query? subquery;

  const Expr({
    this.ident,
    this.wildcard = false,
    this.qualifiedWildcard,
    this.compounds,
    this.isNull,
    this.isNotNull,
    this.isDistinctFrom,
    this.isNotDistinctFrom,
    this.inList,
    this.inSubquery,
    this.binaryOp,
    this.function,
    this.exists,
    this.subquery,
  });

  static Expr? from(Object? jm) {
    if (jm == null) {
      return null;
    }

    if (jm is String && jm == 'Wildcard') {
      return Expr(wildcard: true);
    }

    if (jm is Map) {
      return Expr(
        ident:
            jm.containsKey('Identifier') ? Ident.from(jm['Identifier']) : null,
        compounds: jm.containsKey('CompoundIdentifier')
            ? (jm['CompoundIdentifier'] as List)
                .map((i) => Ident.from(i))
                .toList()
            : [],
        function:
            jm.containsKey('Function') ? Method.from(jm['Function']) : null,
        binaryOp:
            jm.containsKey('BinaryOp') ? BinaryOp.from(jm['BinaryOp']) : null,
      );
    }

    throw Exception();
  }
}

abstract class Statement {
  static Statement? from(Object jm) {
    assert(jm is Map);
    if (jm is Map && jm.isNotEmpty) {
      final e = jm.entries.first;
      if (e.key == 'Query') {
        return Query.from(e.value);
      } else if (e.key == 'ShowVariable') {
        return ShowVariable.from(e.value);
      }
    }
  }
}

class Analyze extends Statement {
  ObjectName tableName;
  List<Expr>? partitions;
  bool forColumns;
  List<Ident>? columns;
  bool cacheMetadata;
  bool noscan;
  bool computeStatistics;
  Analyze(
    this.tableName,
    this.partitions,
    this.forColumns,
    this.columns,
    this.cacheMetadata,
    this.noscan,
    this.computeStatistics,
  );
}

class Truncate extends Statement {
  ObjectName tableName;
  List<Expr> partitions;
  Truncate(this.tableName, this.partitions);
}

class Insert extends Statement {
  /// Only for Sqlite
  // SqliteOnConflict? or;
  /// TABLE
  ObjectName tableName;

  /// COLUMNS
  List<Ident> columns;

  /// Overwrite (Hive)
  bool overwrite;

  /// A SQL query that specifies what to insert
  Query source;

  /// partitioned insert (Hive)
  List<Expr>? partitioned;

  /// Columns defined after PARTITION
  List<Ident> afterColumns;

  /// whether the insert has the table keyword (Hive)
  bool table;

  Insert(this.tableName, this.columns, this.overwrite, this.source,
      this.partitioned, this.afterColumns, this.table);
}

class Assignment {
  final Ident id;
  final Expr value;
  Assignment(this.id, this.value);
}

enum DateTimeField {
  year,
  month,
  day,
  hour,
  minute,
  second,
}

class Interval {
  final String value;
  final DateTimeField? leadingField;
  final int? leadingPrecision;
  final DateTimeField? lastField;
  final int fractionalSecondsPrecision;
  Interval(this.value, this.leadingField, this.leadingPrecision, this.lastField,
      this.fractionalSecondsPrecision);
}

class Value {
  final String? number;
  final String nationalStringLiteral;
  final String hexStringLiteral;
  final String doubleQuotedString;
  final bool boolean;
  Value(this.number, this.nationalStringLiteral, this.hexStringLiteral,
      this.doubleQuotedString, this.boolean);
}

class SqlOption {
  final Ident name;
  final Value value;
  SqlOption(this.name, this.value);
}

class Update extends Statement {
  /// TABLE
  ObjectName tableName;

  /// Column assignments
  List<Assignment> assignments;

  /// WHERE
  Expr? selection;
  Update(this.tableName, this.assignments, this.selection);
}

class Delete extends Statement {
  /// FROM
  ObjectName tableName;

  /// WHERE
  Expr? selection;
  Delete(this.tableName, this.selection);
}

class CreateView extends Statement {
  bool orReplace;
  bool materialized;

  /// View name
  ObjectName name;
  List<Ident> columns;
  Query query;
  List<SqlOption> withOptions;
  CreateView(
    this.orReplace,
    this.materialized,
    this.name,
    this.columns,
    this.query,
    this.withOptions,
  );
}

enum ReferentialAction {
  restrict,
  cascade,
  setNull,
  noAction,
  setDefault,
}

class ForeignKey {
  ObjectName foreignTable;
  List<Ident> referredColumns;
  ReferentialAction? onDelete;
  ReferentialAction? onUpdate;
  ForeignKey(
      this.foreignTable, this.referredColumns, this.onDelete, this.onUpdate);
}

class ColumnOptionDef {
  Ident? name;
  bool? isNull;
  bool? isNotNull;
  Expr? defaultValue;
  bool? unique;
  bool? isPrimary;
}

enum DataType {
  /// Fixed-length character type e.g. CHAR(10)
  char,

  /// Variable-length character type e.g. VARCHAR(10)
  varchar,

  /// Uuid type
  uuid,

  /// Large character object e.g. CLOB(1000)
  clob,

  /// Fixed-length binary type e.g. BINARY(10)
  binary,

  /// Variable-length binary type e.g. VARBINARY(10)
  varbinary,

  /// Large binary object e.g. BLOB(1000)
  blob,

  /// Decimal type with optional precision and scale e.g. DECIMAL(10,2)
  decimal,

  /// Floating point with optional precision e.g. FLOAT(8)
  float,

  /// Tiny integer with optional display width e.g. TINYINT or TINYINT(3)
  tinyInt,

  /// Small integer with optional display width e.g. SMALLINT or SMALLINT(5)
  smallInt,

  /// Integer with optional display width e.g. INT or INT(11)
  integer,

  /// Big integer with optional display width e.g. BIGINT or BIGINT(20)
  bigInt,

  /// Floating point e.g. REAL
  real,

  /// Double e.g. DOUBLE PRECISION
  double,

  /// Boolean
  boolean,

  /// Date
  date,

  /// Time
  time,

  /// Timestamp
  timestamp,

  /// Interval
  interval,

  /// Regclass used in postgresql serial
  regclass,

  /// Text
  text,

  /// String
  string,

  /// Bytea
  bytea,

  /// Custom type such as enums
  custom,

  /// Arrays
  array,
}

class ColumnDef {
  Ident name;
  DataType dataType;
  ObjectName? collation;
  List<ColumnOptionDef>? options;
  ColumnDef(this.name, this.dataType, this.collation, this.options);
}

class Unique {
  Ident? name;
  List<Ident> columns;
  bool isPrimary;
  Unique(this.name, this.columns, this.isPrimary);
}

class TableConstraint {
  Unique unique;
  ForeignKey foreignKey;
  Check check;
  TableConstraint(this.unique, this.foreignKey, this.check);
}

class Check {
  Ident? name;
  Expr expr;
  Check(this.name, this.expr);
}

class CreateTable extends Statement {
  bool orReplace;
  bool temporary;
  bool external;
  bool ifNotExists;

  /// Table name
  ObjectName name;

  /// Optional schema
  List<ColumnDef> columns;
  List<TableConstraint> constraints;
  // HiveDistributionStyle hive_distribution;
  // HiveFormat? hive_formats;
  List<SqlOption> tableProperties;
  List<SqlOption> withOptions;
  // FileFormat? file_format;
  String? location;
  Query? query;
  bool withoutRowid;
  ObjectName? like;

  CreateTable(
    this.orReplace,
    this.temporary,
    this.external,
    this.ifNotExists,
    this.name,
    this.columns,
    this.constraints,
    this.tableProperties,
    this.withOptions,
    this.location,
    this.query,
    this.withoutRowid,
    this.like,
  );
}

class CreateIndex extends Statement {
  /// index name
  ObjectName name;
  ObjectName tableName;
  List<OrderByExpr> columns;
  bool unique;
  bool ifNotExists;
  CreateIndex(
      this.name, this.tableName, this.columns, this.unique, this.ifNotExists);
}

class AlterTableOperation {
  /// `ADD <table_constraint>`
  TableConstraint? addConstraint;

  /// `ADD [ COLUMN ] <column_def>`
  ColumnDef? addColumnDef;

  /// TODO: implement `DROP CONSTRAINT <name>`
  Ident? dropConstraintName;

  /// `DROP [ COLUMN ] [ IF EXISTS ] <column_name> [ CASCADE ]`
  Ident? columnNme;
  bool? ifExists;
  bool? cascade;

  /// `RENAME [ COLUMN ] <old_column_name> TO <new_column_name>`
  Ident? oldColumnName;
  Ident? newColumnName;

  /// `RENAME TO <tableName>`
  ObjectName? renameTableName;
}

class AlterTable extends Statement {
  /// Table name
  final ObjectName name;
  final AlterTableOperation operation;
  AlterTable(this.name, this.operation);
}

enum ObjectType {
  table,
  view,
  index_,
  schema,
}

class Drop extends Statement {
  /// The type of the object to drop;
  final ObjectType objectType;

  /// An optional `IF EXISTS` clause. (Non-standard.)
  final bool ifExists;

  /// One or more objects to drop. (ANSI SQL requires exactly one.)
  final List<ObjectName> names;

  /// Whether `CASCADE` was specified. This will be `false` when
  /// `RESTRICT` or no drop behavior at all was specified.
  final bool cascade;

  /// Hive allows you specify whether the table's stored data will be
  /// deleted along with the dropped table
  final bool purge;
  Drop(this.objectType, this.ifExists, this.names, this.cascade, this.purge);
}

class SetVariableValue {
  Ident ident;
  Value literal;
  SetVariableValue(this.ident, this.literal);
}

class SetVariable extends Statement {
  final bool local;
  final bool hivevar;
  final Ident variable;
  final List<SetVariableValue> value;
  SetVariable(this.local, this.hivevar, this.variable, this.value);
}

class ShowVariable extends Statement {
  final List<Ident> variable;
  ShowVariable(this.variable);
  factory ShowVariable.from(Map jm) =>
      ShowVariable((jm['variable'] as List).map((v) => Ident.from(v)).toList());
}

enum ShowCreateObject {
  event,
  function,
  procedure,
  table,
  trigger,
}

class ShowCreate extends Statement {
  final ShowCreateObject objType;
  final ObjectName objName;
  ShowCreate(this.objType, this.objName);
}

class ShowStatementFilter {
  final String? like;
  final String? iLike;
  final Expr? where;
  ShowStatementFilter(this.like, this.iLike, this.where);
}

class ShowColumns {
  final bool extended;
  final bool full;
  final ObjectName tableName;
  final ShowStatementFilter? filter;
  ShowColumns(this.extended, this.full, this.tableName, this.filter);
}

// class StartTransaction {
//   List<TransactionMode> modes;
// }

// class SetTransaction {
//   List<TransactionMode> modes;
// }

// class Commit {
//   bool chain;
// }

// class Rollback {
//   bool chain;
// }

class CreateSchema {
  final ObjectName schemaName;
  final bool ifNotExists;
  CreateSchema(this.schemaName, this.ifNotExists);
}

class CreateDatabase extends Statement {
  final ObjectName dbName;
  final bool ifNotExists;
  final String? location;
  final String? managedLocation;
  CreateDatabase(
      this.dbName, this.ifNotExists, this.location, this.managedLocation);
}

class Execute extends Statement {
  final Ident name;
  final List<Expr> parameters;
  Execute(this.name, this.parameters);
}

class ExplainTable extends Statement {
  // If true, query used the MySQL `DESCRIBE` alias for explain
  final bool describeAlias;
  // Table name
  final ObjectName tableName;
  ExplainTable(this.describeAlias, this.tableName);
}

class Explain extends Statement {
  // If true, query used the MySQL `DESCRIBE` alias for explain
  bool describeAlias;

  /// Carry out the command and show actual run times and other statistics.
  bool analyze;
  // Display additional information regarding the plan.
  bool verbose;

  /// A SQL query that specifies what to explain
  Statement statement;

  Explain(this.describeAlias, this.analyze, this.verbose, this.statement);
}

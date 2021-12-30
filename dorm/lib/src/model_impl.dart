import 'dart:cli';

import 'package:dorm/annotation.dart';
import 'package:dorm/src/dialect.dart';
import 'package:dorm/src/result_set.dart';
import 'package:dorm/src/database.dart';

/// Help extension extract [String] typed [name].
/// Symbol("id") => id
extension _SymbolWithName on Symbol {
  String get name => toString().split('"')[1];
}

/// Real [Table] in database.
class Table extends table {
  List<Field> fields;

  Table({
    required table base,
    required this.fields,
  }) : super(base.name, bind: base.bind);

  /// CREATE TABLE article (id INT PRIMARY KEY, name varchar(100) NOT NULL);
  String get createSql {
    String fs = fields.map((f) => f.sqlClause(dialect)).toList().join(', ');
    return 'CREATE TABLE IF NOT EXISTS `$name` ($fs)';
  }

  Dialect get dialect {
    if (_dialect == null && bind != null) {
      _dialect = db.session(bind!)?.dialect;
    }

    // default Dialect
    _dialect ??= Dialect();
    return _dialect!;
  }

  Iterable<Field> get indexes =>
      fields.where((f) => f.primaryKey || f.index || f.unique);

  Iterable<Field> get foreignKeys => fields.where((f) => f.foreignKey != null);

  /// Cached dialect.
  Dialect? _dialect;
}

/// Field with name
class Field extends field {
  /// Name of instance.
  final Symbol symbol;

  /// Type of instance.
  final ClassMirror type;
  Field({
    required this.symbol,
    required this.type,
    required field base,
  }) : super(
          name: base.name ?? symbol.name,
          primaryKey: base.primaryKey,
          autoIncrement: base.autoIncrement,
          nullable: base.nullable,
          defaultValue: base.defaultValue,
          unique: base.unique,
          index: base.index,
          maxLength: base.maxLength,
          doc: base.doc,
        );

  /// Name of this field in database.
  /// Rewrite name? to name!
  @override
  String get name => super.name!;

  /// Type name in Dart, like: 'int', 'String', 'double'
  String get typeName => type.simpleName.name;

  /// Create table sql part of this field.
  /// like:
  ///   a int PRIMARY KEY NOT NULL
  ///   b TEXT;
  ///   c varchar(100);
  String sqlClause([Dialect dialect = const Dialect()]) => [
        name, // field name
        dialect.typeNameOf(type.reflectedType),
        if (this.primaryKey) 'PRIMARY KEY',
        if (autoIncrement) 'AUTOINCREMENT',
        if (defaultValue != null) 'DEFAULT "$defaultValue"',
        if (!nullable) 'NOT NULL', // implicit false when primary key
      ].join(' ');
}

/// Base class for all Model.
abstract class Model {
  /// table in database of this Model.
  Table get table {
    _table ??= tableOf(runtimeType);
    return _table!;
  }

  Table? _table;

  /// Return current value of this field or [defaultValue]
  dynamic valueOf(Field f) =>
      reflect(this).getField(f.symbol).reflectee ?? f.defaultValue;

  ///  INSERT INTO `article`(id, name) VALUES (1, 'Led Zeppelin');
  String get insertSql {
    //
    final names = table.fields.map((f) => f.name).toList().join(', ');

    //
    final values = table.fields
        .map((f) => valueOf(f))
        .map((v) => table.dialect.sql(v))
        .toList()
        .join(', ');

    return [
      'INSERT INTO',
      '`${table.name}`($names)',
      'VALUES',
      '($values)',
    ].join(' ');
  }
}

/// Query Helper.
class Query<T extends Model> extends IterableMixin<T> implements Iterable<T> {
  String? filter;
  int? limit;

  Query({
    this.filter,
    this.limit,
  });

  String get sql {
    final atable = tableOf(T);
    final names = atable!.fields
        .map((f) => '${f.name} as ${f.symbol.name}')
        .toList()
        .join(', ');

    return [
      'SELECT $names FROM `${atable.name}`',
      if (filter != null) 'WHERE $filter',
      if (limit != null) 'LIMIT $limit',
    ].join(' ');
  }

  /// Cache result of current query.
  ResultSet? _resultSet;

  ResultSet prepare() {
    final atable = tableOf(T);
    final session = db.session(atable!.bind!);
    if (session == null) {
      throw Exception('No session bind for "${atable.bind}"');
    }

    return waitFor<ResultSet>(session.query(sql));
  }

  @override
  Iterator<T> get iterator {
    _resultSet ??= prepare();
    return _ModelIterator<T>(_resultSet!);
  }
}

class _ModelIterator<T extends Model> extends Iterator<T> {
  final ResultSet result;
  int index = -1;
  Iterator<Row>? iterator;

  _ModelIterator(this.result);

  @override
  T get current {
    iterator ??= result.iterator;
    final row = iterator!.current;

    final classMirror = reflectClass(T);

    final args = <Symbol, dynamic>{};
    for (int i = 0; i < result.columnNames.length; ++i) {
      args[Symbol(result.columnNames[i])] = row.columnAt(i);
    }

    final im = classMirror.newInstance(Symbol(''), [], args);
    return im.reflectee as T;
  }

  @override
  bool moveNext() {
    iterator ??= result.iterator;
    return iterator!.moveNext();
  }
}

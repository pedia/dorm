import 'package:dorm/annotation.dart';
import 'package:dorm/src/dialect.dart';

/// Field with alias name
class Field extends field {
  //
  final Symbol symbol;
  final Type type;
  final Object? impl;

  Field.from(
    field base, {
    required this.symbol,
    required this.type,
    this.impl,
  }) : super(
          name: base.name ?? symbol.name,
          primaryKey: base.primaryKey,
          autoIncrement: base.autoIncrement,
          nullable: base.nullable,
          defaultValue: base.defaultValue,
          unique: base.unique,
          index: base.index,
          maxLength: base.maxLength,
          comment: base.comment,
        );

  /// Name of this field in database.
  /// Rewrite name? to name!
  @override
  String get name => super.name!;

  /// Type name in Dart, like: 'int', 'String', 'double'
  String get typeName => 'TODO:';

  /// Create table sql part of this field.
  /// like:
  ///   a int PRIMARY KEY NOT NULL
  ///   b TEXT;
  ///   c varchar(100);
  String sqlClause([Dialect dialect = const Dialect()]) => [
        name, // field name
        dialect.typeNameOf(type),
        if (this.primaryKey) 'PRIMARY KEY',
        if (autoIncrement) 'AUTOINCREMENT',
        if (defaultValue != null) 'DEFAULT "$defaultValue"',
        if (!nullable) 'NOT NULL', // implicit false when primary key
      ].join(' ');
}

/// Help extension extract [String] typed [name].
/// Symbol("id") => id
extension _SymbolWithName on Symbol {
  String get name => toString().split('"')[1];
}

/// Real [Table] in database.
class Table extends table {
  final List<Field> fields;

  Table.from(
    table base, {
    required this.fields,
  }) : super(
          base.name,
          bind: base.bind,
          engine: base.engine,
          autoIncrement: base.autoIncrement,
          charset: base.charset,
          collate: base.collate,
        );

  ///
  /// CREATE TABLE article (id INT PRIMARY KEY, name varchar(100) NOT NULL);
  String get createSql {
    String fs = fields.map((f) => f.sqlClause(dialect)).toList().join(', ');
    return 'CREATE TABLE IF NOT EXISTS `$name` ($fs)';
  }

  Dialect get dialect {
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

part of dorm;

///
/// Symbol("id") => id
extension SymbolWithName on Symbol {
  String get name => toString().split('"')[1];
}

///
class Table extends table {
  List<Field> fields;

  Table({
    required table base,
    required this.fields,
  }) : super(base.name, base.bind);

  /// CREATE TABLE article (id INT PRIMARY KEY, name varchar(100) NOT NULL);
  String get createSql {
    String fs = fields.map((f) => f.sqlStringOf(dialect)).toList().join(', ');
    return 'CREATE TABLE IF NOT EXISTS `$name` ($fs)';
  }

  /// Cached dialect.
  Dialect? _dialect;

  Dialect get dialect {
    if (_dialect == null && bind != null) {
      _dialect = db.session(bind!)?.dialect;
    }

    // default Dialect
    _dialect ??= Dialect();
    return _dialect!;
  }
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
          nullable: base.nullable,
          defaultValue: base.defaultValue,
          unique: base.unique,
          index: base.index,
        );

  /// Rewrite name? to name!
  @override
  String get name => super.name!;

  /// Like 'int', 'String'
  String get typeName => type.simpleName.name;

  /// Field part of create table sql.
  /// like:
  ///   a int PRIMARY KEY NOT NULL
  ///   b TEXT;
  ///   c varchar(100);
  String sqlStringOf([Dialect dialect = const Dialect()]) => [
        name, // field name
        dialect.typeNameOf(type.reflectedType),
        if (this.primaryKey) 'PRIMARY KEY',
        if (!nullable) 'NOT NULL',
      ].join(' ');
}

class StringField extends Field {
  StringField({
    required Symbol symbol,
    required ClassMirror type, // remove?
    required field base,
  }) : super(symbol: symbol, type: type, base: base);
}

class IntField extends Field {
  IntField({
    required Symbol symbol,
    required ClassMirror type, // remove?
    required field base,
  }) : super(symbol: symbol, type: type, base: base);
}

/// fieldsOf(Model)
List<Field> fieldsOf(Type type) => reflectClass(type)
    .declarations
    .entries
    .map((e) => NamedVariable(e.key, e.value))
    .map((nv) => nv.extract())
    .where((nv) => nv != null)
    .toList()
    .cast<Field>();

/// tableOf(Model)
Table? tableOf(Type type) {
  final rc = reflectClass(type);

  if (rc.metadata.first.hasReflectee) {
    return Table(
      base: rc.metadata.first.reflectee,
      fields: fieldsOf(type),
    );
  }
}

/// Help extract [type], symbol(instance name) from [declarations].
/// Move into model_impl.dart
class NamedVariable {
  final Symbol symbol;
  final DeclarationMirror mirror;

  const NamedVariable(this.symbol, this.mirror);

  Field? extract() {
    if (mirror is VariableMirror) {
      final vm = mirror as VariableMirror;
      if (vm.metadata.isNotEmpty &&
          vm.metadata.first.hasReflectee && // ?
          !vm.isStatic &&
          !vm.isConst &&
          !vm.isExtensionMember) {
        return Field(
          symbol: symbol,
          type: vm.type as ClassMirror,
          base: vm.metadata.first.reflectee,
        );
      }
    }
  }
}

abstract class Model {
  Table get table =>
      Table(base: tableOf(runtimeType)!, fields: fieldsOf(runtimeType));

  /// Return instance value.
  dynamic valueOf(Field f, [bool ensureDefault = false]) {
    //
    return reflect(this).getField(f.symbol).reflectee;
  }

  // INSERT INTO `article`(id, name) VALUES (1, 'heaven under earth');
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

  static BaseQuery<T> query<T extends Model>({
    String? filter,
    int? limit,
    Type? joinable,
  }) =>
      BaseQuery<T>(filter: filter, limit: limit);
}

///
class BaseQuery<T extends Model> extends IterableMixin<T>
    implements Iterable<T> {
  String? filter;
  int? limitCount;

  BaseQuery({
    this.filter,
    int? limit,
    // TODO: join, select
  }) : limitCount = limit;

  String get sql {
    return 'SELECT * FROM article';
  }

  ResultSet? _resultSet;

  ResultSet prepare() {
    final atable = tableOf(T);
    final session = db.session(atable!.bind!);
    if (session == null) {
      throw Exception('No session bind for "${atable.bind}"');
    }

    return session.query(sql);
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

  _ModelIterator(this.result);

  @override
  T get current {
    final row = result.rows[index];

    final classMirror = reflectClass(T);

    final args = <Symbol, dynamic>{};
    for (int i = 0; i < result.columnNames.length; ++i) {
      args[Symbol(result.columnNames[i])] = row[i];
    }

    final im = classMirror.newInstance(Symbol(''), [], args);
    return im.reflectee as T;
  }

  @override
  bool moveNext() {
    index++;
    return index < result.rows.length;
  }
}

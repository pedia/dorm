import 'dart:cli';

import 'package:dorm/annotation.dart';
import 'package:dorm/src/dialect.dart';
import 'package:dorm/src/result_set.dart';
import 'package:dorm/src/database.dart';
import 'package:dorm/src/table.dart';

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

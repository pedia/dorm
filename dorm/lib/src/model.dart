// import 'dart:cli';
import 'package:reflection_factory/reflection_factory.dart';

import 'package:dorm/annotation.dart' as dorm;
import 'package:dorm/src/dialect.dart';
import 'package:dorm/src/result_set.dart';
import 'package:dorm/src/database.dart';
import 'package:dorm/src/table.dart';

/// Base class for all Model.
class Model<T extends ClassReflection> {
  final T t;

  Model(this.t);

  Table? _table;

  Table? get table {
    if (_table == null) {
      for (final tab in t.classAnnotations) {
        if (tab is dorm.table) {
          final fields = <Field>[];

          for (final f in t.allFields()) {
            if (f.annotations.isNotEmpty && f.annotations.first is dorm.field) {
              fields.add(Field.from(
                f.annotations.first as dorm.field,
                symbol: Symbol(f.name),
                type: f.type.type,
                impl: f,
              ));
            }
          }
          _table = Table.from(tab, fields: fields);
        }
      }
    }
    return _table;
  }

  /// Return current value of this field or [defaultValue]
  dynamic valueOf(Field f) {
    // throw exception better?
    if (t.object == null) return null;

    return (f.impl as FieldReflection).get();
  }

  ///  INSERT INTO `article`(id, name) VALUES (1, 'Led Zeppelin');
  String get insertSql {
    //
    final names = table!.fields.map((f) => f.name).toList().join(', ');

    //
    final values = table!.fields
        .map((f) => valueOf(f))
        .map((v) => table!.dialect.sql(v))
        .toList()
        .join(', ');

    return [
      'INSERT INTO',
      '`${table!.name}`($names)',
      'VALUES',
      '($values)',
    ].join(' ');
  }
}

library dorm.annotation;

/// The annotation `@table('name')` marks a Table for Model.
/// ignore: camel_case_types
class table {
  const table(
    this.name, {
    this.bind,
    this.engine,
    this.autoIncrement,
    this.charset,
    this.collate,
  });

  final String name;

  final String? bind;

  final String? engine;
  final int? autoIncrement;
  final String? charset;
  final String? collate;
}

/// The annotation `@field('name')` marks a Field for Model.
/// ignore: camel_case_types
class field {
  const field({
    this.name,
    this.primaryKey = false,
    this.autoIncrement = false,
    this.nullable = false,
    this.defaultValue,
    this.enums,
    this.unique = false,
    this.maxLength,
    this.comment,
    this.index = false,
    this.foreignKey,
  });

  /// Field name in table
  final String? name;

  final bool primaryKey;
  final bool autoIncrement;
  final bool nullable;
  final dynamic defaultValue;
  final List<Object>? enums;
  final bool unique;
  final int? maxLength;
  final String? comment;

  /// KEY `tid` (`tid`),
  final bool index;

  /// pdid = Column(Integer, ForeignKey('dept.did'), nullable=True)
  /// parent = relationship('Dept', remote_side=[did])
  /// KEY `tid` (`tid`),
  /// CONSTRAINT `bullet_ibfk_1` FOREIGN KEY (`tid`) REFERENCES `trade` (`tid`)
  final String? foreignKey;
}

/// Used to annotate a property of a class is not [Field].
const _NotField notfield = _NotField();

class _NotField {
  const _NotField();
}

/// Shortly annotate primary key [Field], not very usefull.
const primaryKey = field(primaryKey: true, autoIncrement: true);

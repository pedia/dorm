part of dorm;

/// The annotation `@table('name')` marks a Table for Model.
/// ignore: camel_case_types
class table {
  const table(this.name, [this.bind]);

  final String name;

  final String? bind;

  /// TODO: ENGINE, AUTO_INCREMENT, DEFAULT, CHARSET, COLLATE
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
    this.doc,
    this.index = false,
    this.foreignKey,
  });

  /// Field name. null value mean same as instance name.
  final String? name;

  final bool primaryKey;
  final bool autoIncrement;
  final bool nullable;
  final dynamic defaultValue;
  final List<String>? enums;
  final bool unique;
  final int? maxLength;
  final String? doc;

  /// KEY `tid` (`tid`),
  final bool index;

  /// pdid = Column(Integer, ForeignKey('dept.did'), nullable=True)
  /// parent = relationship('Dept', remote_side=[did])
  /// KEY `tid` (`tid`),
  /// CONSTRAINT `bullet_ibfk_1` FOREIGN KEY (`tid`) REFERENCES `trade` (`tid`)
  final String? foreignKey;
}

/// Shortly, not very usefull.
const primaryKey = field(primaryKey: true, autoIncrement: true);

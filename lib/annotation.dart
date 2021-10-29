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
    this.nullable = false,
    this.defaultValue,
    this.unique = false,
    this.index = false,
    this.foreignKey,
  });

  /// Field name. Optional value for field name and instance name are same.
  final String? name;

  final bool primaryKey; // AUTO_INCREMENT?
  final bool nullable;
  final dynamic defaultValue;
  final bool unique;

  /// KEY `tid` (`tid`),
  final bool index;

  /// pdid = Column(Integer, ForeignKey('dept.did'), nullable=True)
  /// parent = relationship('Dept', remote_side=[did])
  /// KEY `tid` (`tid`),
  /// CONSTRAINT `bullet_ibfk_1` FOREIGN KEY (`tid`) REFERENCES `trade` (`tid`)
  final String? foreignKey;
}

/// Shortly, not very usefull.
const primaryKey = field(primaryKey: true);

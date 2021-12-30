///
class Dialect {
  const Dialect();

  String typeNameOf(Type type) {
    switch (type) {
      case int:
        return 'INTEGER';
      case String:
        return 'TEXT';
      case DateTime:
      case Duration:
        return 'DATETIME';
      case double:
        return 'DOUBLE';
    }
    return 'TODO: $type';
  }

  /// Nonreserved keywords are permitted as identifiers without quoting.
  /// Reserved words are permitted as identifiers if you quote them
  /// as `val`.
  String quote(String val) => '`$val`';

  // https://dev.mysql.com/doc/refman/5.7/en/string-literals.html
  // % _ ' " to
  String escape(String val) {
    return val;
  }

  /// Convert to string of sql.
  String sql(dynamic val) {
    if (val == null) {
      return 'NULL';
    } else if (val is num) {
      return val.toString();
    } else if (val is String) {
      return '"${escape(val)}"';
    }

    return val;
  }

  // TODO: like '%abc', '%abc%'
  String like(dynamic val) {
    return '%${escape(val)}%';
  }
}

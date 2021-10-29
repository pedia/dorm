part of dorm;

///
class Dialect {
  const Dialect();

  String typeNameOf(Type type) {
    switch (type) {
      case int:
        return 'INTEGER';
      case String:
        return 'TEXT';
    }
    return 'TODO: $type';
  }

  // TODO: % _ ' "
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
    return '%$escape(val)%';
  }
}

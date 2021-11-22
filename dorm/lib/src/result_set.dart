part of dorm;

/// Base class for result sets that are either an in-memory ([ResultSet]) or
/// a lazy iterator ([IteratingCursor]).
@sealed
abstract class Cursor {
  /// The column names of this query, as returned by `sqlite3`.
  final List<String> columnNames;

  // a result set can have multiple columns with the same name, but that's rare
  // and users usually use a name as index. So we cache that for O(1) lookups
  final Map<String, int> _calculatedIndexes;

  Cursor(this.columnNames)
      : _calculatedIndexes = {
          for (var column in columnNames)
            column: columnNames.lastIndexOf(column),
        };
}

/// Stores the full result of a select statement.
abstract class ResultSet extends Cursor
    with IterableMixin<Row>
    implements Iterable<Row> {
  ResultSet(List<String> columnNames) : super(columnNames);

  @override
  Iterator<Row> get iterator;
}

/// A single row in the result of a select statement.
///
/// This class implements the [Map] interface, which can be used to look up the
/// value of a column by its name.
/// The [columnAt] method may be used to obtain the value of a column by its
/// index.
abstract class Row
    with UnmodifiableMapMixin<String, dynamic>, MapMixin<String, dynamic>
    implements Map<String, dynamic> {
  final Cursor cursor;
  Row(this.cursor);

  /// Returns the value stored in the [i]-th column in this row (zero-indexed).
  dynamic columnAt(int i);

  @override
  dynamic operator [](Object? key) {
    if (key is! String) return null;

    final index = cursor._calculatedIndexes[key];
    if (index == null) return null;

    return columnAt(index);
  }

  @override
  Iterable<String> get keys => cursor.columnNames;
}

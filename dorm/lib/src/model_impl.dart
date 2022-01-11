// import 'dart:cli';

import 'package:dorm/annotation.dart';
import 'package:dorm/src/dialect.dart';
import 'package:dorm/src/result_set.dart';
import 'package:dorm/src/database.dart';

/// Help extension extract [String] typed [name].
/// Symbol("id") => id
extension _SymbolWithName on Symbol {
  String get name => toString().split('"')[1];
}

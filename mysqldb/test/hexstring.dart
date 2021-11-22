import 'dart:typed_data';
import 'package:mysqldb/src/stream.dart';

Uint8List bytesFromHexed(String s) {
  final out = OutputStream();
  for (int i = 0; i < s.length; ++i) {
    var char = s[i];
    if (char == ' ' || char == '\n') continue;

    char += s[i++ + 1];

    int v = int.parse(char, radix: 16);
    out.write8(v);
  }
  return out.finished();
}

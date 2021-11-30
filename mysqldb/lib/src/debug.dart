import 'dart:typed_data';

bool isAscii(int c) => c >= 0x20 && c < 0x7f;

/// 0x0000:  4500 0047 0000 4000 4006 81fe 0af9 347a  E..G..@.@.....4z
String hexed(Uint8List data) {
  final lines = [];

  final p1 = [];
  final p2 = [];

  for (int i = 0; i < data.length; ++i) {
    int c = data[i];
    p1.add(c.toRadixString(16).padLeft(2, '0'));
    if (i.isOdd) {
      p1.add(' ');
    }
    if (isAscii(c)) {
      p2.add(String.fromCharCode(c));
    } else {
      p2.add('.');
    }

    if (p2.length == 16) {
      String s = p1.join('');
      s += '  ';
      s += p2.join('');
      lines.add(s);

      p1.clear();
      p1.add('    ');
      p2.clear();
    }
  }

  if (p2.isNotEmpty) {
    String s = p1.join('');
    s = s.padRight(44, ' ');
    s += '  ';
    s += p2.join('');
    lines.add(s);
  }

  return lines.join('\n');
}

Uint8List bytesFromHexed(String s) {
  final out = <int>[];
  for (int i = 0; i < s.length; ++i) {
    var char = s[i];
    if (char == ' ' || char == '\n') continue;

    char += s[i++ + 1];

    int v = int.parse(char, radix: 16);
    out.add(v);
  }
  return Uint8List.fromList(out);
}

///
bool verbose = true;

///
bool debug = true;

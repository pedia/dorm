part of mysql.impl;

///
/// caching_sha2_password
class CachingSha2Password {
  final cache = <String, Uint8List>{};

  void add(String name, String source) {
    if (source.isEmpty) {
      // empty password
      cache[name] = Uint8List.fromList([]);
    } else {
      // TOOD: sha256
      cache[name] =
          Uint8List.fromList(NativePassword.digestTwice(source).bytes);
    }
  }

  void addBytes(String name, Uint8List bytes) => cache[name] = bytes;

  Uint8List? find(String name) => cache[name];

  void store(String file) {
    final contents = cache.entries
        .map((e) => '${e.key}: ${hex.encode(e.value)}')
        .toList()
        .join('\n');

    File(file).writeAsStringSync(contents);
  }

  static Future<CachingSha2Password> loadAsync(String file) {
    final completer = Completer<CachingSha2Password>();

    File(file).readAsString().then((content) {
      final res = CachingSha2Password();

      for (var line in content.split('\n')) {
        final arr = line.split(':');
        res.addBytes(
          arr[0].trim(),
          Uint8List.fromList(hex.decode(arr[1].trim())),
        );
      }
      completer.complete(res);
    });

    return completer.future;
  }

  static CachingSha2Password load(String file) {
    final res = CachingSha2Password();

    for (var line in File(file).readAsLinesSync()) {
      final arr = line.split(':');
      res.addBytes(
        arr[0].trim(),
        Uint8List.fromList(hex.decode(arr[1].trim())),
      );
    }

    return res;
  }
}

part of mysql.impl;

class Salt {
  final Random random;
  Salt([int? seed]) : random = seed == null ? Random.secure() : Random(seed);

  static const int length = 20;

  /// Generate a random string using ASCII characters but avoid seperator character.
  /// Stdlib rand and srand are used to produce pseudo random numbers between
  /// with about 7 bit worth of entropty between 1-127.
  Uint8List generate() {
    final out = OutputStream();
    for (int i = 0; i < length; ++i) {
      int v = random.nextInt(0xff & 0x7f);
      // 0x36 '$'
      if (v == 0 || v == 0x36) {
        v += 1;
      }
      out.write8(v);
    }
    return out.finished();
  }
}

abstract class Password {
  const Password();
  String get name => throw UnimplementedError();

  int get digestLength;

  /// Scramble generation, used in client.
  Uint8List scramble(Uint8List rnd, String source);

  ///
  /// text ^ key = cipher
  /// cipher ^ key = text
  /// make()
  ///
  ///   known = digestTwice(text)
  ///
  bool validate(Uint8List rnd, List<int> scramble, List<int> known);
}

///
class Sha256Password extends Password {
  @override
  String get name => 'caching_sha2_password';

  @override
  int get digestLength => 32;

  @override
  Uint8List scramble(Uint8List rnd, String source) {
    // SHA2(src) => digest_stage1
    final digestStage1 = sha256.convert(utf8.encode(source));

    // SHA2(digest_stage1) => digest_stage2
    final digestStage2 = sha256.convert(digestStage1.bytes);

    // SHA2(digest_stage2, m_rnd) => scramble_stage1
    final scrambleStage1 = digest(digestStage2.bytes, rnd);

    // XOR(digest_stage1, scramble_stage1) => scramble
    final res = Uint8List(digestLength);
    for (int i = 0; i < digestLength; ++i) {
      res[i] = digestStage1.bytes[i] ^ scrambleStage1.bytes[i];
    }
    return res;
  }

  @override
  bool validate(Uint8List rnd, List<int> scramble, List<int> known) {
    // SHA2(known, m_rnd) => scramble_stage1
    final scrambleStage1 = digest(known, rnd);

    // XOR(scramble, scramble_stage1) => digest_stage1
    final digestStage1 = Uint8List(digestLength);
    for (int i = 0; i < digestLength; ++i) {
      digestStage1[i] = scramble[i] ^ scrambleStage1.bytes[i];
    }

    // SHA2(digest_stage1) => digest_stage2
    final digestStage2 = sha256.convert(digestStage1);

    // m_known == digest_stage2
    for (int i = 0; i < known.length; ++i) {
      if (known[i] != digestStage2.bytes[i]) {
        return false;
      }
    }
    return true;
  }

  static Digest digest(List<int> a, List<int> b) {
    final output = AccumulatorSink<Digest>();

    final input = sha256.startChunkedConversion(output);
    input.add(a);
    input.add(b);
    input.close();
    return output.events.single;
  }

  static Digest digestTwice(String source) {
    final d1 = sha256.convert(utf8.encode(source));
    return sha256.convert(d1.bytes);
  }
}

/// sql/auth/password.cc
class NativePassword extends Password {
  const NativePassword();
  @override
  String get name => 'mysql_native_password';

  @override
  int get digestLength => 20;

  @override
  Uint8List scramble(Uint8List rnd, String source) {
    // hash_stage1=sha1("password")
    final digestStage1 = sha1.convert(utf8.encode(source));

    // hash_stage2=sha1(hash_stage1)
    final digestStage2 = sha1.convert(digestStage1.bytes);

    // reply=xor(hash_stage1, sha1(public_seed,hash_stage2)
    final scrambleStage1 = digest(rnd, digestStage2.bytes);

    final res = Uint8List(digestLength);
    for (int i = 0; i < digestLength; ++i) {
      res[i] = digestStage1.bytes[i] ^ scrambleStage1.bytes[i];
    }
    return res;
  }

  @override
  bool validate(Uint8List rnd, List<int> scramble, List<int> known) {
    // hash_stage1=xor(reply, sha1(public_seed,hash_stage2))
    final scrambleStage1 = digest(rnd, known);

    // XOR(scramble, scramble_stage1) => digest_stage1
    final digestStage1 = Uint8List(digestLength);
    for (int i = 0; i < digestLength; ++i) {
      digestStage1[i] = scramble[i] ^ scrambleStage1.bytes[i];
    }

    // candidate_hash2=sha1(hash_stage1)
    final digestStage2 = sha1.convert(digestStage1);

    // m_known == digest_stage2
    for (int i = 0; i < known.length; ++i) {
      if (known[i] != digestStage2.bytes[i]) {
        return false;
      }
    }
    return true;
  }

  static Digest digest(List<int> a, List<int> b) {
    final output = AccumulatorSink<Digest>();

    final input = sha1.startChunkedConversion(output);
    input.add(a);
    input.add(b);
    input.close();
    return output.events.single;
  }

  static Digest digestTwice(String source) {
    final d1 = sha1.convert(utf8.encode(source));
    return sha1.convert(d1.bytes);
  }
}

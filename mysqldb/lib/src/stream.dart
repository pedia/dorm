import 'dart:typed_data';
import 'dart:convert' show utf8;

/// Interface for input streams used to extract some types from
/// a sequence of bytes.
class InputStream {
  final ByteData buf;
  final int byteLength;
  int offset = 0;

  InputStream(this.buf, this.byteLength);

  factory InputStream.from(Uint8List data) =>
      InputStream(ByteData.view(data.buffer), data.lengthInBytes);

  factory InputStream.fromList(List<int> data) =>
      InputStream.from(Uint8List.fromList(data));

  int get byteLeft => byteLength - offset;

  Uint8List get left =>
      Uint8List.view(ByteData.sublistView(buf, offset).buffer);

  void skip(int i) {
    assert(offset + i <= byteLength);
    offset += i;
  }

  int peek() => buf.getUint8(offset);

  Uint8List peeks(int sz) {
    final blob = ByteData(sz);
    blob.buffer.asUint8List(0).setRange(0, sz, buf.buffer.asUint8List(offset));
    return blob.buffer.asUint8List();
  }

  int readu8() {
    assert(offset + 1 <= byteLength);
    return buf.getUint8(offset++);
  }

  int readi8() {
    assert(offset + 1 <= byteLength);
    return buf.getInt8(offset++);
  }

  int readu16([Endian endian = Endian.little]) {
    assert(offset + Uint16List.bytesPerElement <= byteLength);
    final res = buf.getUint16(offset, endian);
    offset += Uint16List.bytesPerElement;
    return res;
  }

  int readu32([Endian endian = Endian.little]) {
    assert(offset + Uint32List.bytesPerElement <= byteLength);
    final res = buf.getUint32(offset, endian);
    offset += Uint32List.bytesPerElement;
    return res;
  }

  int readu64([Endian endian = Endian.little]) {
    assert(offset + Uint64List.bytesPerElement <= byteLength);
    final res = buf.getUint64(offset, endian);
    offset += Uint64List.bytesPerElement;
    return res;
  }

  double readFloat([Endian endian = Endian.little]) {
    assert(offset + Float32List.bytesPerElement <= byteLength);
    final res = buf.getFloat32(offset, endian);
    offset += Float32List.bytesPerElement;
    return res;
  }

  double readDouble([Endian endian = Endian.little]) {
    assert(offset + Float64List.bytesPerElement <= byteLength);
    final res = buf.getFloat64(offset, endian);
    offset += Float64List.bytesPerElement;
    return res;
  }

  Uint8List read(int sz) {
    assert(offset + sz <= byteLength);

    final blob = ByteData(sz);
    blob.buffer.asUint8List(0).setRange(0, sz, buf.buffer.asUint8List(offset));
    offset += sz;
    return blob.buffer.asUint8List();
  }

  /// string<NUL>	NulTerminatedString
  String readCString() {
    int end = offset;
    while (buf.getInt8(end) != 0) {
      if (end++ == byteLength) {
        throw Exception('Not found \\0x00 for end of C string');
      }
    }

    final res = String.fromCharCodes(read(end - offset));
    final zero = readu8();
    assert(zero == 0);
    return res;
  }

  /// int<lenenc>	LengthEncodedInteger
  int readLength() {
    final byte = readu8();
    if (byte < 0xfb) {
      return byte;
    } else if (byte == 0xfb) {
      return 0;
    } else if (byte == 0xfc) {
      return readu16();
    } else if (byte == 0xfd) {
      final b1 = readu8();
      final b2 = readu8();
      final b3 = readu8();
      return (b3 << 16) | (b2 << 8) | b1;
    } else {
      assert(byte == 0xfe);
      return readu64();
    }
  }

  int read3ByteLength() {
    Uint8List b3 = read(3);
    return b3[0] + (b3[1] << 8) + (b3[2] << 16);
  }

  static int lengthSize(int num) {
    if (num < 0xfc) return 1;
    if (num < 65536) return 3;
    if (num < 16777216) return 4;
    return 9;
  }

  /// string<EOF> Protocol::RestOfPacketString
  String readEofString() => String.fromCharCodes(read(byteLeft));

  /// string<lenenc>	LengthEncodedString
  String readLengthEncodedString() {
    final sz = readLength();
    return String.fromCharCodes(Uint8List.fromList(read(sz)));
  }
}

/// Interface for output streams, used to create a sequence of bytes from types.
class OutputStream {
  ByteData? _data;

  int get lengthInBytes => _data?.lengthInBytes ?? 0;

  void write8(int v) => commit(1).setUint8(0, v);
  void write16(int v, [Endian endian = Endian.little]) =>
      commit(2).setUint16(0, v, endian);
  void write32(int v, [Endian endian = Endian.little]) =>
      commit(4).setUint32(0, v, endian);
  void write64(int v, [Endian endian = Endian.little]) =>
      commit(8).setUint64(0, v, endian);
  void writeFloat(double v, [Endian endian = Endian.little]) =>
      commit(4).setFloat32(0, v, endian);
  void writeDouble(double v, [Endian endian = Endian.little]) =>
      commit(8).setFloat64(0, v, endian);

  void write(Uint8List v) {
    if (v.isNotEmpty) {
      final b = commit(v.lengthInBytes);
      assert(b != _data);
      _copy(b, ByteData.view(v.buffer));
    }
  }

  void writeString(String v) => write(Uint8List.fromList(utf8.encode(v)));

  /// Enhance memory, return added part.
  ByteData commit(int size) {
    assert(size > 0);

    // Create new memory and copy old data into it
    final nd = ByteData(lengthInBytes + size);
    if (_data != null) {
      _copy(nd, _data!);
    }

    // Return added memory
    final res = nd.buffer.asByteData(lengthInBytes);

    // Set
    _data = nd;

    assert(res.lengthInBytes == size);
    return res;
  }

  static void _copy(ByteData dst, ByteData src) {
    assert(dst.lengthInBytes >= src.lengthInBytes);
    // for (var i = 0; i < src.lengthInBytes; i++) {
    //   dst.setUint8(i, src.getUint8(i));
    // }
    dst.buffer
        .asInt8List(dst.offsetInBytes)
        .setRange(0, src.lengthInBytes, src.buffer.asInt8List());
  }

  Uint8List finished() {
    if (_data == null) {
      return Uint8List(0);
    }
    return _data!.buffer.asUint8List();
  }

  /// string<NUL>	NulTerminatedString
  void writeCString(String v) {
    write(Uint8List.fromList(v.codeUnits));
    write8(0);
  }

  /// int<lenenc>	LengthEncodedInteger
  void writeLength(int v) {
    if (v < 0xfb) {
      write8(v);
      return;
    }
    if (v < 65536) {
      write8(0xfc);
      write16(v);
      return;
    }
    if (v < 16777216) {
      write8(0xfd);
      write8(v);
      write8((v & 0xff00) >> 8);
      write8((v & 0xff0000) >> 16);
      return;
    } else {
      write8(0xfe);
      write64(v);
    }
  }

  void writeFieldLength(int v) {
    if (v == 0) {
      write8(0xfb);
      return;
    }
    writeLength(v);
  }

  static int lengthSize(int num) {
    if (num < 0xfc) return 1;
    if (num < 65536) return 3;
    if (num < 16777216) return 4;
    return 9;
  }

  /// string<EOF> Protocol::RestOfPacketString
  void writeEofString(String v) => writeString(v);

  /// string<lenenc>	LengthEncodedString
  void writeLengthEncodedString(String v) {
    writeLength(v.length);
    write(Uint8List.fromList(v.codeUnits));
  }

  void write3ByteLength(int v) {
    final bytes = Uint8List.fromList([
      v & 0xff,
      (v & 0xff00) >> 8,
      (v & 0xff0000) >> 16,
    ]);
    write(bytes);
  }

  void writeOptions(Map<String, String> map) {
    final sub = OutputStream();
    map.forEach((key, value) {
      sub.writeLengthEncodedString(key);
      sub.writeLengthEncodedString(value);
    });
    writeLength(sub.finished().length);
    write(sub.finished());
  }
}

/// Merge two buffer
Uint8List merge(Uint8List a, Uint8List b) {
  final c = Uint8List(a.length + b.length);
  c.setRange(0, a.length, a);
  c.setRange(a.length, a.length + b.length, b);
  return c;
}

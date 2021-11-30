part of mysql.impl;

///
class Packet {
  final int? packetId;
  final Uint8List? body;

  Packet([this.packetId, this.body]);

  factory Packet.build(int packetId, Packet inner) =>
      Packet(packetId, inner.encode());

  // Should cache InputStream
  InputStream? _inputStream;
  InputStream get inputStream {
    _inputStream ??= InputStream.from(body!);
    return _inputStream!;
  }

  ///
  void sendTo(IOSink sink) {
    final buf = encode();

    if (debug) print('c : ${hexed(buf)}');
    sink.add(buf);

    /// fixed: nc -z cause crash
    sink.flush().then((_) => null);
  }

  /// Default of max_allowed_packet defined by the MySQL Server (2^30)
  static const int kMaxPacketSize = 0x40000000; // 1073741824

  ///
  static const int kmaxPacketSize56 = 0x1000000; // 16777216

  static const int ok = 0x00;
  static const int eof = 0xfe;
  static const int error = 0xff;

  Uint8List encode() {
    if (body == null) {
      throw UnimplementedError('Not implement $runtimeType.encode');
    }

    final out = OutputStream();
    Uint8List bytes = body!;
    // TODO: split
    out.write3ByteLength(bytes.length);
    out.write8(packetId!);
    out.write(bytes);

    return out.finished();
  }

  factory Packet.parse(InputStream input, [Capability? capability]) {
    capability ??= Capability.kBasicCapabilities;
    int bodyLength = input.read3ByteLength();
    int packetId = input.readu8();

    //
    Uint8List body = input.read(bodyLength);

    // OK: header = 0 and length of packet > 7
    if (body[0] == ok && body.length > 7) {
    } else if (body[0] == error) {
      return ErrorPacket.parse(InputStream.from(body), capability);
    }
    // EOF: header = 0xfe and length of packet < 9
    else if (body[0] == eof && body.length < 9) {
      return EofPacket.parse(InputStream.from(body), capability);
    }

    // When the server receives a packet with 0xffffff length,
    // it will continue to read the next packet.
    while (bodyLength == 0xffffff) {
      bodyLength = input.read3ByteLength();
      final c2 = input.readu8();
      assert(packetId == c2);
      final buf = input.read(bodyLength);

      body = merge(body, buf);
    }

    return Packet(packetId, body);
  }
}

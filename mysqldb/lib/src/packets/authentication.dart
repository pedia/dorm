part of mysql.impl;

///
class ClientAuthentication extends Packet {
  final Handshake handshake;
  final String user;
  final String password;
  final String? db;
  final Map<String, String> options;
  final Capability clientCapability;

  ClientAuthentication(
    this.handshake, {
    required this.user,
    required this.password,
    this.db,
    required this.options,
    required this.clientCapability,
  });

  /// client.cc prep_client_reply_packet
  @override
  Uint8List encode() {
    // Normally ignoreSpace come from command args?
    Capability clientFlag = clientCapability;

    // unix socket: multiStatements?
    // client.cc cli_calculate_client_flag

    if (db != null) {
      clientFlag.set(Capability.connectWithDb);
    } else {
      clientFlag.unset(Capability.connectWithDb);
    }

    // Remove options that server doesn't support
    clientFlag = Capability(clientFlag.value &
        (~(Capability.compress |
                Capability.ssl |
                Capability.protocol41 |
                Capability.optionalResultsetMetadata) |
            handshake.serverCapability.value));

    // force no ssl
    // clientFlag.unset(Capability.secureConnection);

    final out = OutputStream();

    out.write32(clientFlag.value);
    out.write32(Packet.kmaxPacketSize56);
    out.write8(Charset.utf8);
    out.write(Uint8List(23));

    out.writeCString(user);

    final digest = encodePassword();

    if (clientFlag.has(Capability.secureConnection)) {
      out.write8(digest.length);
      out.write(digest);
    } else if (clientFlag.has(Capability.pluginAuthLenencClientData)) {
      out.write8(digest.length);
      out.write(digest);
    } else {
      out.write(digest);
    }

    if (clientFlag.has(Capability.connectWithDb)) {
      out.writeCString(db!);
    }

    if (clientFlag.has(Capability.pluginAuth)) {
      out.writeCString(handshake.authPlugin);
    }

    //
    if (clientFlag.has(Capability.connectAttrs)) {
      out.writeOptions(options);
    } else {
      out.writeLength(0);
    }

    return out.finished();
  }

  Uint8List encodePassword() {
    if (handshake.authPlugin == 'mysql_native_password') {
      return NativePassword().scramble(handshake.scramble, password);
    } else if (handshake.authPlugin == 'caching_sha2_password') {
      return Sha256Password().scramble(handshake.scramble, password);
    }
    throw Exception('Unknown Auth Plugin ${handshake.authPlugin}');
  }
}

class ServerAuthentication extends Packet {
  final Capability clientFlag;
  final int maxPacketSize;
  final int charset;
  final String user;
  final Uint8List scramble;
  final String? db;
  final String? authPlugin;
  final Map<String, String> options;

  ServerAuthentication({
    required this.clientFlag,
    required this.maxPacketSize,
    required this.charset,
    required this.user,
    required this.scramble,
    required this.db,
    required this.authPlugin,
    required this.options,
  });

  static ServerAuthentication parse(InputStream input) {
    final clientFlag = Capability(input.readu32());

    final maxPacketSize = input.readu32();
    final charset = input.readu8();
    input.skip(23);

    final user = input.readCString();

    late Uint8List scramble;

    if (clientFlag.has(Capability.secureConnection)) {
      final scrambleLength = input.readu8();
      scramble = input.read(scrambleLength);
    } else if (clientFlag.has(Capability.pluginAuthLenencClientData)) {
      final scrambleLength = input.readu8();
      scramble = input.read(scrambleLength);
    } else {
      scramble = Uint8List.fromList(input.readCString().codeUnits);
    }

    String? db;
    if (clientFlag.has(Capability.connectWithDb)) {
      db = input.readCString();
    }

    String? authPlugin;
    if (clientFlag.has(Capability.pluginAuth)) {
      authPlugin = input.readCString();
    }

    final options = <String, String>{};

    // Maybe serverCapability is not must
    if (clientFlag.has(Capability.connectAttrs)) {
      int count = input.readLength();
      final pair = [];
      while (count > 0) {
        final s = input.readLengthEncodedString();
        pair.add(s);
        count -= InputStream.lengthSize(s.length);
        count -= s.length;
      }

      assert(pair.length.isEven);
      for (int i = 0; i < pair.length; i += 2) {
        options[pair[i]] = pair[i + 1];
      }
    }
    assert(input.byteLeft == 0);

    return ServerAuthentication(
      clientFlag: clientFlag,
      maxPacketSize: maxPacketSize,
      charset: charset,
      user: user,
      scramble: scramble,
      db: db,
      authPlugin: authPlugin,
      options: options,
    );
  }
}

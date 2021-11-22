part of mysql.impl;

class Charset {
  static const big5 = 1;
  static const dec8 = 3;
  static const cp850 = 4;
  static const hp8 = 6;
  static const koi8r = 7;
  static const latin1 = 8;
  static const latin2 = 9;
  static const swe7 = 10;
  static const ascii = 11;
  static const ujis = 12;
  static const sjis = 13;
  static const hebrew = 16;
  static const tis620 = 18;
  static const euckr = 19;
  static const koi8u = 22;
  static const gb2312 = 24;
  static const greek = 25;
  static const cp1250 = 26;
  static const gbk = 28;
  static const latin5 = 30;
  static const armscii8 = 32;
  static const utf8 = 33;
  static const ucs2 = 35;
  static const cp866 = 36;
  static const keybcs2 = 37;
  static const macce = 38;
  static const macroman = 39;
  static const cp852 = 40;
  static const latin7 = 41;
  static const cp1251 = 51;
  static const utf16 = 54;
  static const utf16le = 56;
  static const cp1256 = 57;
  static const cp1257 = 59;
  static const utf32 = 60;
  static const binary = 63;
  static const geostd8 = 92;
  static const cp932 = 95;
  static const eucjpms = 97;
  static const gb18030 = 248;
  static const utf8mb4 = 255;
}

/// Capability flags passed in handshake packet.
class Capability extends Flag {
  Capability(int v) : super(v);

  static const longPassword = 0x01;
  static const foundRows = 0x02;
  static const longFlag = 0x04;
  static const connectWithDb = 0x08;

  static const noSchema = 0x10;
  static const compress = 0x20;
  static const odbc = 0x40;
  static const localFiles = 0x80;

  static const ignoreSpace = 0x100;

  /// Server: supports the 4.1 protocol, Client: uses the 4.1 protocol
  static const protocol41 = 0x200;
  static const interactive = 0x400;

  /// Server: supports SSL, Client: switch to SSL
  static const ssl = 0x800;

  static const sigPipe = 0x1000;
  static const transactions = 0x2000;

  /// deprecated in 8.0.3
  static const reserved1 = 0x4000;

  /// deprecated in 8.0.3, secureConnection
  static const secureConnection = 0x8000;

  static const multiStatements = 0x10000;
  static const multiResults = 0x20000;
  static const psMultiResults = 0x40000;
  static const pluginAuth = 0x80000;

  static const connectAttrs = 0x100000;
  static const pluginAuthLenencClientData = 0x200000;
  static const expiredPasswords = 0x400000;
  static const sessionTrack = 0x800000;

  static const deprecateEof = 0x1000000;

  /// \  docs for 5.7 don't
  static const optionalResultsetMetadata = 0x2000000;

  ///  > mention these
  static const sslVerifyServerCert = 0x4000000;
  static const rememberOptions = 0x8000000;

  /// other useful flags (our invention, mysql_com.h does not define them)
  static const allZeros = 0;
  static const int allValue = longPassword |
      foundRows |
      longFlag |
      connectWithDb |
      noSchema |
      compress |
      odbc |
      localFiles |
      ignoreSpace |
      protocol41 |
      interactive |
      ssl |
      sigPipe |
      transactions |
      reserved1 |
      secureConnection |
      multiStatements |
      multiResults |
      psMultiResults |
      pluginAuth |
      connectAttrs |
      pluginAuthLenencClientData |
      expiredPasswords |
      sessionTrack |
      deprecateEof |
      optionalResultsetMetadata |
      sslVerifyServerCert |
      rememberOptions;

  static Capability all = Capability(allValue);

  /// 5.7 MySql Server
  static Capability kServerDefault = Capability(longPassword |
      foundRows |
      longFlag |
      connectWithDb |
      noSchema |
      compress |
      odbc |
      localFiles |
      ignoreSpace |
      protocol41 |
      interactive |
      ssl |
      sigPipe |
      transactions |
      reserved1 |
      secureConnection |
      multiStatements |
      multiResults |
      psMultiResults |
      pluginAuth |
      connectAttrs |
      pluginAuthLenencClientData |
      expiredPasswords |
      sessionTrack |
      deprecateEof);

  static Capability kBasicCapabilities =
      Capability(((allValue & ~ssl) & ~compress) & ~sslVerifyServerCert);

  /// mysql 5.6 client default capability.
  static Capability kClientDefault56 = Capability(longPassword |
      longFlag |
      connectWithDb |
      localFiles |
      protocol41 |
      interactive |
      transactions |
      secureConnection |
      multiStatements |
      multiResults |
      psMultiResults |
      pluginAuth |
      connectAttrs |
      pluginAuthLenencClientData |
      expiredPasswords);

  static const a = interactive |
      multiResults |
      protocol41 |
      optionalResultsetMetadata |
      pluginAuth;
}

/// The status flags are a bit-field
class ServerStatus extends Flag {
  ServerStatus(int value) : super(value);

  /// a transaction is active
  static const int statusInTrans = 0x0001;

  /// auto-commit is enabled
  static const int statusAutocommit = 0x0002;
  static const int moreResultsExists = 0x0008;
  static const int statusNoGoodIndexUsed = 0x0010;
  static const int statusNoIndexUsed = 0x0020;

  /// Used by Binary Protocol Resultset to signal that
  /// COM_STMT_FETCH must be used to fetch the row-data.
  static const int statusCursorExists = 0x0040;
  static const int statusLastRowSent = 0x0080;
  static const int statusDbDropped = 0x0100;
  static const int statusNoBackslashEscapes = 0x0200;
  static const int statusMetadataChanged = 0x0400;
  static const int queryWasSlow = 0x0800;
  static const int psOutParams = 0x1000;

  /// in a read-only transaction
  static const int statusInTransReadonly = 0x2000;

  /// connection state information has changed
  static const int sessionStateChanged = 0x4000;

  static ServerStatus defaultStatus = ServerStatus(statusAutocommit);
}

/// Initial handshake packet for protocol version 10.
class Handshake extends Packet {
  final int serverCharset;
  final Capability serverCapability;
  final int serverStatus;

  final String version;
  final int threadId;

  /// MySQL authentication plugin name
  final String authPlugin;
  final Uint8List scramble;

  Handshake({
    this.serverCharset = Charset.utf8mb4,
    required this.serverCapability,
    this.serverStatus = ServerStatus.statusAutocommit,
    required this.version,
    required this.threadId,
    required this.authPlugin,
    required this.scramble,
  }) : assert(scramble.length == Salt.length);

  static const int protocolVersion = 10;

  /// Service side.
  /// sql/auth/sql_authentication.cc send_server_handshake_packet
  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(protocolVersion);
    out.writeCString(version);
    // pos 8
    out.write32(threadId);

    // first part of scrambles
    out.write(scramble.sublist(0, 8));
    out.write8(0);

    // pos: 20
    out.write16(serverCapability.value & 0xffff);

    // pos: 22
    // server default collation, charset, mysql8 一般返回 0xff
    out.write8(serverCharset);

    // server status, pos = 23
    out.write16(ServerStatus.statusAutocommit);
    // 0b1100011111111111
    out.write16(serverCapability.value >> 16); // clientCapbilities >> 16);

    if (serverCapability.has(Capability.pluginAuth)) {
      // pos: 28
      out.write8(scramble.length + 1);
    } else {
      out.write8(0);
    }

    // pos: 29, fill 10 0x00
    out.write(Uint8List(10));

    // pos = 40,
    out.write(scramble.sublist(8));
    out.write8(0);

    out.writeCString(authPlugin);
    return out.finished();
  }

  /// Client side.
  /// client: csm_parse_handshake
  /// server: parse_client_handshake_packet
  static Handshake parse(InputStream input) {
    final pv = input.readu8();
    assert(pv == protocolVersion);

    final version = input.readCString();
    final threadId = input.readu32();
    Uint8List scamble1 = input.read(8);
    input.skip(1);

    Capability serverCapability = Capability(input.readu16());
    int charset = input.readu8();

    int serverStatus = input.readu16();
    serverCapability.set(input.readu16() << 16);
    int scrambleLength = input.readu8();

    input.skip(10);
    Uint8List scamble2 = input.read(scrambleLength - 8 - 1);
    input.skip(1);

    final authPlugin = input.readCString();
    assert(input.byteLeft == 0);

    return Handshake(
      authPlugin: authPlugin,
      threadId: threadId,
      version: version,
      scramble: merge(scamble1, scamble2),
      serverCharset: charset,
      serverStatus: serverStatus,
      serverCapability: serverCapability,
    );
  }
}

class HandshakeResponse320 extends Packet {
  HandshakeResponse320() : super(0);
  parse(InputStream input) {
    final clientFlag = Capability(input.readu32());
    final maxPacketSize = input.readu32();
    final user = input.readCString();
    // TODO:
  }
}

/// If the client requests a TLS/SSL connection, first response will be
/// an SSL connection request packet, then a handshake response packet.
/// If no TLS is required, client send directly a handshake response packet.
class SslRequest extends Packet {
  final Capability clientFlag;
  final int maxPaketSize;
  final int charset;

  SslRequest({
    required this.clientFlag,
    required this.maxPaketSize,
    required this.charset,
  });

  factory SslRequest.parse(InputStream input) {
    final clientFlag = Capability(input.readu32());
    final maxPacketSize = input.readu32();
    final charset = input.readu8();
    input.skip(23);
    return SslRequest(
      clientFlag: clientFlag,
      maxPaketSize: maxPacketSize,
      charset: charset,
    );
  }
}

part of mysql.impl;

/// ERR_Packet indicates that an error occured.
class ErrorPacket extends Packet {
  final int code;

  /// sql state
  final String? state;

  /// human-readable error message
  final String message;

  ErrorPacket({
    required this.code,
    this.state,
    required this.message,
  });

  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(Packet.error);
    out.write16(code);
    if (state != null) {
      out.writeString('#$state');
    }
    out.writeString(message);
    return out.finished();
  }

  factory ErrorPacket.parse(InputStream input, Capability clientCapability) {
    input.skip(1);
    final code = input.readu16();
    String? state;
    if (clientCapability.has(Capability.protocol41)) {
      input.skip(1);
      state = String.fromCharCodes(input.read(5));
    }
    String message = input.readEofString();
    return ErrorPacket(code: code, state: state, message: message);
  }

  @override
  String toString() => 'ERROR $code ($state): $message';
}

/// In the MySQL client/server protocol, EOF and OK packets serve
/// the same purpose, to mark the end of a query execution result.
/// Due to changes in MySQL 5.7 in the OK packet (such as session
/// state tracking), and to avoid repeating the changes in
/// the EOF packet, the EOF packet is deprecated as of MySQL 5.7.5.
class EofPacket extends Packet {
  final int warnings;
  final int serverStatus;
  EofPacket(this.warnings, [this.serverStatus = ServerStatus.statusAutocommit])
      : super(0);

  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(Packet.eof);
    out.write16(warnings);
    out.write16(serverStatus);
    return out.finished();
  }

  factory EofPacket.parse(InputStream input, Capability clientCapability) {
    input.skip(1);
    if (clientCapability.has(Capability.protocol41)) {
      final warnings = input.readu16();
      final serverStatus = input.readu16();
      return EofPacket(warnings, serverStatus);
    }
    return EofPacket(0, 0);
  }

  @override
  String toString() => "EOF: $warnings $serverStatus";
}

/// An OK packet is sent from the server to the client to
/// signal successful completion of a command. As of
/// MySQL 5.7.5, OK packes are also used to indicate EOF,
/// and EOF packets are deprecated.
class OkPacket extends Packet {
  final int affectedRows;
  final int lastInsertId;
  final int serverStatus;
  final int warningCount;
  final String? info;
  final String? sessionStateChanges;

  OkPacket({
    this.affectedRows = 0,
    this.lastInsertId = 0,
    this.serverStatus = ServerStatus.statusAutocommit,
    this.warningCount = 0,
    this.info,
    this.sessionStateChanges,
  });

  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(Packet.ok);
    out.writeLength(affectedRows);
    out.writeLength(lastInsertId);
    out.write16(serverStatus);
    out.write16(warningCount);
    if (info != null) {
      out.writeLengthEncodedString(info!);

      if (sessionStateChanges != null) {
        out.writeCString(sessionStateChanges!);
      }
    }
    return out.finished();
  }

  factory OkPacket.parse(InputStream input, Capability clientCapability) {
    input.skip(1);
    final affectedRows = input.readLength();
    final lastInsertId = input.readLength();
    int? serverStatus;
    int? warningCount;

    if (clientCapability.has(Capability.protocol41)) {
      serverStatus = input.readu16();
      warningCount = input.readu16();
    } else if (clientCapability.has(Capability.transactions)) {
      serverStatus = input.readu16();
    }

    String? info;
    String? sessionStateChanges;

    if (input.byteLeft > 0) {
      if (clientCapability.has(Capability.sessionTrack)) {
        info = input.readLengthEncodedString();
        if (ServerStatus(serverStatus!).has(ServerStatus.sessionStateChanged)) {
          sessionStateChanges = input.readLengthEncodedString();
        }
      } else {
        info = input.readCString();
      }
    }

    return OkPacket(
      affectedRows: affectedRows,
      lastInsertId: lastInsertId,
      serverStatus: serverStatus!,
      warningCount: warningCount ?? 0,
      info: info,
      sessionStateChanges: sessionStateChanges,
    );
  }
}

part of mysql.impl;

///
class CommandPacket extends Packet {
  final Command command;
  CommandPacket(this.command);

  factory CommandPacket.parse(InputStream input) {
    final cmd = Command.values[input.readu8()];
    switch (cmd) {
      case Command.quit:
        return QuitCommand(cmd);
      case Command.query:
      case Command.initDb:
        return QueryCommand.parse(cmd, input);
      case Command.fieldList:
        return FieldListCommand.parse(input);
      case Command.stmtPrepare:
        return PrepareStatement.parse(input);
      default:
        throw UnimplementedError('TODO: $cmd');
    }
  }

  @override
  String toString() => 'CommandPacket($command)';
}

typedef QuitCommand = CommandPacket;

class QueryCommand extends CommandPacket {
  final String sql;
  QueryCommand({
    Command command = Command.query,
    required this.sql,
  }) : super(command);

  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(command.index);
    out.writeString(sql);
    return out.finished();
  }

  factory QueryCommand.parse(Command command, InputStream input) =>
      QueryCommand(
        command: command,
        sql: input.readEofString(),
      );

  @override
  String toString() => 'QueryCommand("$sql")';
}

///
class FieldListCommand extends CommandPacket {
  final String table;
  final String fieldWildcard;
  FieldListCommand({
    required this.table,
    required this.fieldWildcard,
  }) : super(Command.fieldList);

  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(command.index);
    out.writeCString(table);
    out.writeString(fieldWildcard);
    return out.finished();
  }

  factory FieldListCommand.parse(InputStream input) => FieldListCommand(
        table: input.readCString(),
        fieldWildcard: input.readEofString(),
      );

  @override
  String toString() => 'FieldListCommand($table, $fieldWildcard)';
}

class FieldListResponse extends Packet {
  final List<ColumnDefinition> defs;
  FieldListResponse(this.defs);

  @override
  Uint8List encode() {
    final out = OutputStream();
    int i = 1;

    for (var cd in defs) {
      out.write(Packet.build(i++, cd).encode());
    }
    out.write(Packet.build(i++, EofPacket(0)).encode());
    return out.finished();
  }

  factory FieldListResponse.parse(InputStream input) {
    final defs = <ColumnDefinition>[];
    while (input.byteLeft > 0) {
      final p = Packet.parse(input);
      if (p.body != null) {
        defs.add(ColumnDefinition.parse(p.inputStream, true));
      } else {
        assert(p is EofPacket);
      }
    }
    return FieldListResponse(defs);
  }
}

class CursorType {
  static const int noCursor = 0x00;
  static const int readOnly = 0x01;
  static const int forUpdate = 0x02;
  static const int scrollable = 0x04;
}

///
class PrepareStatement extends CommandPacket {
  final String sql;
  PrepareStatement({required this.sql}) : super(Command.stmtPrepare);

  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(command.index);
    out.writeString(sql);
    return out.finished();
  }

  factory PrepareStatement.parse(InputStream input) => PrepareStatement(
        sql: input.readEofString(),
      );

  @override
  String toString() => 'PrepareStatement("$sql")';
}

class PrepareStatementResponse extends Packet {
  final int status;
  final int stmtId;
  final int numColumns;
  final int numParams;
  final int reserved1;
  final int warningCount;
  final List<ColumnDefinition> cols;
  final List<ColumnDefinition> params;

  PrepareStatementResponse({
    required this.status,
    required this.stmtId,
    this.numColumns = 0,
    this.numParams = 0,
    this.reserved1 = 0,
    this.warningCount = 0,
    this.params = const <ColumnDefinition>[],
    this.cols = const <ColumnDefinition>[],
  }) : assert(numColumns == 0 || numParams == 0);

  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(status);
    out.write32(stmtId);
    out.write16(numColumns);
    out.write16(numParams);
    out.write8(reserved1);
    out.write16(warningCount);

    for (final p in params) {
      p.encode(out);
    }
    out.write(Packet.build(0, EofPacket(0)).encode());

    for (final p in cols) {
      p.encode(out);
    }
    out.write(Packet.build(0, EofPacket(0)).encode());
    return out.finished();
  }

  factory PrepareStatementResponse.parse(InputStream input) {
    final status = input.readu8();
    final stmtId = input.readu32();
    final numColumns = input.readu16();
    final numParams = input.readu16();
    final reserved1 = input.readu8();
    final warningCount = input.readu16();

    final params = <ColumnDefinition>[];
    for (int i = 0; i < numParams; ++i) {
      final p = Packet.parse(input);
      if (p.body != null) {
        params.add(ColumnDefinition.parse(p.inputStream, true));
      } else {
        assert(p is EofPacket);
      }
    }

    final cols = <ColumnDefinition>[];
    for (int i = 0; i < numColumns; ++i) {
      final p = Packet.parse(input);
      if (p.body != null) {
        cols.add(ColumnDefinition.parse(p.inputStream, true));
      } else {
        assert(p is EofPacket);
      }
    }
    return PrepareStatementResponse(
      status: status,
      stmtId: stmtId,
      numColumns: numColumns,
      numParams: numParams,
      reserved1: reserved1,
      warningCount: warningCount,
      params: params,
      cols: cols,
    );
  }
}

///
class ExecuteStatement extends CommandPacket {
  final int stmtId;
  final int flags; // cursor type
  final int iterationCount;
  final int numParams;
  final int newParamsBoundFlag;

  ExecuteStatement({
    required this.stmtId,
    required this.flags,
    this.iterationCount = 1,
    required this.numParams,
    required this.newParamsBoundFlag,
  }) : super(Command.stmtExecute);

  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(command.index);
    out.write32(stmtId);
    out.write8(flags);
    out.write32(iterationCount);
    if (numParams > 0) {
      // write null-bitmap
    }
    if (newParamsBoundFlag == 1) {}
    return out.finished();
  }

  // factory ExecuteStatement.parse(InputStream input) => ExecuteStatement(
  //       command: Command.values[input.readu8()],
  //       stmtId: input.readu32(),
  //       flags: input.readu8(),
  //       iterationCount: input.readu32(),
  //     );
}

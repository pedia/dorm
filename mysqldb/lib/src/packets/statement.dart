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
      case Command.stmtPrepare:
        return QueryCommand.parse(cmd, input);
      case Command.fieldList:
        return FieldListCommand.parse(input);
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
class ExecuteStatement extends Packet {
  final Command command;
  final int stmtId;
  final int flags; // cursor type
  final int iterationCount;
  final int numParams;
  final int newParamsBoundFlag;

  ExecuteStatement({
    this.command = Command.stmtExecute,
    required this.stmtId,
    required this.flags,
    this.iterationCount = 1,
    required this.numParams,
    required this.newParamsBoundFlag,
  });

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

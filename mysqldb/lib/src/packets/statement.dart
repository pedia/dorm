part of mysql.impl;

///
class QueryCommand extends Packet {
  final Command command;
  final String sql;

  QueryCommand({
    this.command = Command.query,
    required this.sql,
  });

  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(command.index);
    out.writeString(sql);
    return out.finished();
  }

  factory QueryCommand.parse(InputStream input) => QueryCommand(
        command: Command.values[input.readu8()],
        sql: input.readEofString(),
      );
}

///
class PrepareStatement extends QueryCommand {
  PrepareStatement({
    Command command = Command.stmtPrepare,
    required String sql,
  }) : super(command: Command.stmtPrepare, sql: sql);

  factory PrepareStatement.parse(InputStream input) => PrepareStatement(
        command: Command.values[input.readu8()],
        sql: input.readEofString(),
      );
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

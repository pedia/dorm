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
      case Command.ping:
        return PingCommand();
      case Command.fieldList:
        return FieldListCommand.parse(input);
      case Command.stmtPrepare:
        return PrepareStatement.parse(input);
      case Command.stmtExecute:
      // TODO: return ExecuteStatement.parse(input);
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
class PingCommand extends CommandPacket {
  PingCommand() : super(Command.ping);
  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(command.index);
    return out.finished();
  }
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
  final int reserved1;
  final int warningCount;
  final List<ColumnDefinition> cols;
  final List<ColumnDefinition> params;

  int get numParams => params.length;

  PrepareStatementResponse({
    required this.status,
    required this.stmtId,
    this.numColumns = 0,
    int numParams = 0,
    this.reserved1 = 0,
    this.warningCount = 0,
    this.params = const <ColumnDefinition>[],
    this.cols = const <ColumnDefinition>[],
  }) : assert(numParams == params.length);

  @override
  Uint8List encode() {
    int pid = 1;
    final out = OutputStream();
    {
      final sub = OutputStream();
      sub.write8(status);
      sub.write32(stmtId);
      sub.write16(numColumns);
      sub.write16(numParams);
      sub.write8(reserved1);
      sub.write16(warningCount);
      out.write(Packet(pid++, sub.finished()).encode());
    }

    if (params.isNotEmpty) {
      for (final p in params) {
        out.write(Packet(pid++, p.encode()).encode());
      }
      out.write(Packet.build(pid++, EofPacket(0)).encode());
    }
    if (cols.isNotEmpty) {
      for (final p in cols) {
        out.write(Packet(pid++, p.encode()).encode());
      }
      out.write(Packet.build(pid++, EofPacket(0)).encode());
    }
    return out.finished();
  }

  factory PrepareStatementResponse.parse(InputStream input) {
    final p0 = Packet.parse(input);
    final status = p0.inputStream.readu8();
    final stmtId = p0.inputStream.readu32();
    final numColumns = p0.inputStream.readu16();
    final numParams = p0.inputStream.readu16();
    final reserved1 = p0.inputStream.readu8();
    final warningCount = p0.inputStream.readu16();

    final params = <ColumnDefinition>[];
    if (numParams > 0) {
      for (int i = 0; i < numParams; ++i) {
        final p = Packet.parse(input);
        params.add(ColumnDefinition.parse(p.inputStream));
      }
      final eof1 = Packet.parse(input);
      assert(eof1 is EofPacket);
    }

    final cols = <ColumnDefinition>[];
    if (numColumns > 0) {
      for (int i = 0; i < numColumns; ++i) {
        final p = Packet.parse(input);
        cols.add(ColumnDefinition.parse(p.inputStream));
      }
      final eof2 = Packet.parse(input);
      assert(eof2 is EofPacket);
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

class CursorType {
  static const int noCursor = 0x00;
  static const int readOnly = 0x01;
  static const int forUpdate = 0x02;
  static const int scrollable = 0x04;
}

///
class ExecuteStatement extends CommandPacket {
  final int stmtId;
  final int cursorType; // flags
  final int iterationCount;
  final int newParamsBoundFlag;
  final List<Field> values;

  ExecuteStatement({
    required this.stmtId,
    this.cursorType = CursorType.noCursor,
    this.iterationCount = 1,
    this.newParamsBoundFlag = 1,
    required this.values,
  }) : super(Command.stmtExecute);

  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(command.index);
    out.write32(stmtId);
    out.write8(cursorType);
    out.write32(iterationCount);
    if (values.isNotEmpty) {
      out.write(createNullMap(values));
    }

    if (newParamsBoundFlag == 1) {
      for (final v in values) {}
    }
    return out.finished();
  }

  static Uint8List createNullMap(List<Object?> values) {
    var bytes = (values.length + 7) ~/ 8;
    var nullMap = List<int>.filled(bytes, 0);

    var byte = 0;
    var bit = 0;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == null) {
        nullMap[byte] = nullMap[byte] + (1 << bit);
      }
      bit++;
      if (bit > 7) {
        bit = 0;
        byte++;
      }
    }

    return Uint8List.fromList(nullMap);
  }

  factory ExecuteStatement.parse(
      InputStream input, PrepareStatementResponse psr) {
    final p = Packet.parse(input);
    final command = p.inputStream.readu8();
    assert(Command.stmtExecute.index == command);
    final stmtId = p.inputStream.readu32();
    assert(stmtId == psr.stmtId);
    final cursorType = p.inputStream.readu8();
    final iterationCount = p.inputStream.readu32();

    if (psr.numParams == 0) {
      // Bytes left are not needed
      return ExecuteStatement(
        stmtId: stmtId,
        cursorType: cursorType,
        iterationCount: iterationCount,
        newParamsBoundFlag: 0,
        values: [],
      );
    }

    final values = <Field>[];
    late int newParamsBoundFlag;

    if (psr.numParams > 0) {
      Uint8List nullBitmap = p.inputStream.read((psr.numParams + 7) ~/ 8);
      newParamsBoundFlag = p.inputStream.readu8();

      if (newParamsBoundFlag == 1) {
        for (int i = 0; i < psr.numParams; ++i) {
          final byte = i ~/ 8;
          final bit = 1 << (i & 7);
          bool isNull = nullBitmap[byte] & bit == bit;

          final type = p.inputStream.readu8();
          p.inputStream.readu8(); // 0
          switch (type) {
            case Field.typeNull:
              values.add(Field(value: null, type: Field.typeNull));
              break;
            case Field.typeTiny:
              values.add(
                  Field(value: p.inputStream.readu8(), type: Field.typeTiny));
              break;
            case Field.typeLong:
              break;
            case Field.typeLonglong:
              break;
            case Field.typeDouble:
            case Field.typeDecimal:
              break;
            case Field.typeDate:
            case Field.typeDatetime:
            case Field.typeTime:
            case Field.typeTimestamp:
              break;

            case Field.typeBlob:
              break;
            case Field.typeVarchar:
              values.add(Field(
                  value: p.inputStream.readLengthEncodedString(),
                  type: Field.typeVarString));
              break;
            default:
              break;
          }
        }
      }
    }

    return ExecuteStatement(
      stmtId: stmtId,
      cursorType: cursorType,
      iterationCount: iterationCount,
      newParamsBoundFlag: newParamsBoundFlag,
      values: values,
    );
  }
}

class ExecuteStatementResponse extends Packet {}

part of mysql.impl;

///
class CommandPacket extends Packet {
  final Command command;
  CommandPacket(this.command);

  factory CommandPacket.parse(InputStream input, [Object? arg]) {
    // TODO: Use peek instead
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
      case Command.stmtClose:
        return CloseStatement.parse(input);
      case Command.stmtExecute:
        return ExecuteStatement.parse(input, arg as PrepareStatementResponse);
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
    final bytes = (values.length + 7) ~/ 8;
    final nullMap = List<int>.filled(bytes, 0);

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

      final types = [];

      if (newParamsBoundFlag == 1) {
        for (int i = 0; i < psr.numParams; ++i) {
          final byte = i ~/ 8;
          final bit = 1 << (i & 7);
          bool isNull = nullBitmap[byte] & bit == bit;

          final type = p.inputStream.readu8();
          p.inputStream.readu8();

          types.add(type);
        }

        for (final type in types) {
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

/// https://dev.mysql.com/doc/internals/en/binary-protocol-resultset-row.html
class BinaryRow extends Packet {
  final List<Object?> values;
  BinaryRow(this.values);

  factory BinaryRow.parse(InputStream input, List<ColumnDefinition> cds) {
    final _ = input.readu8();
    assert(_ == 0);
    Uint8List nullBitmap = input.read((cds.length + 7 + 2) ~/ 8);
    final bits = List.generate(cds.length, (i) {
      // weired +2
      final byte = (i + 2) ~/ 8;
      final bit = 1 << ((i + 2) % 8);
      return nullBitmap[byte] & bit == bit;
    });
    final values = <Object?>[];

    for (int i = 0; i < cds.length; ++i) {
      if (bits[i]) {
        values.add(null);
        assert(cds[i].columnType == Field.typeNull);
        continue;
      }

      final cd = cds[i];
      switch (cd.columnType) {

        ///
        case Field.typeString:
        case Field.typeVarString:
          final value = input.readLengthEncodedString();
          values.add(value);
          break;

        ///
        case Field.typeTiny:
          values.add(input.readu8());
          break;
        case Field.typeShort:
          values.add(input.readu16());
          break;
        case Field.typeInt24:
        case Field.typeLong:
          values.add(input.readu32());
          break;
        case Field.typeLonglong:
          values.add(input.readu64());
          break;

        ///
        case Field.typeFloat:
          values.add(input.readFloat());
          break;
        case Field.typeDouble:
          values.add(input.readDouble());
          break;

        ///
        case Field.typeDate:
        case Field.typeDatetime:
        case Field.typeTimestamp:
          final len = input.readu8();
          if (len == 4) {
            final dt = DateTime(
              input.readu16(),
              input.readu8(),
              input.readu8(),
            );
            values.add(dt);
          } else if (len >= 7) {
            var dt = DateTime(
              input.readu16(),
              input.readu8(),
              input.readu8(),
              input.readu8(),
              input.readu8(),
              input.readu8(),
            );

            if (len == 11) {
              final mcs = input.readu32();
              dt = dt.add(Duration(microseconds: mcs));
            }
            values.add(dt);
          }
          break;

        ///
        case Field.typeTime:
          final len = input.readu8();
          int days = input.readu32();
          if (days == 1) days = -days;
          var d = Duration(
            days: days,
            hours: input.readu8(),
            minutes: input.readu8(),
            seconds: input.readu8(),
          );

          if (len > 8) {
            d += Duration(microseconds: input.readu32());
          }
          values.add(d);
          break;

        default:
          throw UnimplementedError('BinaryRow value type: ${cd.columnType}');
      }
    }

    // assert(input.byteLeft == 0);
    return BinaryRow(values);
  }
}

class BinaryResultSet extends Packet {
  final List<ColumnDefinition> cds;
  final List<BinaryRow> rows;

  BinaryResultSet(this.cds, this.rows);

  factory BinaryResultSet.parse(InputStream input) {
    final cds = <ColumnDefinition>[];
    final rows = <BinaryRow>[];

    final p0 = Packet.parse(input);
    if (p0 is EofPacket || p0 is OkPacket) {
      return BinaryResultSet(cds, rows); // Is this right?
    }

    /// column define count
    final columnCount = p0.inputStream.readLength();

    for (int i = 0; i < columnCount; ++i) {
      final p = Packet.parse(input);
      cds.add(ColumnDefinition.parse(p.inputStream));
      assert(p.inputStream.byteLeft == 0);
    }
    if (columnCount > 0) {
      final tail = Packet.parse(input);
      assert(tail is EofPacket);
    }

    while (true) {
      final p2 = Packet.parse(input);
      if (p2 is EofPacket) break;

      rows.add(BinaryRow.parse(p2.inputStream, cds));
      assert(p2.inputStream.byteLeft == 0);
    }

    assert(input.byteLeft == 0);
    return BinaryResultSet(cds, rows);
  }
}

/// Deallocates a prepared statement
/// No response is sent back to the client.
class CloseStatement extends CommandPacket {
  final int stmtId;
  CloseStatement(this.stmtId) : super(Command.stmtClose);

  @override
  Uint8List encode() {
    final out = OutputStream();
    out.write8(command.index);
    out.write32(stmtId);
    return out.finished();
  }

  factory CloseStatement.parse(InputStream input) {
    final stmtId = input.readu32();
    assert(input.byteLeft == 0);
    return CloseStatement(stmtId);
  }
}

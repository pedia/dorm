part of mysql.impl;

///
class ColumnDefinition extends Packet {
  final String catalog;
  final String schema;
  final String table;
  final String orgTable;
  final String name;
  final String orgName;
  final int nextLength;
  final int charset;
  final int columnLength;
  final int columnType; // Field.typeXxx
  final int flags;

  /// 0x00 for integers and static strings
  /// 0x1f for dynamic strings, double, float
  /// 0x00 to 0x51 for decimals
  final int decimals;
  final int filler;

  /// in COM_FIELD_LIST, defaultValue used.
  /// Split a new class is too expensive
  final bool inComFieldList;
  final String? defaultValue;

  ColumnDefinition({
    this.catalog = 'def',
    required this.schema,
    required this.table,
    required this.orgTable,
    required this.name,
    required this.orgName,
    this.nextLength = 0x0c,
    this.charset = Charset.utf8,
    required this.columnLength,
    required this.columnType,
    this.flags = 0,
    this.decimals = 0,
    this.filler = 0,
    this.defaultValue,
    this.inComFieldList = false,
  });

  ColumnDefinition apply({
    String? catalog,
    String? schema,
    String? table,
    String? orgTable,
    String? name,
    String? orgName,
    int? charset,
    int? columnLength,
    int? columnType,
    int? decimals,
  }) =>
      ColumnDefinition(
        catalog: catalog ?? this.catalog,
        schema: schema ?? this.schema,
        table: table ?? this.table,
        orgTable: orgTable ?? this.orgTable,
        name: name ?? this.name,
        orgName: orgName ?? this.orgName,
        charset: charset ?? this.charset,
        columnLength: columnLength ?? this.columnLength,
        columnType: columnType ?? this.columnType,
        decimals: decimals ?? this.decimals,
      );

  factory ColumnDefinition.varString({
    String schema = '',
    required String table,
    required String name,
    required int columnLength,
  }) =>
      ColumnDefinition(
        schema: schema,
        table: table,
        orgTable: table,
        name: name,
        orgName: name,
        columnLength: columnLength,
        columnType: Field.typeVarString,
        decimals: 31,
      );

  @override
  Uint8List encode([OutputStream? out]) {
    out ??= OutputStream();
    out.writeLengthEncodedString(catalog);
    out.writeLengthEncodedString(schema);
    out.writeLengthEncodedString(table);
    out.writeLengthEncodedString(orgTable);
    out.writeLengthEncodedString(name);
    out.writeLengthEncodedString(orgName);
    out.write8(nextLength);
    out.write16(charset);
    out.write32(columnLength);
    out.write8(columnType);
    out.write16(flags);
    out.write8(decimals);
    out.write16(filler);

    // if command was COM_FIELD_LIST
    if (inComFieldList) {
      int sz = (defaultValue ?? '').length;
      out.writeFieldLength(sz);
      out.writeString(defaultValue ?? '');
    }
    return out.finished();
  }

  factory ColumnDefinition.parse(InputStream input,
      [bool inComFieldList = false]) {
    final cd = ColumnDefinition(
      catalog: input.readLengthEncodedString(),
      schema: input.readLengthEncodedString(),
      table: input.readLengthEncodedString(),
      orgTable: input.readLengthEncodedString(),
      name: input.readLengthEncodedString(),
      orgName: input.readLengthEncodedString(),
      nextLength: input.readu8(),
      charset: input.readu16(),
      columnLength: input.readu32(),
      columnType: input.readu8(),
      flags: input.readu16(),
      decimals: input.readu8(),
      filler: input.readu16(),
      inComFieldList: inComFieldList,
      defaultValue: inComFieldList ? input.readLengthEncodedString() : null,
    );

    if (inComFieldList) {
      assert(input.byteLeft == 0);
    }
    return cd;
  }
}

typedef Row = List<Field>;

///
class ResultSet extends Packet {
  final List<ColumnDefinition> columns;
  final List<Row> rows;
  final int serverStatus;
  ResultSet(
    this.columns,
    this.rows, [
    this.serverStatus = ServerStatus.statusAutocommit,
  ]);

  factory ResultSet.empty() => ResultSet([], []);

  int get rowCount => rows.length;
  int get columnCount => columns.length;

  Field fieldOf(int row, int col) => rows[row][col];

  @override
  Uint8List encode() {
    final out = OutputStream();
    int seqid = 1;
    // 1
    out.write3ByteLength(1);
    out.write8(seqid++);
    out.write8(columns.length);

    // 2 def
    for (ColumnDefinition col in columns) {
      final buf = col.encode();
      out.write3ByteLength(buf.length);
      out.write8(seqid++);
      out.write(buf);
    }
    // 3
    final eof = EofPacket(0, serverStatus).encode();
    out.write3ByteLength(eof.length);
    out.write8(seqid++);
    out.write(eof);

    // 4 row
    for (int row = 0; row < rowCount; ++row) {
      final sub = OutputStream();
      for (int col = 0; col < columnCount; ++col) {
        fieldOf(row, col).encode(sub);
      }

      final buf = sub.finished();
      out.write3ByteLength(buf.length);
      out.write8(seqid++);
      out.write(buf);
    }

    // 5
    out.write3ByteLength(eof.length);
    out.write8(seqid++);
    out.write(eof);
    return out.finished();
  }

  factory ResultSet.parse(InputStream input) {
    // 1
    int seqlen = input.read3ByteLength();
    int seqid = input.readu8();
    int columCount = input.readu8();

    // 2 def
    final columns = <ColumnDefinition>[];
    for (int i = 0; i < columCount; ++i) {
      seqlen = input.read3ByteLength();
      seqid = input.readu8();
      columns.add(ColumnDefinition.parse(input));
    }

    // 3
    seqlen = input.read3ByteLength();
    seqid = input.readu8();
    final eof = EofPacket.parse(input, Capability.kClientDefault56);

    // 4 row
    final fields = <Field>[];
    do {
      seqlen = input.read3ByteLength();
      seqid = input.readu8();
      final fe = input.peek();
      if (fe != 0xfe) {
        for (int c = 0; c < columCount; ++c) {
          final field = Field.parse(input, columns[c]);
          fields.add(field);
        }
      } else {
        final last = EofPacket.parse(input, Capability.kClientDefault56);
        break;
      }
    } while (true);

    // Convert to List<Row>
    final rows = <Row>[];
    for (int r = 0; r < fields.length ~/ columns.length; ++r) {
      rows.add(fields.sublist(r * columCount, r * columCount + columCount));
    }

    assert(input.byteLeft == 0);
    return ResultSet(columns, rows, eof.serverStatus);
  }

  @override
  String toString() {
    final widthList = columns.map((col) => col.name.length).toList();
    for (int i = 0; i < rowCount; ++i) {
      for (int c = 0; c < columns.length; ++c) {
        widthList[c] = max(widthList[c], fieldOf(i, c).width ?? 0);
      }
    }

    int i = 0;
    final cs = columns.map((col) => col.name.padLeft(widthList[i++])).join('|');

    final rs = <String>[];
    for (int r = 0; r < rowCount; ++r) {
      final s = List.generate(columnCount,
          (i) => fieldOf(r, i).toString().padLeft(widthList[i++])).join('|');
      rs.add(s);
    }

    return [
      cs,
      List.generate(widthList.fold(0, (prev, c) => c + prev), (i) => '-')
          .join(''),
      ...rs
    ].join('\n');
  }
}

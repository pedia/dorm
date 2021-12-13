part of mysql.impl;

class Field {
  static const int typeDecimal = 0x00;
  static const int typeTiny = 0x01;
  static const int typeShort = 0x02;
  static const int typeLong = 0x03;
  static const int typeFloat = 0x04;
  static const int typeDouble = 0x05;
  static const int typeNull = 0x06;
  static const int typeTimestamp = 0x07;
  static const int typeLonglong = 0x08;
  static const int typeInt24 = 0x09;
  static const int typeDate = 0x0a;
  static const int typeTime = 0x0b;
  static const int typeDatetime = 0x0c;
  static const int typeYear = 0x0d;
  static const int typeNewdate = 0x0e;
  static const int typeVarchar = 0x0f;
  static const int typeBit = 0x10;
  static const int typeNewdecimal = 0xf6;
  static const int typeEnum = 0xf7;
  static const int typeSet = 0xf8;
  static const int typeTinyBlob = 0xf9;
  static const int typeMediumBlob = 0xfa;
  static const int typeLongBlob = 0xfb;
  static const int typeBlob = 0xfc;
  static const int typeVarString = 0xfd;
  static const int typeString = 0xfe;
  static const int typeGeometry = 0xff;

  static String? typeNameOf(int type) {
    final names = {
      0x00: 'Decimal',
      0x01: 'Tiny',
      0x02: 'Short',
      0x03: 'Long',
      0x04: 'Float',
      0x05: 'Double',
      0x06: 'Null',
      0x07: 'Timestamp',
      0x08: 'Longlong',
      0x09: 'Int24',
      0x0a: 'Date',
      0x0b: 'Time',
      0x0c: 'Datetime',
      0x0d: 'Year',
      0x0e: 'Newdate',
      0x0f: 'Varchar',
      0x10: 'Bit',
      0xf6: 'Newdecimal',
      0xf7: 'Enum',
      0xf8: 'Set',
      0xf9: 'TinyBlob',
      0xfa: 'MediumBlob',
      0xfb: 'LongBlob',
      0xfc: 'Blob',
      0xfd: 'VarString',
      0xfe: 'String',
      0xff: 'Geometry',
    };
    return names[type];
  }

  // NULL is sent as 0xfb
  static const int nullValue = 0xfb;

  final dynamic value;
  final int type;

  /// Width of value to String.
  final int? width;

  final int? decimals;

  Field(this.value, this.type, {this.width, this.decimals = 0});

  factory Field.of(Object? o) {
    if (o == null) {
      return Field(null, typeNull);
    } else if (o is String) {
      return Field(o, typeVarString);
    } else if (o is Double) {
      return Field(o, typeDouble);
    } else if (o is int) {
      return Field(o, typeLong);
    } else if (o is Duration) {
      return Field(o, typeTime);
    } else if (o is DateTime) {
      return Field(o, typeDatetime);
    }
    throw UnimplementedError();
  }

  factory Field.string(String? value) => Field(value, typeVarString);

  Uint8List encode([OutputStream? out]) {
    out ??= OutputStream();

    if (value == null) {
      out.write8(nullValue);
    } else {
      switch (type) {
        case typeTiny:
        case typeShort:
        case typeLong:
        case typeLonglong:
        case typeInt24:
        case typeYear:
          final buf =
              Uint8List.fromList(utf8.encode((value as int).toString()));
          out.writeFieldLength(buf.length);
          out.write(buf);
          break;
        case typeNewdecimal:
        case typeFloat:
        case typeDouble:
          final buf = Uint8List.fromList(
              utf8.encode((value as num).toStringAsFixed(decimals!)));
          out.writeFieldLength(buf.length);
          out.write(buf);
          break;
        case typeBit:
          // int v = 0;
          // for (int n in bytes) {
          //   v = (v << 8) + n;
          // }
          // return Field(fieldType, v, 8);
          assert(false);
          break;
        case typeDate:
        case typeDatetime:
        case typeTimestamp:
          final buf = Uint8List.fromList(
              utf8.encode((value as DateTime).toString().substring(0, 19)));
          out.writeFieldLength(buf.length);
          out.write(buf);
          break;
        case typeTime:
          final d = Duration(seconds: value as int);
          final s = '${d.inHours.toStringAsFixed(2).padLeft(2, '0')}:'
              '${(d.inMinutes % 3600).toStringAsFixed(2).padLeft(2, '0')}:'
              '${(d.inSeconds % 60).toStringAsFixed(2).padLeft(2, '0')}';
          final buf = Uint8List.fromList(utf8.encode(s));
          out.writeFieldLength(buf.length);
          out.write(buf);
          break;
        case typeString:
        case typeVarString:
        case typeGeometry:
          //
          if (value.isEmpty) {
            out.write8(0);
          } else {
            final buf = Uint8List.fromList(utf8.encode(value));
            out.writeFieldLength(buf.length);
            out.write(buf);
          }
          break;
        case typeBlob:
          if (value.isEmpty) {
            out.write8(0);
          } else {
            final buf = value as Uint8List;
            out.writeLength(buf.length);
            out.write(buf);
          }
          break;
        default:
          throw Exception('FieldType $type is unknown');
      }
    }
    return out.finished();
  }

  factory Field.parse(InputStream input, int fieldType, [int? decimals]) {
    // Difference between NULL(null String) and ''(empty String):
    //  in the byte of `length`:
    //    0xfb -> NULL
    //    0x00 -> ''
    // This occured in `String` and `Blob`, not in `int` and `Datetime`
    int force = input.peek();

    if (force == nullValue) {
      input.skip(1);
      return Field(null, fieldType, width: 4);
    }

    final len = input.readLength();
    final bytes = input.read(len);
    switch (fieldType) {
      case typeTiny:
      case typeShort:
      case typeLong:
      case typeLonglong:
      case typeInt24:
      case typeYear:
        final s = utf8.decode(bytes);
        return Field(int.parse(s), fieldType, width: s.length);
      case typeNewdecimal:
      case typeFloat:
      case typeDouble:
        final s = utf8.decode(bytes);
        return Field(
          double.parse(s),
          fieldType,
          width: s.length,
          decimals: decimals,
        );
      case typeBit:
        int v = 0;
        for (int n in bytes) {
          v = (v << 8) + n;
        }
        return Field(v, fieldType, width: 8);
      case typeDate:
      case typeDatetime:
      case typeTimestamp:
        final s = utf8.decode(bytes);
        return Field(
          DateTime.parse(s),
          fieldType,
          width: s.length,
        );
      case typeTime:
        final arr = utf8.decode(bytes).split(':');
        final d = Duration(
          hours: int.parse(arr[0]),
          minutes: int.parse(arr[0]),
          seconds: int.parse(arr[0]),
        );
        return Field(d, fieldType, width: 8);
      case typeString:
      case typeVarString:
      case typeGeometry:
        if (force == 0) {
          return Field('', fieldType, width: 0);
        }
        final s = utf8.decode(bytes);
        return Field(s, fieldType, width: s.length);
      case typeBlob:
        if (force == 0) {
          return Field(Uint8List(0), fieldType, width: 0);
        }
        return Field(bytes, fieldType, width: bytes.length * 2);
      default:
        throw Exception('FieldType $fieldType is unknown, $bytes');
    }
  }

  @override
  String toString() {
    if (value == null) {
      return 'NULL';
    }

    switch (type) {
      case typeBit:
        // int v = 0;
        // for (int n in bytes) {
        //   v = (v << 8) + n;
        // }
        // return Field(fieldType, v, 8);
        assert(false);
        break;
      case typeFloat:
      case typeDouble:
        return (value as double).toStringAsFixed(decimals!);
      case typeDate:
      case typeDatetime:
        // 2021-11-07 13:32:57.000 to 2021-11-07 13:32:57
        return (value as DateTime).toString().substring(0, 19);
      case typeTimestamp:
        final dt = DateTime.fromMillisecondsSinceEpoch((value as int) * 1000,
            isUtc: true);
        return dt.toString().substring(0, 19);
      case typeTime:
        final d = Duration(seconds: value as int);
        final s = '${d.inHours.toStringAsFixed(2).padLeft(2, '0')}:'
            '${(d.inMinutes % 3600).toStringAsFixed(2).padLeft(2, '0')}:'
            '${(d.inSeconds % 60).toStringAsFixed(2).padLeft(2, '0')}';
        return s;
      case typeBlob:
        return 'TODO:';
      default:
        return value.toString();
    }
    return value.toString();
  }
}

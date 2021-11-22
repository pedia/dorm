///
class Flag {
  int value;
  final int mask;

  Flag(this.value, [this.mask = 0xffffffff]) : assert(value < mask);

  bool has(int f) => value & f == f;

  void set(int f) => value |= f;

  void unset(int f) => value &= ~f;

  @override
  bool operator ==(Object other) => other is Flag && value == other.value;

  @override
  int get hashCode => Object.hash(Flag, value);

  @override
  String toString() =>
      '0x${value.toRadixString(16)} 0b${value.toRadixString(2)}';

  final Map<String, int> _items = <String, int>{};

  Map<String, int> get items {
    if (_items.isEmpty) {}
    return _items;
  }

  Set<String> get setted =>
      items.entries.where((e) => has(e.value)).map((e) => e.key).toSet();
}

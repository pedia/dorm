part of dorm;

///
/// Helper function, extract all [Field] from members of [Model].
/// fieldsOf(Model)
List<Field> fieldsOf(Type type) => reflectClass(type)
    .declarations
    .entries
    .map((e) => _NamedVariable(e.key, e.value))
    .map((nv) => nv.extract())
    .where((nv) => nv != null)
    .toList()
    .cast<Field>();

///
/// Helper function, construct [Table] from annotation and [Model].
/// tableOf(Model)
Table? tableOf(Type type) {
  final rc = reflectClass(type);

  if (rc.metadata.first.hasReflectee) {
    return Table(
      base: rc.metadata.first.reflectee,
      fields: fieldsOf(type),
    );
  }
}

/// Help extract [type], symbol(instance name) from [declarations].
/// Move into model_impl.dart
class _NamedVariable {
  final Symbol symbol;
  final DeclarationMirror mirror;

  const _NamedVariable(this.symbol, this.mirror);

  Field? extract() {
    if (mirror is VariableMirror) {
      final vm = mirror as VariableMirror;
      if (vm.metadata.isNotEmpty &&
          vm.metadata.first.hasReflectee && // ?
          !vm.isStatic &&
          !vm.isConst &&
          !vm.isExtensionMember) {
        return Field(
          symbol: symbol,
          type: vm.type as ClassMirror,
          base: vm.metadata.first.reflectee,
        );
      }
    }
  }
}

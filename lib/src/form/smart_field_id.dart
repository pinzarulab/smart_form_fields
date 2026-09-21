import 'package:flutter/foundation.dart';

/// A reusable, typed identity for one smart form field.
@immutable
final class SmartFieldId<T> {
  /// Creates a typed field identifier.
  const SmartFieldId(this.name)
    : assert(name.length > 0, 'A field id name cannot be empty.');

  /// Name used for registration, API errors, drafts, and JSON values.
  final String name;

  @override
  bool operator ==(Object other) =>
      other is SmartFieldId<Object?> && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'SmartFieldId<$T>($name)';
}

/// Resolves either a legacy string name or a typed [SmartFieldId].
String smartFieldName(Object field) {
  if (field is String && field.isNotEmpty) {
    return field;
  }
  if (field is SmartFieldId<Object?>) {
    return field.name;
  }
  throw ArgumentError.value(
    field,
    'field',
    'Expected a non-empty String or SmartFieldId.',
  );
}

import 'dart:collection';

import 'smart_field_id.dart';

/// An immutable snapshot produced by validating a smart form.
class SmartFormResult {
  /// Creates an immutable validation result from the supplied snapshots.
  SmartFormResult({
    required this.isValid,
    required Map<String, Object?> values,
    required Map<String, String> errors,
    this.firstInvalidFieldName,
  }) : values = UnmodifiableMapView(Map<String, Object?>.of(values)),
       errors = UnmodifiableMapView(Map<String, String>.of(errors));

  /// Whether every enabled field passed validation.
  final bool isValid;

  /// Values captured when validation completed.
  final Map<String, Object?> values;

  /// Validation errors keyed by field name.
  final Map<String, String> errors;

  /// Name of the first invalid field in form order, when invalid.
  final String? firstInvalidFieldName;

  /// Whether a value for [name] exists in this result.
  bool contains(String name) => values.containsKey(name);

  /// Whether a typed [field] exists in this result.
  bool containsField<T>(SmartFieldId<T> field) => contains(field.name);

  /// Returns field [name] as [T], or null when its value is null.
  ///
  /// Throws an [ArgumentError] for an unknown field and a [StateError] when a
  /// non-null value does not have the requested type.
  T? valueOf<T>(String name) {
    if (!values.containsKey(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'No field with this name exists in the form result.',
      );
    }
    final value = values[name];
    if (value == null) {
      return null;
    }
    if (value is! T) {
      throw StateError(
        'Field "$name" contains ${value.runtimeType}, not the requested type '
        '$T.',
      );
    }
    return value as T;
  }

  /// Returns the value for a typed [field].
  T? valueFor<T>(SmartFieldId<T> field) => valueOf<T>(field.name);

  /// Returns the error for [field], or null when valid or unknown.
  String? errorOf(Object field) => errors[smartFieldName(field)];

  /// Decodes this valid result with [decoder].
  T? decode<T>(T Function(SmartFormResult result) decoder) =>
      isValid ? decoder(this) : null;

  /// Returns the text value for [name], or null when the value is null.
  ///
  /// This is intended for text-based fields. It throws a [StateError] when the
  /// value exists but is not a [String], so parsed values such as phone objects
  /// stay explicit.
  String? maybeText(String name) => valueOf<String>(name);

  /// Returns the text value for [name], or [fallback] when the value is null.
  String text(String name, {String fallback = ''}) =>
      maybeText(name) ?? fallback;
}

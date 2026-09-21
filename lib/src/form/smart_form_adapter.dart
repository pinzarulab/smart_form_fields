import 'dart:collection';

import 'smart_field_id.dart';
import 'smart_form_result.dart';

/// Converts between application models and smart form values.
final class SmartFormAdapter<T> {
  /// Creates a bidirectional model adapter.
  const SmartFormAdapter({required this.fromValues, required this.toValues});

  /// Builds an application model from read-only values.
  final T Function(SmartFormValues values) fromValues;

  /// Converts an application model into field values.
  final Map<Object, Object?> Function(T model) toValues;

  /// Decodes a validation [result].
  T decode(SmartFormResult result) =>
      fromValues(SmartFormValues(result.values));

  /// Encodes [model] using names from strings or typed field IDs.
  Map<String, Object?> encode(T model) {
    return <String, Object?>{
      for (final entry in toValues(model).entries)
        smartFieldName(entry.key): entry.value,
    };
  }
}

/// Read-only, typed access to a form value snapshot.
final class SmartFormValues {
  /// Creates an immutable value view.
  SmartFormValues(Map<String, Object?> values)
    : _values = UnmodifiableMapView(Map<String, Object?>.of(values));

  final Map<String, Object?> _values;

  /// Raw immutable values for interoperability.
  Map<String, Object?> get raw => _values;

  /// Whether [field] exists.
  bool contains(Object field) => _values.containsKey(smartFieldName(field));

  /// Reads a value using a typed field identifier.
  T? get<T>(SmartFieldId<T> field) => valueOf<T>(field.name);

  /// Reads a value using a legacy field name.
  T? valueOf<T>(String name) {
    if (!_values.containsKey(name)) {
      throw ArgumentError.value(name, 'name', 'Unknown form field.');
    }
    final value = _values[name];
    if (value == null) {
      return null;
    }
    if (value is! T) {
      throw StateError('Field "$name" contains ${value.runtimeType}, not $T.');
    }
    return value as T;
  }
}

/// A raw form result optionally decoded into [T].
final class SmartTypedFormResult<T> {
  /// Creates a typed result.
  const SmartTypedFormResult({required this.result, required this.value});

  /// Underlying validation result.
  final SmartFormResult result;

  /// Decoded model. Null when [result] is invalid.
  final T? value;

  /// Whether validation succeeded and [value] is available.
  bool get isValid => result.isValid;
}

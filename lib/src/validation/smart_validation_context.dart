import 'dart:collection';

import '../localization/smart_form_messages.dart';
import '../form/smart_field_id.dart';

/// Read-only form values available while a dependent validator runs.
final class SmartValidationContext {
  /// Creates an immutable validation snapshot from [values].
  SmartValidationContext(
    Map<String, Object?> values, {
    this.messages = const SmartDefaultFormMessages(),
  }) : values = UnmodifiableMapView(Map<String, Object?>.of(values));

  /// Values keyed by registered field name at validation start.
  final Map<String, Object?> values;

  /// Application-owned messages used by built-in validators.
  final SmartFormMessages messages;

  /// Returns field [name] as [T], or null when its value is null.
  ///
  /// Throws an [ArgumentError] for an unknown field and a [StateError] when a
  /// non-null value does not have the requested type.
  T? valueOf<T>(String name) {
    if (!values.containsKey(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'No field with this name exists in the validation context.',
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
}

/// A synchronous validator that can read other form values through [context].
typedef SmartContextValidator<T> =
    String? Function(T? value, SmartValidationContext context);

/// An asynchronous validator that can read form values through [context].
typedef SmartContextAsyncValidator<T> =
    Future<String?> Function(T? value, SmartValidationContext context);

/// Cooperative cancellation and form values for async validation work.
final class SmartAsyncValidationContext {
  /// Creates async validation context.
  const SmartAsyncValidationContext({
    required this.form,
    required this._isCurrent,
  });

  /// Read-only form values and message resolver.
  final SmartValidationContext form;

  final bool Function() _isCurrent;

  /// Whether a newer value/validation has superseded this request.
  bool get isCancelled => !_isCurrent();

  /// Throws when this request is no longer current.
  void throwIfCancelled() {
    if (isCancelled) {
      throw const SmartAsyncValidationCancelled();
    }
  }
}

/// Cooperative cancellation marker for application validators.
final class SmartAsyncValidationCancelled implements Exception {
  /// Creates the cancellation marker.
  const SmartAsyncValidationCancelled();
}

/// Async validator with cancellation and read-only form context.
typedef SmartControlledAsyncValidator<T> =
    Future<String?> Function(T? value, SmartAsyncValidationContext context);

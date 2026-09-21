import 'smart_validator.dart';
import 'smart_validation_context.dart';
import 'smart_validator_metadata.dart';
import '../form/smart_field_id.dart';

/// String-first factories for commonly used synchronous validators.
///
/// Validators other than [required] allow `null` and blank strings. Add a
/// [required] validator first when a field must contain a value.
abstract final class SmartValidators {
  /// Creates a string validator with explicit [dependsOn] metadata.
  static SmartValidator dependent({
    required Iterable<String> dependsOn,
    required SmartContextValidator<String> validator,
  }) {
    return SmartValueValidators.dependent<String>(
      dependsOn: dependsOn,
      validator: validator,
    );
  }

  /// Requires a non-empty string to equal another form [field].
  static SmartValidator matchesField(Object field, {String? message}) {
    return SmartValueValidators.matchesField<String>(field, message: message);
  }

  /// Requires this string when another [field] equals [equals].
  static SmartValidator requiredWhen({
    required Object field,
    required Object? equals,
    String? message,
  }) {
    return SmartValueValidators.requiredWhen<String>(
      field: field,
      equals: equals,
      message: message,
    );
  }

  /// Requires a non-null, non-empty string.
  static SmartValidator required({String? message}) =>
      SmartValueValidators.required<String>(message: message);

  /// Requires a syntactically plausible email address when present.
  static SmartValidator email({String? message}) =>
      SmartValueValidators.email(message: message);

  /// Requires a string to contain exactly [expected] characters.
  static SmartValidator length(int expected, {String? message}) {
    return SmartValueValidators.length<String>(expected, message: message);
  }

  /// Requires a string to contain at least [minimum] characters.
  static SmartValidator minLength(int minimum, {String? message}) {
    return SmartValueValidators.minLength<String>(minimum, message: message);
  }

  /// Requires a string to contain at most [maximum] characters.
  static SmartValidator maxLength(int maximum, {String? message}) {
    return SmartValueValidators.maxLength<String>(maximum, message: message);
  }

  /// Requires a string to match [pattern] when present.
  static SmartValidator pattern(Pattern pattern, {String? message}) =>
      SmartValueValidators.pattern(pattern, message: message);

  /// Requires a string to contain a finite number.
  static SmartValidator number({String? message}) {
    return SmartValueValidators.number<String>(message: message);
  }

  /// Requires a numeric string greater than or equal to [minimum].
  static SmartValidator min(num minimum, {String? message}) {
    return SmartValueValidators.min<String>(minimum, message: message);
  }

  /// Requires a numeric string less than or equal to [maximum].
  static SmartValidator max(num maximum, {String? message}) {
    return SmartValueValidators.max<String>(maximum, message: message);
  }
}

/// Generic validator factories for typed dropdowns, dates, and custom fields.
abstract final class SmartValueValidators {
  /// Creates a validator with explicit [dependsOn] metadata.
  ///
  /// Every field read from [SmartValidationContext] should appear in
  /// [dependsOn] so source changes can automatically revalidate this field.
  static SmartValueValidator<T> dependent<T>({
    required Iterable<String> dependsOn,
    required SmartContextValidator<T> validator,
  }) {
    return createDependentValidator<T>(
      dependsOn: dependsOn,
      validator: validator,
    );
  }

  /// Requires a non-empty value to equal another form [field].
  ///
  /// Empty values are allowed; add [required] when confirmation is mandatory.
  static SmartValueValidator<T> matchesField<T>(
    Object field, {
    String? message,
  }) {
    final fieldName = smartFieldName(field);
    return dependent<T>(
      dependsOn: <String>[fieldName],
      validator: (value, context) {
        if (_isEmpty(value)) {
          return null;
        }
        return value == context.values[fieldName]
            ? null
            : message ?? context.messages.valuesDoNotMatch;
      },
    );
  }

  /// Requires this value when another [field] equals [equals].
  static SmartValueValidator<T> requiredWhen<T>({
    required Object field,
    required Object? equals,
    String? message,
  }) {
    final fieldName = smartFieldName(field);
    return dependent<T>(
      dependsOn: <String>[fieldName],
      validator: (value, context) {
        if (context.values[fieldName] != equals) {
          return null;
        }
        return _isEmpty(value) ? message ?? context.messages.required : null;
      },
    );
  }

  /// Requires a non-null, non-empty value.
  ///
  /// Strings containing only whitespace and empty iterables or maps are
  /// considered empty.
  static SmartValueValidator<T> required<T>({String? message}) {
    return createContextValidator<T>(
      (value, context) =>
          _isEmpty(value) ? message ?? context.messages.required : null,
    );
  }

  /// Requires a syntactically plausible email address when a value is present.
  static SmartValidator email({String? message}) {
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return createContextValidator<String>((value, context) {
      final normalized = value?.trim();
      if (normalized == null || normalized.isEmpty) {
        return null;
      }
      return pattern.hasMatch(normalized)
          ? null
          : message ?? context.messages.invalidEmail;
    });
  }

  /// Requires a string or collection to contain exactly [expected] items.
  static SmartValueValidator<T> length<T>(int expected, {String? message}) {
    _checkLength(expected, 'expected');
    return createContextValidator<T>((value, context) {
      if (_isEmpty(value)) {
        return null;
      }
      return _lengthOf(value) == expected
          ? null
          : message ?? context.messages.exactLength(expected);
    });
  }

  /// Requires a string or collection to contain at least [minimum] items.
  static SmartValueValidator<T> minLength<T>(int minimum, {String? message}) {
    _checkLength(minimum, 'minimum');
    return createContextValidator<T>((value, context) {
      if (_isEmpty(value)) {
        return null;
      }
      final length = _lengthOf(value);
      return length != null && length >= minimum
          ? null
          : message ?? context.messages.minimumLength(minimum);
    });
  }

  /// Requires a string or collection to contain at most [maximum] items.
  static SmartValueValidator<T> maxLength<T>(int maximum, {String? message}) {
    _checkLength(maximum, 'maximum');
    return createContextValidator<T>((value, context) {
      if (_isEmpty(value)) {
        return null;
      }
      final length = _lengthOf(value);
      return length != null && length <= maximum
          ? null
          : message ?? context.messages.maximumLength(maximum);
    });
  }

  /// Requires a string to match [pattern] when a value is present.
  static SmartValidator pattern(Pattern pattern, {String? message}) {
    return createContextValidator<String>((value, context) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return pattern.allMatches(value).isNotEmpty
          ? null
          : message ?? context.messages.invalidPattern;
    });
  }

  /// Requires a value to be a finite number.
  ///
  /// Numeric values and strings accepted by [num.tryParse] are supported.
  static SmartValueValidator<T> number<T>({String? message}) {
    return createContextValidator<T>((value, context) {
      if (_isEmpty(value)) {
        return null;
      }
      return _numberOf(value) == null
          ? message ?? context.messages.invalidNumber
          : null;
    });
  }

  /// Requires a numeric value greater than or equal to [minimum].
  static SmartValueValidator<T> min<T>(num minimum, {String? message}) {
    return createContextValidator<T>((value, context) {
      if (_isEmpty(value)) {
        return null;
      }
      final number = _numberOf(value);
      return number != null && number >= minimum
          ? null
          : message ?? context.messages.minimumNumber(minimum);
    });
  }

  /// Requires a numeric value less than or equal to [maximum].
  static SmartValueValidator<T> max<T>(num maximum, {String? message}) {
    return createContextValidator<T>((value, context) {
      if (_isEmpty(value)) {
        return null;
      }
      final number = _numberOf(value);
      return number != null && number <= maximum
          ? null
          : message ?? context.messages.maximumNumber(maximum);
    });
  }

  static bool _isEmpty(Object? value) {
    return value == null ||
        value is String && value.trim().isEmpty ||
        value is Iterable<Object?> && value.isEmpty ||
        value is Map<Object?, Object?> && value.isEmpty;
  }

  static int? _lengthOf(Object? value) {
    return switch (value) {
      String value => value.length,
      Iterable<Object?> value => value.length,
      Map<Object?, Object?> value => value.length,
      _ => null,
    };
  }

  static num? _numberOf(Object? value) {
    final number = switch (value) {
      num value => value,
      String value => num.tryParse(value.trim()),
      _ => null,
    };
    return number != null && number.isFinite ? number : null;
  }

  static void _checkLength(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'Must not be negative.');
    }
  }
}

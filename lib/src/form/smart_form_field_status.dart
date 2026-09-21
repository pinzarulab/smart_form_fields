/// Origin of the current field error.
enum SmartFieldErrorSource {
  /// Produced by a synchronous or asynchronous validator.
  validation,

  /// Injected from an API or application command.
  server,
}

/// Controls how programmatic value changes affect interaction state.
final class SmartValueUpdateOptions {
  /// Creates value-update behavior.
  const SmartValueUpdateOptions({
    this.markDirty = true,
    this.markTouched = true,
    this.clearError = true,
    this.validate = false,
    this.autovalidate = true,
    this.updateInitialValue = false,
  });

  /// Standard user-like programmatic patch behavior.
  static const patch = SmartValueUpdateOptions();

  /// Initial-data behavior for API-loaded edit forms.
  static const initial = SmartValueUpdateOptions(
    markDirty: false,
    markTouched: false,
    updateInitialValue: true,
    autovalidate: false,
  );

  /// Whether changed fields become dirty.
  final bool markDirty;

  /// Whether changed fields become touched.
  final bool markTouched;

  /// Whether an existing field error is cleared.
  final bool clearError;

  /// Whether validation runs after the update.
  final bool validate;

  /// Whether normal field autovalidation policy may run after the update.
  final bool autovalidate;

  /// Whether the new value becomes the reset baseline.
  final bool updateInitialValue;
}

/// Immutable runtime state for one registered smart form field.
final class SmartFormFieldStatus {
  /// Creates a field-status snapshot.
  const SmartFormFieldStatus({
    required this.name,
    required this.value,
    required this.enabled,
    required this.excludeFromDraft,
    required this.isDirty,
    required this.isValid,
    required this.isValidating,
    required this.errorText,
    this.isTouched = false,
    this.hasValidated = false,
    this.readOnly = false,
    this.errorSource,
  });

  /// Registered field name.
  final String name;

  /// Current live field value.
  final Object? value;

  /// Whether the field participates in validation.
  final bool enabled;

  /// Whether this field should be omitted from persisted drafts.
  final bool excludeFromDraft;

  /// Whether the field changed since its last reset.
  final bool isDirty;

  /// Whether the field currently has no validation error.
  final bool isValid;

  /// Whether asynchronous validation is currently running.
  final bool isValidating;

  /// Current validation or server error.
  final String? errorText;

  /// Whether the field has been interacted with or explicitly validated.
  final bool isTouched;

  /// Whether validation has run at least once.
  final bool hasValidated;

  /// Whether input is locked while the value still participates in validation.
  final bool readOnly;

  /// Origin of [errorText], when available.
  final SmartFieldErrorSource? errorSource;
}

/// Typed runtime state for one field.
final class SmartFieldSnapshot<T> {
  /// Creates a typed snapshot from an untyped status.
  SmartFieldSnapshot.fromStatus(SmartFormFieldStatus status)
    : name = status.name,
      value = _typedValue<T>(status),
      enabled = status.enabled,
      readOnly = status.readOnly,
      excludeFromDraft = status.excludeFromDraft,
      isDirty = status.isDirty,
      isTouched = status.isTouched,
      hasValidated = status.hasValidated,
      isValid = status.isValid,
      isValidating = status.isValidating,
      errorText = status.errorText,
      errorSource = status.errorSource;

  /// Field name.
  final String name;

  /// Typed live value.
  final T? value;

  /// Whether validation participates.
  final bool enabled;

  /// Whether user input is locked.
  final bool readOnly;

  /// Whether draft persistence omits the field.
  final bool excludeFromDraft;

  /// Whether value differs from its baseline.
  final bool isDirty;

  /// Whether field has been touched.
  final bool isTouched;

  /// Whether validation has run.
  final bool hasValidated;

  /// Whether field has no error.
  final bool isValid;

  /// Whether asynchronous validation is running.
  final bool isValidating;

  /// Current error.
  final String? errorText;

  /// Current error origin.
  final SmartFieldErrorSource? errorSource;

  @override
  bool operator ==(Object other) {
    return other is SmartFieldSnapshot<T> &&
        other.name == name &&
        other.value == value &&
        other.enabled == enabled &&
        other.readOnly == readOnly &&
        other.excludeFromDraft == excludeFromDraft &&
        other.isDirty == isDirty &&
        other.isTouched == isTouched &&
        other.hasValidated == hasValidated &&
        other.isValid == isValid &&
        other.isValidating == isValidating &&
        other.errorText == errorText &&
        other.errorSource == errorSource;
  }

  @override
  int get hashCode => Object.hash(
    name,
    value,
    enabled,
    readOnly,
    excludeFromDraft,
    isDirty,
    isTouched,
    hasValidated,
    isValid,
    isValidating,
    errorText,
    errorSource,
  );
}

T? _typedValue<T>(SmartFormFieldStatus status) {
  final value = status.value;
  if (value == null) {
    return null;
  }
  if (value is! T) {
    throw StateError(
      'Field "${status.name}" contains ${value.runtimeType}, not $T.',
    );
  }
  return value as T;
}

import 'package:flutter/foundation.dart';

import 'dart:async';

import 'smart_api_errors.dart';
import 'smart_field_id.dart';
import 'smart_form_adapter.dart';
import 'smart_form_field_status.dart';
import 'smart_form_result.dart';
import 'smart_submission.dart';

/// Called after a form validates successfully during submission.
typedef SmartFormSubmitCallback =
    FutureOr<void> Function(Map<String, Object?> values);

/// Internal command surface implemented by a mounted smart form.
abstract interface class SmartFormControllerDelegate {
  /// Current values keyed by field name.
  Map<String, Object?> get values;

  /// Current state keyed by field name.
  Map<String, SmartFormFieldStatus> get fieldStatuses;

  /// Registers an observer for form value and status changes.
  void addFormListener(VoidCallback listener);

  /// Removes a previously registered observer.
  void removeFormListener(VoidCallback listener);

  /// Reads a typed field value.
  T? valueOf<T>(String name);

  /// Validates the form.
  Future<SmartFormResult> validate({
    bool? scrollToError,
    bool? focusFirstError,
  });

  /// Validates one named field.
  Future<bool> validateField(String name);

  /// Validates only the supplied registered fields.
  Future<SmartFormResult> validateFields(
    Iterable<String> names, {
    bool? scrollToError,
    bool? focusFirstError,
  });

  /// Names belonging to a named form section.
  Iterable<String> sectionFields(String name);

  /// Restores one field to its initial value.
  void resetField(String name);

  /// Clears one field's error.
  void clearFieldError(String name);

  /// Moves to the next enabled writable field in widget order.
  Future<void> focusNext({bool wrap = false});

  /// Validates the form and runs its submit callback when valid.
  Future<SmartFormResult> submit({bool? scrollToError, bool? focusFirstError});

  /// Runs the configured callback for an already valid [result].
  Future<SmartSubmissionResult> performSubmit(SmartFormResult result);

  /// Changes one field value.
  void setValue<T>(String name, T? value, {SmartValueUpdateOptions options});

  /// Changes multiple field values atomically.
  void patchValue(
    Map<String, Object?> values, {
    SmartValueUpdateOptions options,
  });

  /// Resets every field.
  void reset();

  /// Clears every field error.
  void clearErrors();

  /// Applies one field error.
  void setFieldError(String name, String error);

  /// Applies multiple field errors.
  Future<void> setErrors(Map<String, String> errors, {bool scrollToFirstError});

  /// Parses and applies field errors from a complete API response.
  Future<SmartApiErrorResult> setErrorsFromResponse(
    Object? response, {
    SmartApiErrorExtractor? extractor,
    Map<String, String> fieldAliases,
    String messageSeparator,
    bool clearExistingErrors,
    bool scrollToFirstError,
  });

  /// Reveals and focuses a field.
  Future<void> focusField(String name);

  /// Reveals a field without focusing it.
  Future<void> scrollToField(String name);
}

/// Imperative access to a mounted smart form.
final class SmartFormController extends ChangeNotifier {
  SmartFormControllerDelegate? _delegate;
  final Map<String, _SmartFieldAccessorBase> _fieldAccessors =
      <String, _SmartFieldAccessorBase>{};
  bool _disposed = false;
  bool _isSubmitting = false;
  Future<SmartFormSubmitResult>? _activeSubmission;
  SmartFormResult? _lastSubmitResult;
  Object? _submissionError;
  SmartSubmissionPhase _submissionPhase = SmartSubmissionPhase.idle;
  SmartSubmissionResult? _lastSubmissionOutcome;
  List<String> _submissionGeneralErrors = const <String>[];

  /// Whether this controller is attached to a mounted form.
  bool get isAttached => _delegate != null;

  /// Whether a submit call is currently validating or running `onSubmit`.
  bool get isSubmitting => _isSubmitting;

  /// Last validation result produced by [submit], when available.
  SmartFormResult? get lastSubmitResult => _lastSubmitResult;

  /// Last error thrown by the form submit callback.
  Object? get submissionError => _submissionError;

  /// Current structured submission phase.
  SmartSubmissionPhase get submissionPhase => _submissionPhase;

  /// Last structured application submission outcome.
  SmartSubmissionResult? get lastSubmissionOutcome => _lastSubmissionOutcome;

  /// Last fieldless backend/application messages.
  List<String> get submissionGeneralErrors => _submissionGeneralErrors;

  /// Returns an immutable snapshot of current registered field values.
  Map<String, Object?> get values => _requireDelegate().values;

  /// Returns immutable runtime state for every registered field.
  Map<String, SmartFormFieldStatus> get fieldStatuses =>
      _requireDelegate().fieldStatuses;

  /// Names of fields changed since their last reset.
  Set<String> get dirtyFields => <String>{
    for (final status in fieldStatuses.values)
      if (status.isDirty) status.name,
  };

  /// Whether at least one field has changed since reset.
  bool get isDirty => dirtyFields.isNotEmpty;

  /// Names of fields currently running asynchronous validation.
  Set<String> get validatingFields => <String>{
    for (final status in fieldStatuses.values)
      if (status.isValidating) status.name,
  };

  /// Whether any field is currently running asynchronous validation.
  bool get isValidating => validatingFields.isNotEmpty;

  /// Whether any enabled field currently has an error.
  bool get hasErrors =>
      isAttached && fieldStatuses.values.any((s) => s.enabled && !s.isValid);

  /// Whether every enabled field has completed validation.
  bool get hasValidated =>
      isAttached &&
      fieldStatuses.values
          .where((s) => s.enabled)
          .every((s) => s.hasValidated && !s.isValidating);

  /// Whether all enabled fields have passed completed validation.
  bool get isValid => hasValidated && !hasErrors;

  /// Whether a known-valid form can begin a new submission.
  bool get canSubmit => isAttached && !isSubmitting && !isValidating && isValid;

  /// Returns field [name] as [T], or null when its value is null.
  T? valueOf<T>(String name) => _requireDelegate().valueOf<T>(name);

  /// Returns the value for a typed [field].
  T? valueFor<T>(SmartFieldId<T> field) => valueOf<T>(field.name);

  /// Returns a stable typed accessor for [field].
  SmartFieldAccessor<T> field<T>(SmartFieldId<T> field) {
    final existing = _fieldAccessors[field.name];
    if (existing != null) {
      if (existing.valueType != T) {
        throw StateError(
          'Field "${field.name}" was already accessed as '
          '${existing.valueType}, not $T.',
        );
      }
      return existing as SmartFieldAccessor<T>;
    }
    final accessor = SmartFieldAccessor<T>._(this, field);
    _fieldAccessors[field.name] = accessor;
    return accessor;
  }

  /// Validates every enabled field and optionally navigates to the first error.
  Future<SmartFormResult> validate({
    bool? scrollToError,
    bool? focusFirstError,
  }) {
    return _requireDelegate().validate(
      scrollToError: scrollToError,
      focusFirstError: focusFirstError,
    );
  }

  /// Validates and decodes a successful result with [adapter].
  Future<SmartTypedFormResult<T>> validateAs<T>(
    SmartFormAdapter<T> adapter, {
    bool? scrollToError,
    bool? focusFirstError,
  }) async {
    final result = await validate(
      scrollToError: scrollToError,
      focusFirstError: focusFirstError,
    );
    return SmartTypedFormResult<T>(
      result: result,
      value: result.isValid ? adapter.decode(result) : null,
    );
  }

  /// Validates one named field immediately.
  Future<bool> validateField(String name) {
    return _requireDelegate().validateField(name);
  }

  /// Validates a subset, accepting names or typed field IDs.
  Future<SmartFormResult> validateFields(
    Iterable<Object> fields, {
    bool? scrollToError,
    bool? focusFirstError,
  }) => _requireDelegate().validateFields(
    fields.map(smartFieldName),
    scrollToError: scrollToError,
    focusFirstError: focusFirstError,
  );

  /// Validates all mounted fields in [section].
  Future<SmartFormResult> validateSection(
    String section, {
    bool? scrollToError,
    bool? focusFirstError,
  }) => validateFields(
    _requireDelegate().sectionFields(section),
    scrollToError: scrollToError,
    focusFirstError: focusFirstError,
  );

  /// Resets one field, accepting a name or typed ID.
  void resetField(Object field) =>
      _requireDelegate().resetField(smartFieldName(field));

  /// Clears one field error.
  void clearFieldError(Object field) =>
      _requireDelegate().clearFieldError(smartFieldName(field));

  /// Focuses the next enabled writable field; optionally wraps to the first.
  Future<void> focusNext({bool wrap = false}) =>
      _requireDelegate().focusNext(wrap: wrap);

  /// Validates the form, prevents duplicate concurrent submissions, and runs
  /// `SmartForm.onSubmit` when the form is valid.
  Future<SmartFormSubmitResult> submit({
    bool? scrollToError,
    bool? focusFirstError,
  }) {
    final active = _activeSubmission;
    if (active != null) {
      return active;
    }
    final completer = Completer<SmartFormSubmitResult>();
    _activeSubmission = completer.future;
    unawaited(
      _submit(
        scrollToError: scrollToError,
        focusFirstError: focusFirstError,
      ).then(completer.complete, onError: completer.completeError),
    );
    return completer.future;
  }

  /// Changes the value of field [name].
  void setValue<T>(
    String name,
    T? value, {
    SmartValueUpdateOptions options = SmartValueUpdateOptions.patch,
  }) {
    _requireDelegate().setValue<T>(name, value, options: options);
  }

  /// Changes a typed [field] value.
  void setFieldValue<T>(
    SmartFieldId<T> field,
    T? value, {
    SmartValueUpdateOptions options = SmartValueUpdateOptions.patch,
  }) {
    setValue<T>(field.name, value, options: options);
  }

  /// Changes multiple field values after validating every supplied name.
  void patchValue(
    Map<String, Object?> values, {
    SmartValueUpdateOptions options = SmartValueUpdateOptions.patch,
  }) {
    _requireDelegate().patchValue(values, options: options);
  }

  /// Loads API/model values as a clean reset baseline.
  void setInitialValues(
    Map<String, Object?> values, {
    bool preserveDirtyFields = false,
  }) {
    patchValue(<String, Object?>{
      for (final entry in values.entries)
        if (!preserveDirtyFields || fieldStatuses[entry.key]?.isDirty != true)
          entry.key: entry.value,
    }, options: SmartValueUpdateOptions.initial);
  }

  /// Loads [model] as a clean reset baseline through [adapter].
  void setInitialModel<T>(
    T model,
    SmartFormAdapter<T> adapter, {
    bool preserveDirtyFields = false,
  }) {
    setInitialValues(
      adapter.encode(model),
      preserveDirtyFields: preserveDirtyFields,
    );
  }

  /// Restores every field to its initial value and clears its state.
  void reset() => _requireDelegate().reset();

  /// Clears all validation and server errors.
  void clearErrors() => _requireDelegate().clearErrors();

  /// Applies [error] to field [name].
  void setFieldError(String name, String error) {
    _requireDelegate().setFieldError(name, error);
  }

  /// Applies backend [errors] and optionally scrolls to the first one.
  Future<void> setErrors(
    Map<String, String> errors, {
    bool scrollToFirstError = false,
  }) {
    return _requireDelegate().setErrors(
      errors,
      scrollToFirstError: scrollToFirstError,
    );
  }

  /// Parses a complete decoded API [response] and applies matching errors.
  ///
  /// Common nested maps and error arrays are supported automatically. Use
  /// [fieldAliases] to map backend names to form names, or [extractor] for an
  /// application-specific response shape. Unmapped and general messages are
  /// returned to the caller.
  Future<SmartApiErrorResult> setErrorsFromResponse(
    Object? response, {
    SmartApiErrorExtractor? extractor,
    Map<String, String> fieldAliases = const {},
    String messageSeparator = '\n',
    bool clearExistingErrors = false,
    bool scrollToFirstError = false,
  }) {
    return _requireDelegate().setErrorsFromResponse(
      response,
      extractor: extractor,
      fieldAliases: fieldAliases,
      messageSeparator: messageSeparator,
      clearExistingErrors: clearExistingErrors,
      scrollToFirstError: scrollToFirstError,
    );
  }

  /// Scrolls to and focuses field [name].
  Future<void> focusField(String name) {
    return _requireDelegate().focusField(name);
  }

  /// Scrolls field [name] into view without changing focus.
  Future<void> scrollToField(String name) {
    return _requireDelegate().scrollToField(name);
  }

  /// Releases this controller.
  ///
  /// A form does not dispose a controller supplied by its caller.
  @override
  void dispose() {
    _delegate?.removeFormListener(_handleFormChanged);
    for (final accessor in _fieldAccessors.values) {
      accessor.disposeFromOwner();
    }
    _fieldAccessors.clear();
    _disposed = true;
    _delegate = null;
    super.dispose();
  }

  /// Attaches this controller to a mounted form delegate.
  ///
  /// This is used by [SmartForm] and is not normally called by applications.
  void attach(SmartFormControllerDelegate delegate) {
    if (_disposed) {
      throw StateError('Cannot attach a disposed SmartFormController.');
    }
    if (_delegate != null && !identical(_delegate, delegate)) {
      throw StateError(
        'A SmartFormController cannot be attached to more than one SmartForm '
        'at a time.',
      );
    }
    _delegate = delegate;
    delegate.addFormListener(_handleFormChanged);
  }

  /// Detaches [delegate] when it is the currently attached form.
  ///
  /// This is used by [SmartForm] and is not normally called by applications.
  void detach(SmartFormControllerDelegate delegate) {
    if (identical(_delegate, delegate)) {
      delegate.removeFormListener(_handleFormChanged);
      _delegate = null;
    }
  }

  void _handleFormChanged() {
    for (final accessor in _fieldAccessors.values) {
      accessor.refresh();
    }
    notifyListeners();
  }

  SmartFieldSnapshot<T> _snapshot<T>(String name) {
    final status = _requireDelegate().fieldStatuses[name];
    if (status == null) {
      throw ArgumentError.value(name, 'name', 'No registered field.');
    }
    return SmartFieldSnapshot<T>.fromStatus(status);
  }

  Future<SmartFormSubmitResult> _submit({
    bool? scrollToError,
    bool? focusFirstError,
  }) async {
    _isSubmitting = true;
    _submissionError = null;
    _lastSubmissionOutcome = null;
    _submissionGeneralErrors = const <String>[];
    _submissionPhase = SmartSubmissionPhase.validating;
    notifyListeners();
    SmartFormResult? validation;
    try {
      final delegate = _requireDelegate();
      final result = await delegate.validate(
        scrollToError: scrollToError,
        focusFirstError: focusFirstError,
      );
      validation = result;
      _lastSubmitResult = result;
      if (!result.isValid) {
        _submissionPhase = SmartSubmissionPhase.invalid;
        return SmartFormSubmitResult(
          validation: result,
          phase: _submissionPhase,
        );
      }
      _submissionPhase = SmartSubmissionPhase.submitting;
      notifyListeners();
      final outcome = await delegate.performSubmit(result);
      _lastSubmissionOutcome = outcome;
      _submissionGeneralErrors = List<String>.unmodifiable(
        outcome.generalErrors,
      );
      _submissionPhase = outcome.accepted
          ? SmartSubmissionPhase.succeeded
          : SmartSubmissionPhase.rejected;
      return SmartFormSubmitResult(
        validation: result,
        phase: _submissionPhase,
        outcome: outcome,
      );
    } catch (error, stackTrace) {
      _submissionError = error;
      _submissionPhase = SmartSubmissionPhase.failed;
      return SmartFormSubmitResult(
        validation:
            validation ??
            SmartFormResult(isValid: false, values: const {}, errors: const {}),
        phase: _submissionPhase,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isSubmitting = false;
      _activeSubmission = null;
      if (!_disposed) notifyListeners();
    }
  }

  SmartFormControllerDelegate _requireDelegate() {
    if (_disposed) {
      throw StateError('This SmartFormController has been disposed.');
    }
    return _delegate ??
        (throw StateError(
          'SmartFormController is not attached to a mounted SmartForm.',
        ));
  }
}

abstract interface class _SmartFieldAccessorBase {
  Type get valueType;

  void refresh();

  void disposeFromOwner();
}

/// Typed value and state access for one registered field.
final class SmartFieldAccessor<T>
    implements ValueListenable<SmartFieldSnapshot<T>>, _SmartFieldAccessorBase {
  SmartFieldAccessor._(this._form, this.id)
    : _notifier = ValueNotifier<SmartFieldSnapshot<T>>(
        _form._snapshot<T>(id.name),
      );

  final SmartFormController _form;

  /// Typed field identity.
  final SmartFieldId<T> id;

  final ValueNotifier<SmartFieldSnapshot<T>> _notifier;

  @override
  Type get valueType => T;

  /// Current typed field state.
  @override
  SmartFieldSnapshot<T> get value => _notifier.value;

  /// Current field value.
  T? get fieldValue => value.value;

  /// Changes the current field value.
  set fieldValue(T? next) => _form.setFieldValue<T>(id, next);

  /// Changes the value with explicit interaction-state behavior.
  void setValue(
    T? next, {
    SmartValueUpdateOptions options = SmartValueUpdateOptions.patch,
  }) {
    _form.setFieldValue<T>(id, next, options: options);
  }

  /// Scrolls to and focuses this field.
  Future<void> focus() => _form.focusField(id.name);

  /// Validates this field immediately.
  Future<bool> validate() => _form.validateField(id.name);

  /// Restores this field's reset baseline.
  void reset() => _form.resetField(id);

  /// Clears this field's current error.
  void clearError() => _form.clearFieldError(id);

  /// Applies a server/application error.
  void setError(String error) => _form.setFieldError(id.name, error);

  /// Scrolls this field into view without changing focus.
  Future<void> scrollIntoView() => _form.scrollToField(id.name);

  @override
  void addListener(VoidCallback listener) => _notifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _notifier.removeListener(listener);

  @override
  void refresh() {
    if (!_form.isAttached ||
        !_form._requireDelegate().fieldStatuses.containsKey(id.name)) {
      return;
    }
    final next = _form._snapshot<T>(id.name);
    if (next != _notifier.value) {
      _notifier.value = next;
    }
  }

  @override
  void disposeFromOwner() => _notifier.dispose();
}

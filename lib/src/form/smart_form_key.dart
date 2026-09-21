import 'package:flutter/widgets.dart';

import 'smart_api_errors.dart';
import 'smart_field_id.dart';
import 'smart_form.dart';
import 'smart_form_adapter.dart';
import 'smart_form_field_status.dart';
import 'smart_form_result.dart';

/// A key that provides imperative access to a mounted [SmartForm].
final class SmartFormKey extends GlobalKey<SmartFormState> {
  /// Creates a unique key for one [SmartForm].
  // A const GlobalKey would be canonicalized and could accidentally be reused.
  // ignore: prefer_const_constructors_in_immutables
  SmartFormKey() : super.constructor();

  /// Returns an immutable snapshot of current registered field values.
  Map<String, Object?> get values => _state.values;

  /// Returns field [name] as [T], or null when its value is null.
  T? valueOf<T>(String name) => _state.valueOf<T>(name);

  /// Returns the value for a typed [field].
  T? valueFor<T>(SmartFieldId<T> field) => valueOf<T>(field.name);

  /// Validates every enabled field and optionally navigates to the first error.
  Future<SmartFormResult> validate({
    bool? scrollToError,
    bool? focusFirstError,
  }) {
    return _state.validate(
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
  Future<bool> validateField(String name) => _state.validateField(name);

  /// Changes the value of field [name].
  void setValue<T>(
    String name,
    T? value, {
    SmartValueUpdateOptions options = SmartValueUpdateOptions.patch,
  }) {
    _state.setValue<T>(name, value, options: options);
  }

  /// Changes a typed field value.
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
  }) => _state.patchValue(values, options: options);

  /// Loads values as a clean reset baseline.
  void setInitialValues(Map<String, Object?> values) {
    patchValue(values, options: SmartValueUpdateOptions.initial);
  }

  /// Loads a model as a clean reset baseline.
  void setInitialModel<T>(T model, SmartFormAdapter<T> adapter) {
    setInitialValues(adapter.encode(model));
  }

  /// Restores every field to its initial value and clears its state.
  void reset() => _state.reset();

  /// Clears all validation and server errors.
  void clearErrors() => _state.clearErrors();

  /// Applies [error] to field [name].
  void setFieldError(String name, String error) {
    _state.setFieldError(name, error);
  }

  /// Applies backend [errors] and optionally scrolls to the first one.
  Future<void> setErrors(
    Map<String, String> errors, {
    bool scrollToFirstError = false,
  }) {
    return _state.setErrors(errors, scrollToFirstError: scrollToFirstError);
  }

  /// Parses a complete decoded API [response] and applies matching errors.
  Future<SmartApiErrorResult> setErrorsFromResponse(
    Object? response, {
    SmartApiErrorExtractor? extractor,
    Map<String, String> fieldAliases = const {},
    String messageSeparator = '\n',
    bool clearExistingErrors = false,
    bool scrollToFirstError = false,
  }) {
    return _state.setErrorsFromResponse(
      response,
      extractor: extractor,
      fieldAliases: fieldAliases,
      messageSeparator: messageSeparator,
      clearExistingErrors: clearExistingErrors,
      scrollToFirstError: scrollToFirstError,
    );
  }

  /// Scrolls to and focuses field [name].
  Future<void> focusField(String name) => _state.focusField(name);

  /// Scrolls field [name] into view without changing focus.
  Future<void> scrollToField(String name) => _state.scrollToField(name);

  SmartFormState get _state {
    return currentState ??
        (throw StateError(
          'SmartFormKey is not attached to a mounted SmartForm.',
        ));
  }
}

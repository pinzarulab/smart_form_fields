// ignore_for_file: public_member_api_docs

import 'dart:ui' show Offset;

import '../validation/smart_validation_context.dart';
import 'smart_form_field_status.dart';

/// Internal contract between a smart field and its containing form.
abstract interface class SmartFieldHandle<T> {
  String get name;

  String? get section;

  bool get hasFocus;

  bool get canRequestFocus;

  T? get value;

  Future<Object?> resolveResultValue();

  bool get enabled;

  bool get readOnly;

  bool get excludeFromDraft;

  bool get includeInResult;

  bool get isValid;

  bool get isDirty;

  bool get isTouched;

  bool get hasValidated;

  bool get isValidating;

  String? get errorText;

  SmartFieldErrorSource? get errorSource;

  Set<String> get dependencies;

  Future<bool> validate({
    bool animateError = true,
    SmartValidationContext? context,
  });

  void setValue(
    T? value, {
    bool notifyDependents = true,
    SmartValueUpdateOptions options = SmartValueUpdateOptions.patch,
  });

  void dependencyDidChange(SmartValidationContext context);

  void reset();

  void clearError();

  void setError(String error, {bool animateError = true});

  void animateError();

  void focus();

  bool containsGlobalPosition(Offset position);

  Future<void> scrollIntoView();
}

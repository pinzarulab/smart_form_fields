import 'dart:async';

import 'smart_api_errors.dart';
import 'smart_form_result.dart';

/// Current stage of controller-managed submission.
enum SmartSubmissionPhase {
  /// No submission has started.
  idle,

  /// Local field validation is running.
  validating,

  /// Application submission callback is running.
  submitting,

  /// Local validation rejected submission.
  invalid,

  /// Submission completed successfully.
  succeeded,

  /// Backend/application rejected values with handled messages.
  rejected,

  /// Submission callback threw an unhandled exception.
  failed,
}

/// Structured result returned by an application submission callback.
final class SmartSubmissionResult {
  /// Creates a successful outcome.
  const SmartSubmissionResult.success()
    : accepted = true,
      response = null,
      fieldErrors = const <String, String>{},
      generalErrors = const <String>[],
      extractor = null,
      fieldAliases = const <String, String>{},
      scrollToFirstError = false;

  /// Creates a handled backend/application rejection.
  const SmartSubmissionResult.rejected({
    this.response,
    this.fieldErrors = const <String, String>{},
    this.generalErrors = const <String>[],
    this.extractor,
    this.fieldAliases = const <String, String>{},
    this.scrollToFirstError = true,
  }) : accepted = false;

  /// Whether submission was accepted.
  final bool accepted;

  /// Optional complete decoded API response to parse and apply.
  final Object? response;

  /// Already-normalized field errors.
  final Map<String, String> fieldErrors;

  /// Application-level errors not tied to one field.
  final List<String> generalErrors;

  /// Optional parser for [response].
  final SmartApiErrorExtractor? extractor;

  /// Optional backend-to-form field aliases.
  final Map<String, String> fieldAliases;

  /// Whether handled field errors navigate to the first rejected field.
  final bool scrollToFirstError;
}

/// Called with a valid snapshot and returns success or handled rejection.
typedef SmartFormResultSubmitCallback =
    FutureOr<SmartSubmissionResult> Function(SmartFormResult result);

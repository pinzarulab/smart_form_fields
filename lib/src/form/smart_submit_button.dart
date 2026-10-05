import 'package:flutter/material.dart';

import 'smart_form_controller.dart';
import 'smart_submission.dart';

/// Builds any application-owned submit control.
typedef SmartSubmitButtonBuilder =
    Widget Function(
      BuildContext context,
      SmartSubmissionPhase phase,
      VoidCallback? onPressed,
    );

/// A Material submit button connected to a [SmartFormController].
class SmartSubmitButton extends StatelessWidget {
  /// Creates a submit button that validates and submits [controller].
  const SmartSubmitButton({
    required this.controller,
    required this.child,
    this.buttonBuilder,
    this.loadingChild,
    this.enabled = true,
    this.scrollToError,
    this.focusFirstError,
    this.onSubmitted,
    this.onError,
    this.onInvalid,
    this.onRejected,
    this.style,
    super.key,
  });

  /// Creates a submit control with fully application-owned presentation.
  const SmartSubmitButton.builder({
    required this.controller,
    required SmartSubmitButtonBuilder builder,
    this.enabled = true,
    this.scrollToError,
    this.focusFirstError,
    this.onSubmitted,
    this.onError,
    this.onInvalid,
    this.onRejected,
    super.key,
  }) : child = null,
       loadingChild = null,
       style = null,
       buttonBuilder = builder;

  /// Controller attached to the target [SmartForm].
  final SmartFormController controller;

  /// Button content displayed while the form is not submitting.
  final Widget? child;

  /// Optional application-owned button/control builder.
  final SmartSubmitButtonBuilder? buttonBuilder;

  /// Button content displayed while a submission is running.
  final Widget? loadingChild;

  /// Whether the button can start a submission.
  final bool enabled;

  /// Overrides first-error scrolling for this submit action.
  final bool? scrollToError;

  /// Overrides first-error focusing for this submit action.
  final bool? focusFirstError;

  /// Called after a valid submission finishes successfully.
  final VoidCallback? onSubmitted;

  /// Called when `SmartForm.onSubmit` throws.
  final ValueChanged<Object>? onError;

  /// Called when local form validation blocks submission.
  final VoidCallback? onInvalid;

  /// Called when a structured callback returns a handled rejection.
  final ValueChanged<SmartSubmissionResult>? onRejected;

  /// Optional style for the underlying [FilledButton].
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isSubmitting = controller.isSubmitting;
        final onPressed = enabled && !isSubmitting ? _submit : null;
        final customBuilder = buttonBuilder;
        if (customBuilder != null) {
          return customBuilder(context, controller.submissionPhase, onPressed);
        }
        return FilledButton(
          style: style,
          onPressed: onPressed,
          child: isSubmitting
              ? loadingChild ?? const _SmartSubmitButtonLoadingChild()
              : child!,
        );
      },
    );
  }

  Future<void> _submit() async {
    try {
      final result = await controller.submit(
        scrollToError: scrollToError,
        focusFirstError: focusFirstError,
      );
      if (result.error != null) {
        onError?.call(result.error!);
      } else if (!result.isValid) {
        onInvalid?.call();
      } else if (result.isSuccess) {
        onSubmitted?.call();
      } else if (controller.submissionPhase == SmartSubmissionPhase.rejected) {
        final outcome = result.outcome;
        if (outcome != null) {
          onRejected?.call(outcome);
        }
      }
    } catch (error) {
      onError?.call(error);
    }
  }
}

class _SmartSubmitButtonLoadingChild extends StatelessWidget {
  const _SmartSubmitButtonLoadingChild();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

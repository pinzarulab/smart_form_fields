import 'dart:async';

import 'package:flutter/widgets.dart';

import '../animation/smart_error_animation.dart';
import '../draft/smart_form_draft.dart';
import '../fields/smart_field_view_item.dart';
import '../localization/smart_form_messages.dart';
import 'smart_form.dart';
import 'smart_form_adapter.dart';
import 'smart_form_controller.dart';
import 'smart_form_result.dart';
import 'smart_submission.dart';

/// Called with a decoded model after successful local validation.
typedef SmartModelSubmitCallback<T> = FutureOr<void> Function(T model);

/// Returns a structured submission result for a decoded model.
typedef SmartModelResultSubmitCallback<T> =
    FutureOr<SmartSubmissionResult> Function(
      T model,
      SmartFormResult rawResult,
    );

/// Typed model-binding wrapper around [SmartForm].
class SmartModelForm<T> extends StatelessWidget {
  /// Creates a form whose successful values decode into [T].
  const SmartModelForm({
    required this.adapter,
    this.children = const [],
    this.items = const [],
    this.child,
    this.controller,
    this.draftController,
    this.onSubmit,
    this.onSubmitResult,
    this.itemSeparatorHeight = 0,
    this.itemSeparatorBuilder,
    this.padding,
    this.scrollToFirstError,
    this.focusFirstError,
    this.errorAnimation,
    this.errorAnimationBuilder,
    this.onRevealField,
    this.messages,
    this.autovalidateMode = AutovalidateMode.onUnfocus,
    super.key,
  }) : assert(
         onSubmit == null || onSubmitResult == null,
         'Provide onSubmit or onSubmitResult, not both.',
       );

  /// Converts raw values to/from [T].
  final SmartFormAdapter<T> adapter;

  /// Vertically arranged widgets.
  final List<Widget> children;

  /// Declarative field items.
  final List<SmartFieldViewItem> items;

  /// Arbitrary application-owned layout.
  final Widget? child;

  /// Imperative form controller.
  final SmartFormController? controller;

  /// Optional draft lifecycle.
  final SmartFormDraftController? draftController;

  /// Simple typed submission callback.
  final SmartModelSubmitCallback<T>? onSubmit;

  /// Structured typed submission callback.
  final SmartModelResultSubmitCallback<T>? onSubmitResult;

  /// Spacing between [items].
  final double itemSeparatorHeight;

  /// Custom separator between [items].
  final SmartFormItemSeparatorBuilder? itemSeparatorBuilder;

  /// Padding around form content.
  final EdgeInsetsGeometry? padding;

  /// First-error scrolling override.
  final bool? scrollToFirstError;

  /// First-error focusing override.
  final bool? focusFirstError;

  /// Built-in error animation override.
  final SmartErrorAnimation? errorAnimation;

  /// Custom error animation override.
  final SmartErrorAnimationBuilder? errorAnimationBuilder;

  /// Container reveal hook for tabs, steps, or accordions.
  final SmartFormRevealField? onRevealField;

  /// Application-owned validation messages.
  final SmartFormMessages? messages;

  /// Default descendant validation timing.
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return SmartForm(
      children: children,
      items: items,
      child: child,
      controller: controller,
      draftController: draftController,
      itemSeparatorHeight: itemSeparatorHeight,
      itemSeparatorBuilder: itemSeparatorBuilder,
      padding: padding,
      scrollToFirstError: scrollToFirstError,
      focusFirstError: focusFirstError,
      errorAnimation: errorAnimation,
      errorAnimationBuilder: errorAnimationBuilder,
      onRevealField: onRevealField,
      messages: messages,
      autovalidateMode: autovalidateMode,
      onSubmitResult: onSubmit == null && onSubmitResult == null
          ? null
          : (result) async {
              final model = adapter.decode(result);
              final structured = onSubmitResult;
              if (structured != null) {
                return structured(model, result);
              }
              await onSubmit?.call(model);
              return const SmartSubmissionResult.success();
            },
    );
  }
}

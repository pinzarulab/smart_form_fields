// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../animation/smart_error_animation.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import 'smart_conditional_field.dart';
import 'smart_date_field.dart';
import 'smart_dropdown_field.dart';
import 'smart_email_field.dart';
import 'smart_field_view_item.dart';
import 'smart_form_field.dart';
import 'smart_password_field.dart';

/// Reusable item configuration for [SmartEmailField].
final class SmartEmailFieldViewItem extends SmartFieldViewItem {
  /// Creates an email item.
  SmartEmailFieldViewItem({
    required super.name,
    String? initialValue,
    TextEditingController? controller,
    this.focusNode,
    this.required = false,
    this.requiredMessage,
    this.invalidEmailMessage,
    this.validators = const [],
    this.asyncValidators = const [],
    this.asyncValidationDebounce,
    this.autovalidateMode,
    this.errorAnimation,
    this.errorAnimationBuilder,
    this.enabled = true,
    this.readOnly = false,
    this.decoration = const InputDecoration(),
    this.textInputAction,
    this.resultValueTransformer,
    this.excludeFromDraft = false,
  }) : controller =
           controller ?? TextEditingController(text: initialValue ?? ''),
       _ownsController = controller == null;

  /// Text controller used by the built field.
  final TextEditingController controller;
  final bool _ownsController;
  final FocusNode? focusNode;
  final bool required;
  final String? requiredMessage;
  final String? invalidEmailMessage;
  final List<SmartValidator> validators;
  final List<SmartAsyncValidator<String>> asyncValidators;
  final Duration? asyncValidationDebounce;
  final AutovalidateMode? autovalidateMode;
  final SmartErrorAnimation? errorAnimation;
  final SmartErrorAnimationBuilder? errorAnimationBuilder;
  final bool enabled;
  final bool readOnly;
  final InputDecoration decoration;
  final TextInputAction? textInputAction;
  final SmartResultValueTransformer<String>? resultValueTransformer;
  final bool excludeFromDraft;

  @override
  String get text => controller.text;

  set text(String value) => controller.text = value;

  @override
  Object? get value => controller.text;

  /// Disposes an internally owned text controller.
  void dispose() {
    if (_ownsController) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => SmartEmailField(
    name: name,
    controller: controller,
    focusNode: focusNode,
    required: required,
    requiredMessage: requiredMessage,
    invalidEmailMessage: invalidEmailMessage,
    validators: validators,
    asyncValidators: asyncValidators,
    asyncValidationDebounce: asyncValidationDebounce,
    autovalidateMode: autovalidateMode,
    errorAnimation: errorAnimation,
    errorAnimationBuilder: errorAnimationBuilder,
    enabled: enabled,
    readOnly: readOnly,
    decoration: decoration,
    textInputAction: textInputAction,
    resultValueTransformer: resultValueTransformer,
    excludeFromDraft: excludeFromDraft,
  );
}

/// Reusable item configuration for [SmartPasswordField].
final class SmartPasswordFieldViewItem extends SmartFieldViewItem {
  /// Creates a password item.
  SmartPasswordFieldViewItem({
    required super.name,
    String? initialValue,
    TextEditingController? controller,
    this.focusNode,
    this.required = false,
    this.requiredMessage,
    this.minLength = 8,
    this.minLengthMessage,
    this.validators = const [],
    this.asyncValidators = const [],
    this.asyncValidationDebounce,
    this.autovalidateMode,
    this.enabled = true,
    this.readOnly = false,
    this.decoration = const InputDecoration(),
    this.showVisibilityToggle = true,
    this.excludeFromDraft = false,
  }) : controller =
           controller ?? TextEditingController(text: initialValue ?? ''),
       _ownsController = controller == null;

  final TextEditingController controller;
  final bool _ownsController;
  final FocusNode? focusNode;
  final bool required;
  final String? requiredMessage;
  final int? minLength;
  final String? minLengthMessage;
  final List<SmartValidator> validators;
  final List<SmartAsyncValidator<String>> asyncValidators;
  final Duration? asyncValidationDebounce;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final bool readOnly;
  final InputDecoration decoration;
  final bool showVisibilityToggle;
  final bool excludeFromDraft;

  @override
  String get text => controller.text;

  set text(String value) => controller.text = value;

  @override
  Object? get value => controller.text;

  /// Disposes an internally owned text controller.
  void dispose() {
    if (_ownsController) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => SmartPasswordField(
    name: name,
    controller: controller,
    focusNode: focusNode,
    required: required,
    requiredMessage: requiredMessage,
    minLength: minLength,
    minLengthMessage: minLengthMessage,
    validators: validators,
    asyncValidators: asyncValidators,
    asyncValidationDebounce: asyncValidationDebounce,
    autovalidateMode: autovalidateMode,
    enabled: enabled,
    readOnly: readOnly,
    decoration: decoration,
    showVisibilityToggle: showVisibilityToggle,
    excludeFromDraft: excludeFromDraft,
  );
}

/// Reusable item configuration for [SmartDateField].
final class SmartDateFieldViewItem extends SmartFieldViewItem {
  /// Creates a date item.
  const SmartDateFieldViewItem({
    required super.name,
    required this.firstDate,
    required this.lastDate,
    this.initialValue,
    this.focusNode,
    this.required = false,
    this.requiredMessage,
    this.validators = const [],
    this.asyncValidators = const [],
    this.asyncValidationDebounce,
    this.autovalidateMode,
    this.enabled = true,
    this.readOnly = false,
    this.decoration = const InputDecoration(),
    this.dateFormatter,
    this.resultValueTransformer,
    this.excludeFromDraft = false,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialValue;
  final FocusNode? focusNode;
  final bool required;
  final String? requiredMessage;
  final List<SmartValueValidator<DateTime>> validators;
  final List<SmartAsyncValidator<DateTime>> asyncValidators;
  final Duration? asyncValidationDebounce;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final bool readOnly;
  final InputDecoration decoration;
  final SmartDateFormatter? dateFormatter;
  final SmartResultValueTransformer<DateTime>? resultValueTransformer;
  final bool excludeFromDraft;

  @override
  Widget build(BuildContext context) => SmartDateField(
    name: name,
    firstDate: firstDate,
    lastDate: lastDate,
    initialValue: initialValue,
    focusNode: focusNode,
    required: required,
    requiredMessage: requiredMessage,
    validators: validators,
    asyncValidators: asyncValidators,
    asyncValidationDebounce: asyncValidationDebounce,
    autovalidateMode: autovalidateMode,
    enabled: enabled,
    readOnly: readOnly,
    decoration: decoration,
    dateFormatter: dateFormatter,
    resultValueTransformer: resultValueTransformer,
    excludeFromDraft: excludeFromDraft,
  );
}

/// Reusable item configuration for [SmartDropdownField].
final class SmartDropdownFieldViewItem<T> extends SmartFieldViewItem {
  /// Creates a dropdown item.
  const SmartDropdownFieldViewItem({
    required super.name,
    required this.items,
    required this.itemLabelBuilder,
    this.itemBuilder,
    this.initialValue,
    this.focusNode,
    this.required = false,
    this.requiredMessage,
    this.validators = const [],
    this.asyncValidators = const [],
    this.asyncValidationDebounce,
    this.autovalidateMode,
    this.enabled = true,
    this.readOnly = false,
    this.decoration = const InputDecoration(),
    this.resultValueTransformer,
    this.excludeFromDraft = false,
  });

  final List<T> items;
  final SmartItemLabelBuilder<T> itemLabelBuilder;
  final SmartDropdownItemBuilder<T>? itemBuilder;
  final T? initialValue;
  final FocusNode? focusNode;
  final bool required;
  final String? requiredMessage;
  final List<SmartValueValidator<T>> validators;
  final List<SmartAsyncValidator<T>> asyncValidators;
  final Duration? asyncValidationDebounce;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final bool readOnly;
  final InputDecoration decoration;
  final SmartResultValueTransformer<T>? resultValueTransformer;
  final bool excludeFromDraft;

  @override
  Widget build(BuildContext context) => SmartDropdownField<T>(
    name: name,
    items: items,
    itemLabelBuilder: itemLabelBuilder,
    itemBuilder: itemBuilder,
    initialValue: initialValue,
    focusNode: focusNode,
    required: required,
    requiredMessage: requiredMessage,
    validators: validators,
    asyncValidators: asyncValidators,
    asyncValidationDebounce: asyncValidationDebounce,
    autovalidateMode: autovalidateMode,
    enabled: enabled,
    readOnly: readOnly,
    decoration: decoration,
    resultValueTransformer: resultValueTransformer,
    excludeFromDraft: excludeFromDraft,
  );
}

/// Reusable conditional wrapper around another field item.
final class SmartConditionalFieldViewItem extends SmartFieldViewItem {
  /// Creates a conditional item using the child's field name.
  SmartConditionalFieldViewItem({
    required this.dependsOn,
    required this.condition,
    required this.child,
    this.hiddenBehavior = SmartHiddenFieldBehavior.remove,
  }) : super(name: child.name);

  final String dependsOn;
  final SmartConditionalFieldCondition condition;
  final SmartFieldViewItem child;
  final SmartHiddenFieldBehavior hiddenBehavior;

  @override
  Widget build(BuildContext context) => SmartConditionalField(
    dependsOn: dependsOn,
    condition: condition,
    hiddenBehavior: hiddenBehavior,
    child: child.build(context),
  );
}

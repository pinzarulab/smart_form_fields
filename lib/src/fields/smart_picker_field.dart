import 'dart:async';

import 'package:flutter/material.dart';

import '../animation/smart_error_animation.dart';
import '../form/smart_field_id.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import 'smart_field_controller.dart';
import 'smart_field_view_item.dart';
import 'smart_form_field.dart';

/// Opens an application-owned picker such as a bottom sheet or dialog.
typedef SmartPickerCallback<T> =
    FutureOr<T?> Function(BuildContext context, T? currentValue);

/// Explicit picker outcome: select, clear, or cancel without changing value.
final class SmartPickerResult<T> {
  /// Selects [value].
  const SmartPickerResult.selected(this.value) : isCancelled = false;

  /// Clears the existing value.
  const SmartPickerResult.cleared() : value = null, isCancelled = false;

  /// Leaves the current value unchanged.
  const SmartPickerResult.cancelled() : value = null, isCancelled = true;

  /// New value, null for a cleared or cancelled outcome.
  final T? value;

  /// Whether the operation should leave the current selection untouched.
  final bool isCancelled;
}

/// Picker callback distinguishing selection, clearing, and cancellation.
typedef SmartPickerResultCallback<T> =
    FutureOr<SmartPickerResult<T>> Function(
      BuildContext context,
      T? currentValue,
    );

/// Builds the visible picker value from current field state.
typedef SmartPickerDisplayBuilder<T> =
    Widget Function(
      BuildContext context,
      T? value,
      SmartFieldController<T> field,
    );

/// Declarative configuration for a [SmartPickerField].
final class SmartPickerFieldViewItem<T> extends SmartFieldViewItem {
  /// Creates a picker item for `SmartForm.items`.
  const SmartPickerFieldViewItem({
    required super.name,
    this.onPick,
    this.onPickResult,
    this.allowClear = false,
    this.clearTooltip = 'Clear selection',
    required this.displayBuilder,
    this.initialValue,
    this.focusNode,
    this.validators = const [],
    this.asyncValidators = const [],
    this.asyncValidationDebounce,
    this.autovalidateMode,
    this.errorAnimation,
    this.errorAnimationBuilder,
    this.enabled = true,
    this.readOnly = false,
    this.decoration = const InputDecoration(),
    this.loading,
    this.onChanged,
    this.resultValueTransformer,
    this.excludeFromDraft = false,
  }) : assert(onPick != null || onPickResult != null),
       assert(onPick == null || onPickResult == null);

  /// Initial selected value.
  final T? initialValue;

  /// Application-owned picker opener.
  final SmartPickerCallback<T>? onPick;

  /// Picker with explicit clear and cancel outcomes.
  final SmartPickerResultCallback<T>? onPickResult;

  /// Shows a clear button when a selected value exists.
  final bool allowClear;

  /// Application-localizable clear button tooltip.
  final String clearTooltip;

  /// Visible selected-value builder.
  final SmartPickerDisplayBuilder<T> displayBuilder;

  /// Optional focus node.
  final FocusNode? focusNode;

  /// Synchronous validators.
  final List<SmartValueValidator<T>> validators;

  /// Asynchronous validators.
  final List<SmartAsyncValidator<T>> asyncValidators;

  /// Automatic async-validation debounce.
  final Duration? asyncValidationDebounce;

  /// Field validation timing override.
  final AutovalidateMode? autovalidateMode;

  /// Field error animation override.
  final SmartErrorAnimation? errorAnimation;

  /// Custom error animation override.
  final SmartErrorAnimationBuilder? errorAnimationBuilder;

  /// Whether validation and interaction are enabled.
  final bool enabled;

  /// Whether selection is locked while validation remains enabled.
  final bool readOnly;

  /// Material input decoration.
  final InputDecoration decoration;

  /// Widget displayed while [onPick] is running.
  final Widget? loading;

  /// Called after a new non-null value is selected.
  final ValueChanged<T?>? onChanged;

  /// Optional submission-value transformer.
  final SmartResultValueTransformer<T>? resultValueTransformer;

  /// Whether draft persistence excludes this field.
  final bool excludeFromDraft;

  @override
  Widget build(BuildContext context) => SmartPickerField<T>(
    name: name,
    initialValue: initialValue,
    onPick: onPick,
    onPickResult: onPickResult,
    allowClear: allowClear,
    clearTooltip: clearTooltip,
    displayBuilder: displayBuilder,
    focusNode: focusNode,
    validators: validators,
    asyncValidators: asyncValidators,
    asyncValidationDebounce: asyncValidationDebounce,
    autovalidateMode: autovalidateMode,
    errorAnimation: errorAnimation,
    errorAnimationBuilder: errorAnimationBuilder,
    enabled: enabled,
    readOnly: readOnly,
    decoration: decoration,
    loading: loading,
    onChanged: onChanged,
    resultValueTransformer: resultValueTransformer,
    excludeFromDraft: excludeFromDraft,
  );
}

/// Form field whose presentation is supplied by an app-owned picker callback.
class SmartPickerField<T> extends StatefulWidget {
  /// Creates a bottom-sheet, dialog, or custom picker field.
  const SmartPickerField({
    String? name,
    this.fieldId,
    this.onPick,
    this.onPickResult,
    this.allowClear = false,
    this.clearTooltip = 'Clear selection',
    required this.displayBuilder,
    this.initialValue,
    this.focusNode,
    this.validators = const [],
    this.asyncValidators = const [],
    this.asyncValidationDebounce,
    this.autovalidateMode,
    this.errorAnimation,
    this.errorAnimationBuilder,
    this.enabled = true,
    this.readOnly = false,
    this.decoration = const InputDecoration(),
    this.loading,
    this.onChanged,
    this.resultValueTransformer,
    this.excludeFromDraft = false,
    super.key,
  }) : assert(
         (name != null && name.length > 0) || fieldId != null,
         'Provide a non-empty name or SmartFieldId.',
       ),
       assert(onPick != null || onPickResult != null),
       assert(onPick == null || onPickResult == null),
       _name = name;

  final String? _name;

  /// Optional typed field identity.
  final SmartFieldId<T>? fieldId;

  /// Unique field name.
  String get name => _name ?? fieldId!.name;

  /// Initial selected value.
  final T? initialValue;

  /// Application-owned picker opener.
  final SmartPickerCallback<T>? onPick;

  /// Picker with explicit clear and cancel outcomes.
  final SmartPickerResultCallback<T>? onPickResult;

  /// Shows a clear button alongside the current selection.
  final bool allowClear;

  /// Application-localizable clear button tooltip.
  final String clearTooltip;

  /// Visible selected-value builder.
  final SmartPickerDisplayBuilder<T> displayBuilder;

  /// Optional focus node.
  final FocusNode? focusNode;

  /// Synchronous validators.
  final List<SmartValueValidator<T>> validators;

  /// Asynchronous validators.
  final List<SmartAsyncValidator<T>> asyncValidators;

  /// Automatic async-validation debounce.
  final Duration? asyncValidationDebounce;

  /// Validation timing override.
  final AutovalidateMode? autovalidateMode;

  /// Error animation override.
  final SmartErrorAnimation? errorAnimation;

  /// Custom error animation override.
  final SmartErrorAnimationBuilder? errorAnimationBuilder;

  /// Whether validation and interaction are enabled.
  final bool enabled;

  /// Whether selection is locked while validation remains enabled.
  final bool readOnly;

  /// Material input decoration.
  final InputDecoration decoration;

  /// Widget shown while the picker callback is running.
  final Widget? loading;

  /// Called after a new value is selected.
  final ValueChanged<T?>? onChanged;

  /// Optional submission-value transformer.
  final SmartResultValueTransformer<T>? resultValueTransformer;

  /// Whether draft persistence excludes this field.
  final bool excludeFromDraft;

  @override
  State<SmartPickerField<T>> createState() => _SmartPickerFieldState<T>();
}

class _SmartPickerFieldState<T> extends State<SmartPickerField<T>> {
  bool _isPicking = false;

  Future<void> _pick(SmartFieldController<T> field) async {
    if (!field.enabled || field.readOnly || _isPicking) {
      return;
    }
    field.focusNode.requestFocus();
    setState(() => _isPicking = true);
    try {
      final original = field.value;
      final resultCallback = widget.onPickResult;
      final SmartPickerResult<T> result;
      if (resultCallback != null) {
        result = await resultCallback(context, original);
      } else {
        final selected = await widget.onPick!(context, original);
        result = selected == null
            ? const SmartPickerResult.cancelled()
            : SmartPickerResult.selected(selected);
      }
      if (mounted &&
          !result.isCancelled &&
          field.enabled &&
          !field.readOnly &&
          field.value == original) {
        field.didChange(result.value);
        widget.onChanged?.call(result.value);
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
        field.focusNode.unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartFormField<T>(
      name: widget.name,
      initialValue: widget.initialValue,
      focusNode: widget.focusNode,
      validators: widget.validators,
      asyncValidators: widget.asyncValidators,
      asyncValidationDebounce: widget.asyncValidationDebounce,
      autovalidateMode: widget.autovalidateMode,
      errorAnimation: widget.errorAnimation,
      errorAnimationBuilder: widget.errorAnimationBuilder,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      resultValueTransformer: widget.resultValueTransformer,
      excludeFromDraft: widget.excludeFromDraft,
      builder: (context, field) {
        final decoration = widget.decoration.copyWith(
          enabled: field.enabled,
          errorText: field.errorText,
          suffixIcon: widget.allowClear && field.value != null
              ? IconButton(
                  tooltip: widget.clearTooltip,
                  icon: const Icon(Icons.clear),
                  onPressed: field.enabled && !field.readOnly && !_isPicking
                      ? () {
                          field.didChange(null);
                          widget.onChanged?.call(null);
                        }
                      : null,
                )
              : widget.decoration.suffixIcon,
        );
        return Focus(
          focusNode: field.focusNode,
          child: Semantics(
            button: true,
            enabled: field.enabled && !field.readOnly,
            child: InkWell(
              onTap: field.enabled && !field.readOnly
                  ? () => _pick(field)
                  : null,
              child: InputDecorator(
                isFocused: field.focusNode.hasFocus,
                isEmpty: field.value == null,
                decoration: decoration,
                child: _isPicking
                    ? widget.loading ??
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                    : widget.displayBuilder(context, field.value, field),
              ),
            ),
          ),
        );
      },
    );
  }
}

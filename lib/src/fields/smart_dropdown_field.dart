import 'dart:async';

import 'package:flutter/material.dart';

import '../animation/smart_error_animation.dart';
import '../form/smart_field_id.dart';
import '../form/smart_form_scope.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_validators.dart';
import 'smart_field_controller.dart';
import 'smart_form_field.dart';

/// Produces the fallback text label for a dropdown item.
typedef SmartItemLabelBuilder<T> = String Function(T item);

/// Builds the widget displayed for a dropdown item.
typedef SmartDropdownItemBuilder<T> =
    Widget Function(BuildContext context, T item);

/// A Material dropdown connected to the closest [SmartForm].
class SmartDropdownField<T> extends StatefulWidget {
  /// Creates a Material dropdown registered as [name].
  const SmartDropdownField({
    String? name,
    this.fieldId,
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
    this.errorAnimation,
    this.errorAnimationBuilder,
    this.enabled = true,
    this.readOnly = false,
    this.decoration = const InputDecoration(),
    this.hint,
    this.disabledHint,
    this.isExpanded = true,
    this.menuMaxHeight,
    this.onChanged,
    this.resultValueTransformer,
    this.excludeFromDraft = false,
    super.key,
  }) : assert(
         (name != null && name.length > 0) || fieldId != null,
         'Provide a non-empty name or SmartFieldId.',
       ),
       _name = name;

  /// Unique form field name.
  final String? _name;

  /// Optional typed identity for this field.
  final SmartFieldId<T>? fieldId;

  /// Unique form field name.
  String get name => _name ?? fieldId!.name;

  /// Values available for selection.
  final List<T> items;

  /// Produces a text label for each item and selected value.
  final SmartItemLabelBuilder<T> itemLabelBuilder;

  /// Optional custom widget builder for menu items.
  final SmartDropdownItemBuilder<T>? itemBuilder;

  /// Initial selected value.
  final T? initialValue;

  /// Optional caller-owned focus node.
  final FocusNode? focusNode;

  /// Whether a null selection is invalid.
  final bool required;

  /// Message returned when [required] validation fails.
  final String? requiredMessage;

  /// Additional synchronous validators run after required validation.
  final List<SmartValueValidator<T>> validators;

  /// Asynchronous validators run after synchronous validators pass.
  final List<SmartAsyncValidator<T>> asyncValidators;

  /// Debounce applied to automatic asynchronous validation.
  final Duration? asyncValidationDebounce;

  /// Field-level automatic validation override.
  final AutovalidateMode? autovalidateMode;

  /// Field-level error animation override.
  final SmartErrorAnimation? errorAnimation;

  /// Field-level custom error animation override.
  final SmartErrorAnimationBuilder? errorAnimationBuilder;

  /// Whether the dropdown accepts input and participates in validation.
  final bool enabled;

  /// Whether selection is locked while validation remains enabled.
  final bool readOnly;

  /// Material input decoration.
  final InputDecoration decoration;

  /// Widget displayed when there is no selection.
  final Widget? hint;

  /// Widget displayed when a disabled dropdown has no selection.
  final Widget? disabledHint;

  /// Whether the dropdown fills its available horizontal space.
  final bool isExpanded;

  /// Maximum height of the dropdown menu.
  final double? menuMaxHeight;

  /// Called whenever the selected value changes.
  final ValueChanged<T?>? onChanged;

  /// Optionally transforms the selected value for submission.
  final SmartResultValueTransformer<T>? resultValueTransformer;

  /// Whether this field is omitted from persisted draft payloads.
  final bool excludeFromDraft;

  @override
  State<SmartDropdownField<T>> createState() => _SmartDropdownFieldState<T>();
}

class _SmartDropdownFieldState<T> extends State<SmartDropdownField<T>> {
  late List<SmartValueValidator<T>> _validators;
  FocusNode? _observedFocusNode;
  SmartFieldController<T>? _fieldController;
  bool _menuIsOpen = false;
  bool _menuMovedFocusToRoute = false;
  bool _validateWhenMenuCloses = false;
  int _menuSession = 0;

  @override
  void initState() {
    super.initState();
    _rebuildValidators();
  }

  @override
  void didUpdateWidget(SmartDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.required != widget.required ||
        oldWidget.requiredMessage != widget.requiredMessage ||
        !identical(oldWidget.validators, widget.validators)) {
      _rebuildValidators();
    }
  }

  @override
  void dispose() {
    _observedFocusNode?.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _rebuildValidators() {
    _validators = <SmartValueValidator<T>>[
      if (widget.required)
        SmartValueValidators.required<T>(message: widget.requiredMessage),
      ...widget.validators,
    ];
  }

  void _observeField(SmartFieldController<T> field) {
    _fieldController = field;
    if (identical(_observedFocusNode, field.focusNode)) {
      return;
    }
    _observedFocusNode?.removeListener(_handleFocusChanged);
    _observedFocusNode = field.focusNode..addListener(_handleFocusChanged);
  }

  void _handleMenuOpened({required bool validateWhenMenuCloses}) {
    _menuSession++;
    _menuIsOpen = true;
    _menuMovedFocusToRoute = false;
    _validateWhenMenuCloses = validateWhenMenuCloses;
  }

  void _handleSelection(SmartFieldController<T> field, T? value) {
    _menuSession++;
    _menuIsOpen = false;
    field.didChange(value);
    widget.onChanged?.call(value);
  }

  void _handleFocusChanged() {
    final focusNode = _observedFocusNode;
    if (!_menuIsOpen || focusNode == null) {
      return;
    }
    if (!focusNode.hasFocus) {
      _menuMovedFocusToRoute = true;
      return;
    }
    if (!_menuMovedFocusToRoute) {
      return;
    }

    final session = _menuSession;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_menuIsOpen || session != _menuSession) {
        return;
      }

      _menuIsOpen = false;
      focusNode.unfocus();
      final field = _fieldController;
      if (_validateWhenMenuCloses && field != null && field.enabled) {
        unawaited(field.validate());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final configuredMode =
        widget.autovalidateMode ?? SmartFormScope.of(context).autovalidateMode;
    final dropdownAutovalidateMode =
        configuredMode == AutovalidateMode.onUnfocus
        ? AutovalidateMode.onUserInteraction
        : widget.autovalidateMode;

    return SmartFormField<T>(
      name: widget.name,
      initialValue: widget.initialValue,
      validators: _validators,
      asyncValidators: widget.asyncValidators,
      asyncValidationDebounce: widget.asyncValidationDebounce,
      autovalidateMode: dropdownAutovalidateMode,
      errorAnimation: widget.errorAnimation,
      errorAnimationBuilder: widget.errorAnimationBuilder,
      excludeFromDraft: widget.excludeFromDraft,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      resultValueTransformer: widget.resultValueTransformer,
      focusNode: widget.focusNode,
      builder: (context, field) {
        _observeField(field);
        return DropdownButtonFormField<T>(
          key: ValueKey<Object?>(field.value),
          initialValue: field.value,
          focusNode: field.focusNode,
          decoration: widget.decoration.copyWith(errorText: field.errorText),
          items: <DropdownMenuItem<T>>[
            for (final item in widget.items)
              DropdownMenuItem<T>(
                value: item,
                child:
                    widget.itemBuilder?.call(context, item) ??
                    Text(widget.itemLabelBuilder(item)),
              ),
          ],
          hint: widget.hint,
          disabledHint: widget.disabledHint,
          isExpanded: widget.isExpanded,
          menuMaxHeight: widget.menuMaxHeight,
          onTap: field.enabled && !field.readOnly
              ? () => _handleMenuOpened(
                  validateWhenMenuCloses:
                      configuredMode == AutovalidateMode.onUnfocus,
                )
              : null,
          onChanged: field.enabled && !field.readOnly
              ? (value) => _handleSelection(field, value)
              : null,
        );
      },
    );
  }
}

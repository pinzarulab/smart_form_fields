import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../form/smart_field_id.dart';
import '../validation/smart_validation_context.dart';
import '../validation/smart_validator.dart';
import '../validation/smart_async_validator.dart';
import '../validation/smart_validator_metadata.dart';
import 'smart_field_controller.dart';
import 'smart_form_field.dart';

/// Builds one repeated editor. Use [SmartArrayItem.setValue] to update its row.
typedef SmartArrayItemBuilder<T> =
    Widget Function(BuildContext context, SmartArrayItem<T> item, int index);

/// Stable identity and state for one repeated row.
final class SmartArrayItem<T> extends ChangeNotifier
    implements ValueListenable<T> {
  SmartArrayItem._(this.id, this._value, this._onChanged);

  /// Stable row identity, independent of its current position.
  final int id;

  /// Attach to the row's primary editor for first-error focus navigation.
  final FocusNode focusNode = FocusNode();
  T _value;
  final void Function(SmartArrayItem<T>, T) _onChanged;
  String? _errorText;
  bool _readOnly = false;

  @override
  T get value => _value;

  /// First row validation error, if any.
  String? get errorText => _errorText;

  /// Whether user edits are currently locked.
  bool get readOnly => _readOnly;

  void _notify() => notifyListeners();

  /// Updates this row and the form's typed list value.
  void setValue(T value) {
    if (!_readOnly) _onChanged(this, value);
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }
}

/// Commands and ordered values for a mounted [SmartFieldArray].
final class SmartFieldArrayController<T> extends ChangeNotifier {
  _SmartFieldArrayState<T>? _state;

  /// Current immutable ordered row values; empty before attachment.
  List<T> get values => List<T>.unmodifiable(items.map((item) => item.value));

  /// Stable row objects, in current display order.
  List<SmartArrayItem<T>> get items => List.unmodifiable(_state?._rows ?? []);

  /// Whether a repeated field is attached.
  bool get isAttached => _state != null;

  /// Adds a row at the end or at [index].
  void add(T value, {int? index}) => _requireState()._add(value, index: index);

  /// Removes the row at [index].
  void removeAt(int index) => _requireState()._removeAt(index);

  /// Moves a row to its final [toIndex], retaining its widget and editor state.
  void move(int fromIndex, int toIndex) =>
      _requireState()._move(fromIndex, toIndex);

  /// Changes one row's value.
  void setValue(int index, T value) => items[index].setValue(value);

  _SmartFieldArrayState<T> _requireState() =>
      _state ??
      (throw StateError('SmartFieldArrayController is not attached.'));

  void _notify() => notifyListeners();
}

/// A registered typed list field with stable add/remove/reorder row editors.
/// Editors can use ordinary Flutter controls, or nested SmartForms for models.
class SmartFieldArray<T> extends StatefulWidget {
  /// Creates a repeated group whose result value is an immutable `List<T>`.
  const SmartFieldArray({
    String? name,
    this.fieldId,
    required this.itemBuilder,
    this.controller,
    this.initialValue = const [],
    this.validators = const [],
    this.asyncValidators = const [],
    this.itemValidators = const [],
    this.autovalidateMode,
    this.enabled = true,
    this.readOnly = false,
    this.excludeFromDraft = false,
    this.spacing = 12,
    this.onChanged,
    this.emptyBuilder,
    super.key,
  }) : assert(name != null || fieldId != null),
       _name = name;

  final String? _name;

  /// Unique form field name.
  String get name => _name ?? fieldId!.name;

  /// Optional typed identity for the complete list.
  final SmartFieldId<List<T>>? fieldId;

  /// Builds the application-owned editor for each row.
  final SmartArrayItemBuilder<T> itemBuilder;

  /// Optional add/remove/reorder controller, owned by the application.
  final SmartFieldArrayController<T>? controller;

  /// Initial ordered values and reset baseline.
  final List<T> initialValue;

  /// Validators for the complete list (such as minimum number of rows).
  final List<SmartValueValidator<List<T>>> validators;

  /// Async validators for the complete typed list.
  final List<SmartAsyncValidator<List<T>>> asyncValidators;

  /// Synchronous validators run for every row; expose errors on row objects.
  final List<SmartValueValidator<T>> itemValidators;

  /// Automatic validation policy.
  final AutovalidateMode? autovalidateMode;

  /// Whether editing and validation are enabled.
  final bool enabled;

  /// Whether row edits and structural commands are locked.
  final bool readOnly;

  /// Whether the entire list is excluded from drafts.
  final bool excludeFromDraft;

  /// Space between rows.
  final double spacing;

  /// Receives an immutable ordered list after a row/structure change.
  final ValueChanged<List<T>>? onChanged;

  /// Optional empty-list presentation.
  final WidgetBuilder? emptyBuilder;

  @override
  State<SmartFieldArray<T>> createState() => _SmartFieldArrayState<T>();
}

class _SmartFieldArrayState<T> extends State<SmartFieldArray<T>> {
  final List<SmartArrayItem<T>> _rows = [];
  int _nextId = 0;
  SmartFieldController<List<T>>? _field;
  late SmartValueValidator<List<T>> _rowValidator;

  @override
  void initState() {
    super.initState();
    _rowValidator = _createRowValidator();
    for (final value in widget.initialValue) {
      _rows.add(_newRow(value));
    }
    _attach(widget.controller);
  }

  void _attach(SmartFieldArrayController<T>? controller) {
    if (controller == null) return;
    if (controller._state != null && controller._state != this) {
      throw StateError(
        'A SmartFieldArrayController cannot attach to two fields.',
      );
    }
    controller._state = this;
  }

  @override
  void didUpdateWidget(SmartFieldArray<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.itemValidators, widget.itemValidators)) {
      _rowValidator = _createRowValidator();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      _attach(widget.controller);
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  SmartArrayItem<T> _newRow(T value) =>
      SmartArrayItem._(_nextId++, value, _edit);
  bool get _canEdit => _field != null && _field!.enabled && !_field!.readOnly;

  void _edit(SmartArrayItem<T> row, T value) {
    if (!_canEdit || !_rows.contains(row)) return;
    row._value = value;
    row._errorText = null;
    row._notify();
    _changed();
  }

  void _add(T value, {int? index}) {
    if (!_canEdit) return;
    _rows.insert(index ?? _rows.length, _newRow(value));
    _changed();
  }

  void _removeAt(int index) {
    if (!_canEdit) return;
    final removed = _rows.removeAt(index);
    // The row editor may still have listeners until the next layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
    _changed();
  }

  void _move(int from, int to) {
    if (!_canEdit || from == to) return;
    RangeError.checkValidIndex(to, _rows);
    final row = _rows.removeAt(from);
    _rows.insert(to, row);
    _changed();
  }

  void _changed() {
    final values = List<T>.unmodifiable(_rows.map((row) => row.value));
    _field!.didChange(values);
    setState(() {});
    widget.controller?._notify();
    widget.onChanged?.call(values);
  }

  void _sync(List<T> values) {
    if (listEquals(_rows.map((r) => r.value).toList(), values)) return;
    final previous = List<SmartArrayItem<T>>.of(_rows);
    _rows.clear();
    for (var i = 0; i < values.length; i++) {
      final row = i < previous.length ? previous[i] : _newRow(values[i]);
      row._value = values[i];
      row._errorText = null;
      _rows.add(row);
    }
    for (final row in previous.skip(values.length)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        for (final row in _rows) {
          row._notify();
        }
        widget.controller?._notify();
      }
    });
  }

  SmartValueValidator<List<T>> _createRowValidator() {
    final dependencies = dependenciesOfValidators(widget.itemValidators);
    return dependencies.isEmpty
        ? createContextValidator<List<T>>(_validateRows)
        : createDependentValidator<List<T>>(
            dependsOn: dependencies,
            validator: _validateRows,
          );
  }

  String? _validateRows(List<T>? values, SmartValidationContext context) {
    String? firstError;
    for (var index = 0; index < (values?.length ?? 0); index++) {
      String? error;
      for (final validator in widget.itemValidators) {
        error = runSmartValidator(validator, values![index], context);
        if (error != null) break;
      }
      if (index < _rows.length) _rows[index]._errorText = error;
      if (error != null) firstError ??= error;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        for (final row in _rows) {
          row._notify();
        }
        widget.controller?._notify();
      }
    });
    return firstError;
  }

  @override
  Widget build(BuildContext context) => SmartFormField<List<T>>(
    name: widget.name,
    initialValue: List<T>.unmodifiable(widget.initialValue),
    enabled: widget.enabled,
    readOnly: widget.readOnly,
    excludeFromDraft: widget.excludeFromDraft,
    autovalidateMode: widget.autovalidateMode,
    validators: [
      ...widget.validators,
      if (widget.itemValidators.isNotEmpty) _rowValidator,
    ],
    asyncValidators: widget.asyncValidators,
    builder: (context, field) {
      _field = field;
      _sync(field.value ?? []);
      for (final row in _rows) {
        row._readOnly = !field.enabled || field.readOnly;
        if (field.errorText == null && !field.isValidating) {
          row._errorText = null;
        }
      }
      return Focus(
        focusNode: field.focusNode,
        onFocusChange: (focused) {
          if (!focused || !field.focusNode.hasPrimaryFocus) return;
          final target =
              _rows.where((r) => r.errorText != null).firstOrNull ??
              _rows.firstOrNull;
          if (target?.focusNode.context != null && !target!.readOnly) {
            target.focusNode.requestFocus();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_rows.isEmpty && widget.emptyBuilder != null)
              widget.emptyBuilder!(context),
            for (var i = 0; i < _rows.length; i++) ...[
              if (i > 0) SizedBox(height: widget.spacing),
              KeyedSubtree(
                key: ValueKey(_rows[i].id),
                child: widget.itemBuilder(context, _rows[i], i),
              ),
            ],
            if (field.errorText != null)
              Text(
                field.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      );
    },
  );
}

import 'package:flutter/widgets.dart';

import 'smart_field_id.dart';
import 'smart_form_controller.dart';
import 'smart_form_field_status.dart';

/// Builds UI from one typed field without rebuilding for unrelated fields.
class SmartFormValueBuilder<T> extends StatelessWidget {
  /// Creates a typed field-state builder.
  const SmartFormValueBuilder({
    required this.controller,
    required this.field,
    required this.builder,
    super.key,
  });

  /// Controller attached to the target form.
  final SmartFormController controller;

  /// Typed field to observe.
  final SmartFieldId<T> field;

  /// Builds from the latest typed snapshot.
  final ValueWidgetBuilder<SmartFieldSnapshot<T>> builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SmartFieldSnapshot<T>>(
      valueListenable: controller.field<T>(field),
      builder: builder,
    );
  }
}

/// Builds UI from aggregate form-controller state.
class SmartFormStatusBuilder extends StatelessWidget {
  /// Creates an aggregate form-state builder.
  const SmartFormStatusBuilder({
    required this.controller,
    required this.builder,
    super.key,
  });

  /// Controller to observe.
  final SmartFormController controller;

  /// Builds from the current controller state.
  final Widget Function(BuildContext context, SmartFormController controller)
  builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => builder(context, controller),
    );
  }
}

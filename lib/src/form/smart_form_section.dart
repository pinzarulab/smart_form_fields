import 'package:flutter/widgets.dart';

/// Named group for independent validation. Keep inactive steps mounted.
class SmartFormSection extends InheritedWidget {
  /// Groups descendant fields under [name].
  const SmartFormSection({required this.name, required super.child, super.key});

  /// Section name passed to `controller.validateSection`.
  final String name;

  /// Closest enclosing section name.
  static String? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SmartFormSection>()?.name;

  @override
  bool updateShouldNotify(SmartFormSection oldWidget) => name != oldWidget.name;
}

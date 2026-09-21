import 'package:flutter/widgets.dart';

import '../form/smart_form_scope.dart';
import '../form/smart_field_id.dart';
import '../validation/smart_validation_context.dart';

/// Decides whether a conditional field should be visible.
typedef SmartConditionalFieldCondition =
    bool Function(Object? value, SmartValidationContext context);

/// Builds the transition used when a conditional field appears or disappears.
typedef SmartConditionalFieldTransitionBuilder =
    Widget Function(Widget child, Animation<double> animation);

/// Controls value/state behavior while a conditional field is hidden.
enum SmartHiddenFieldBehavior {
  /// Disposes hidden content and removes its values from the form.
  remove,

  /// Keeps state and includes hidden values, while skipping validation.
  preserve,

  /// Keeps state but excludes hidden values and skips validation.
  preserveAndExclude,
}

/// Shows [child] only when another field value satisfies [condition].
class SmartConditionalField extends StatefulWidget {
  /// Creates a field wrapper controlled by [dependsOn].
  const SmartConditionalField({
    this.dependsOn,
    this.dependsOnFields = const <Object>{},
    required this.condition,
    required this.child,
    this.placeholder = const SizedBox.shrink(),
    this.duration = const Duration(milliseconds: 220),
    this.reverseDuration,
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeInCubic,
    this.alignment = Alignment.topCenter,
    this.transitionBuilder,
    this.hiddenBehavior = SmartHiddenFieldBehavior.remove,
    super.key,
  }) : assert(
         dependsOn != null || dependsOnFields.length > 0,
         'Provide dependsOn or dependsOnFields.',
       );

  /// Source field name observed for visibility changes.
  final Object? dependsOn;

  /// Additional field names observed by [condition].
  final Set<Object> dependsOnFields;

  /// Predicate evaluated with the source value and current form values.
  final SmartConditionalFieldCondition condition;

  /// Widget displayed when [condition] returns true.
  final Widget child;

  /// Widget displayed when [condition] returns false.
  final Widget placeholder;

  /// Duration used when [child] appears.
  final Duration duration;

  /// Duration used when [child] disappears.
  final Duration? reverseDuration;

  /// Curve used when [child] appears.
  final Curve curve;

  /// Curve used when [child] disappears.
  final Curve reverseCurve;

  /// Alignment used by the built-in size animation.
  final AlignmentGeometry alignment;

  /// Optional custom transition for appearing and disappearing content.
  ///
  /// When omitted, the field fades content while its outer size animates
  /// without clipping descendant input labels.
  final SmartConditionalFieldTransitionBuilder? transitionBuilder;

  /// State/value behavior used while [condition] is false.
  final SmartHiddenFieldBehavior hiddenBehavior;

  @override
  State<SmartConditionalField> createState() => _SmartConditionalFieldState();
}

class _SmartConditionalFieldState extends State<SmartConditionalField> {
  SmartFormScope? _scope;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextScope = SmartFormScope.of(context);
    if (!identical(_scope?.registrar, nextScope.registrar)) {
      _scope?.registrar.removeFormListener(_handleFormChanged);
      _scope = nextScope;
      nextScope.registrar.addFormListener(_handleFormChanged);
    } else {
      _scope = nextScope;
    }
    _visible = _evaluate();
  }

  @override
  void didUpdateWidget(SmartConditionalField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dependsOn != widget.dependsOn ||
        oldWidget.dependsOnFields != widget.dependsOnFields ||
        !identical(oldWidget.condition, widget.condition)) {
      final visible = _evaluate();
      if (visible != _visible) {
        setState(() => _visible = visible);
      } else {
        _visible = visible;
      }
    }
  }

  @override
  void dispose() {
    _scope?.registrar.removeFormListener(_handleFormChanged);
    super.dispose();
  }

  void _handleFormChanged() {
    final visible = _evaluate();
    if (visible != _visible && mounted) {
      setState(() => _visible = visible);
    }
  }

  bool _evaluate() {
    final context = _scope?.registrar.validationContext;
    if (context == null) {
      return false;
    }
    final dependency = widget.dependsOn;
    return widget.condition(
      dependency == null ? null : context.values[smartFieldName(dependency)],
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hiddenBehavior != SmartHiddenFieldBehavior.remove) {
      return _buildMaintainedChild();
    }
    return AnimatedSize(
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
      curve: widget.curve,
      alignment: widget.alignment,
      clipBehavior: Clip.none,
      child: AnimatedSwitcher(
        duration: widget.duration,
        reverseDuration: widget.reverseDuration,
        switchInCurve: widget.curve,
        switchOutCurve: widget.reverseCurve,
        transitionBuilder:
            widget.transitionBuilder ?? _defaultTransitionBuilder,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: widget.alignment,
            children: <Widget>[...previousChildren, ?currentChild],
          );
        },
        child: KeyedSubtree(
          key: ValueKey<bool>(_visible),
          child: _visible ? widget.child : widget.placeholder,
        ),
      ),
    );
  }

  Widget _buildMaintainedChild() {
    final includeInResult =
        _visible || widget.hiddenBehavior == SmartHiddenFieldBehavior.preserve;
    return SmartFieldActivityScope(
      active: _visible,
      includeInResult: includeInResult,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _visible ? 1 : 0),
        duration: _visible
            ? widget.duration
            : widget.reverseDuration ?? widget.duration,
        curve: _visible ? widget.curve : widget.reverseCurve,
        builder: (context, animationValue, child) {
          final animation = AlwaysStoppedAnimation<double>(animationValue);
          final transitioned = widget.transitionBuilder == null
              ? Opacity(opacity: animationValue, child: child)
              : widget.transitionBuilder!(child!, animation);
          return IgnorePointer(
            ignoring: !_visible,
            child: ExcludeSemantics(
              excluding: !_visible,
              child: Align(
                alignment: widget.alignment,
                heightFactor: animationValue,
                child: transitioned,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }

  Widget _defaultTransitionBuilder(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }
}

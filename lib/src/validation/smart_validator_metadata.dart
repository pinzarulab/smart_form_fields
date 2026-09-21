// ignore_for_file: public_member_api_docs

import 'smart_async_validator.dart';
import 'smart_validation_context.dart';
import 'smart_validator.dart';

typedef _SyncRunner =
    String? Function(Object? value, SmartValidationContext context);
typedef _AsyncRunner =
    Future<String?> Function(
      Object? value,
      SmartValidationContext context,
      SmartAsyncValidationContext asyncContext,
    );

final class _SyncMetadata {
  const _SyncMetadata(this.dependencies, this.run);

  final Set<String> dependencies;
  final _SyncRunner run;
}

final class _AsyncMetadata {
  const _AsyncMetadata(this.dependencies, this.run);

  final Set<String> dependencies;
  final _AsyncRunner run;
}

final Expando<_SyncMetadata> _syncMetadata = Expando<_SyncMetadata>();
final Expando<_AsyncMetadata> _asyncMetadata = Expando<_AsyncMetadata>();

SmartValueValidator<T> createDependentValidator<T>({
  required Iterable<String> dependsOn,
  required SmartContextValidator<T> validator,
}) {
  final dependencies = _checkedDependencies(dependsOn);
  String? placeholder(T? value) {
    throw StateError(
      'A dependent validator must run through SmartFormField validation so '
      'that a SmartValidationContext is available.',
    );
  }

  _syncMetadata[placeholder] = _SyncMetadata(
    dependencies,
    (value, context) => validator(value as T?, context),
  );
  return placeholder;
}

SmartValueValidator<T> createContextValidator<T>(
  SmartContextValidator<T> validator,
) {
  String? placeholder(T? value) {
    return validator(value, SmartValidationContext(const <String, Object?>{}));
  }

  _syncMetadata[placeholder] = _SyncMetadata(
    const <String>{},
    (value, context) => validator(value as T?, context),
  );
  return placeholder;
}

SmartAsyncValidator<T> createDependentAsyncValidator<T>({
  required Iterable<String> dependsOn,
  required SmartContextAsyncValidator<T> validator,
}) {
  final dependencies = _checkedDependencies(dependsOn);
  Future<String?> placeholder(T? value) {
    throw StateError(
      'A dependent async validator must run through SmartFormField validation '
      'so that a SmartValidationContext is available.',
    );
  }

  _asyncMetadata[placeholder] = _AsyncMetadata(
    dependencies,
    (value, context, _) => validator(value as T?, context),
  );
  return placeholder;
}

Set<String> dependenciesOfValidators(Iterable<Object> validators) {
  return Set<String>.unmodifiable(<String>{
    for (final validator in validators)
      ...?_syncMetadata[validator]?.dependencies,
    for (final validator in validators)
      ...?_asyncMetadata[validator]?.dependencies,
  });
}

String? runSmartValidator<T>(
  SmartValueValidator<T> validator,
  T? value,
  SmartValidationContext context,
) {
  final metadata = _syncMetadata[validator];
  return metadata == null ? validator(value) : metadata.run(value, context);
}

Future<String?> runSmartAsyncValidator<T>(
  SmartAsyncValidator<T> validator,
  T? value,
  SmartValidationContext context, [
  SmartAsyncValidationContext? asyncContext,
]) {
  final metadata = _asyncMetadata[validator];
  final effectiveAsyncContext =
      asyncContext ??
      SmartAsyncValidationContext(form: context, isCurrent: () => true);
  return metadata == null
      ? validator(value)
      : metadata.run(value, context, effectiveAsyncContext);
}

SmartValueValidator<T> adaptSmartValidator<T>(
  SmartValueValidator<Object?> validator,
) {
  final metadata = _syncMetadata[validator];
  if (metadata == null) {
    return (value) => validator(value);
  }
  String? placeholder(T? value) {
    return metadata.run(
      value,
      SmartValidationContext(const <String, Object?>{}),
    );
  }

  _syncMetadata[placeholder] = _SyncMetadata(
    metadata.dependencies,
    (value, context) => metadata.run(value, context),
  );
  return placeholder;
}

SmartAsyncValidator<T> createControlledAsyncValidator<T>({
  required Iterable<String> dependsOn,
  required SmartControlledAsyncValidator<T> validator,
}) {
  final dependencies = <String>{};
  for (final dependency in dependsOn) {
    if (dependency.isEmpty) {
      throw ArgumentError.value(
        dependency,
        'dependsOn',
        'Names cannot be empty.',
      );
    }
    dependencies.add(dependency);
  }
  Future<String?> placeholder(T? value) {
    return validator(
      value,
      SmartAsyncValidationContext(
        form: SmartValidationContext(const <String, Object?>{}),
        isCurrent: () => true,
      ),
    );
  }

  _asyncMetadata[placeholder] = _AsyncMetadata(
    Set<String>.unmodifiable(dependencies),
    (value, _, asyncContext) => validator(value as T?, asyncContext),
  );
  return placeholder;
}

SmartAsyncValidator<T> adaptSmartAsyncValidator<T>(
  SmartAsyncValidator<Object?> validator,
) {
  final metadata = _asyncMetadata[validator];
  if (metadata == null) {
    return (value) => validator(value);
  }
  Future<String?> placeholder(T? value) {
    final context = SmartValidationContext(const <String, Object?>{});
    return metadata.run(
      value,
      context,
      SmartAsyncValidationContext(form: context, isCurrent: () => true),
    );
  }

  _asyncMetadata[placeholder] = _AsyncMetadata(
    metadata.dependencies,
    (value, context, asyncContext) =>
        metadata.run(value, context, asyncContext),
  );
  return placeholder;
}

Set<String> dependenciesOfAsyncValidator(Object validator) {
  return _asyncMetadata[validator]?.dependencies ?? const <String>{};
}

Set<String> _checkedDependencies(Iterable<String> values) {
  final result = <String>{};
  for (final value in values) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'dependsOn', 'Names cannot be empty.');
    }
    result.add(value);
  }
  if (result.isEmpty) {
    throw ArgumentError.value(
      values,
      'dependsOn',
      'At least one dependency is required.',
    );
  }
  return Set<String>.unmodifiable(result);
}

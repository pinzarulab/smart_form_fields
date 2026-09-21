# Migrating to 2.0.0

Version 2 keeps existing string names, map results, widget constructors, and
legacy submit callbacks working. Applications can migrate incrementally.

Use typed field IDs where the same name appears more than once:

```dart
const emailField = SmartFieldId<String>('email');

SmartEmailField(fieldId: emailField);
final email = result.valueFor(emailField);
```

Use `controller.setInitialValues()` instead of `patchValue()` when loading an
edit model that should become the clean reset baseline. Use
`SmartFormAdapter<T>` and `SmartModelForm<T>` when typed model binding is
desired.

Legacy `onSubmit(values)` remains supported. Migrate to `onSubmitResult` only
when automatic backend error application and structured submission phases are
needed.

Built-in validator defaults now resolve through `SmartForm.messages`. Explicit
messages behave exactly as before. The fallback text remains compatible, and
the package still bundles no translation catalogs.

# Migrating to 1.0.0

## String validators

`SmartValidator` now represents a string validator directly. Remove the
`<String>` type argument from validator declarations and factories:

```dart
// Before
final List<SmartValidator<String>> validators = [
  SmartValidators.matchesField<String>('password'),
];

// 1.0.0
final List<SmartValidator> validators = [
  SmartValidators.matchesField('password'),
];
```

For dates, typed dropdowns, and custom values, replace generic
`SmartValidator<T>` usage with `SmartValueValidator<T>` and use
`SmartValueValidators`:

```dart
final List<SmartValueValidator<DateTime>> validators = [
  SmartValueValidators.required<DateTime>(),
];
```

## Declarative forms

`SmartSchemaForm.fromClasses` adapts application/API model objects into smart
fields through one typed mapper:

```dart
SmartSchemaForm.fromClasses<ApiField>(
  fields: response.fields,
  fieldMapper: (field) => switch (field) {
    EmailField field => SmartFieldDefinition.email(
        name: field.name,
        labelText: field.label,
        required: field.required,
      ),
    // Map the remaining API model subclasses once.
  },
);
```

JSON remains available through `SmartSchemaForm.fromJson`. The previous
`SmartJsonForm`, `SmartJsonFieldDefinition`, `SmartJsonValidatorDefinition`,
and builder names remain as compatibility aliases, but new code should use the
neutral schema names.

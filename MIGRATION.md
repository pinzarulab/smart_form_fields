# Migrating to 3.0.0

`controller.submit()` and `formKey.submit()` return `SmartFormSubmitResult`.
The existing `isValid`, `values`, and `errors` accessors remain available;
`isValid` describes local validation, while `isSuccess` means the application
accepted the submission. Backend rejections include field and general errors.
Validation and submission exceptions are captured in `error` and `stackTrace`
rather than thrown from `submit()`:

```dart
final result = await controller.submit();
if (result.isSuccess) {
  closePage();
} else if (result.error != null) {
  showFailure(result.error!);
} else {
  showMessages(result.generalErrors);
}
```

`validate()` still throws unexpected validator exceptions. `SmartSubmitButton`
continues routing submission exceptions to `onError` automatically.

`hasValidated` describes validation of the current value. Editing a field
invalidates its previous validation status. Use `canSubmit` only when you want
to require already-completed validation; a normal submit button should remain
enabled so tapping it can validate untouched fields.

Picker callbacks returning nullable values still treat null as cancellation.
Use `onPickResult` with `SmartPickerResult.cleared()` to explicitly clear a value.

Keep inactive `SmartFormSection` steps mounted with `IndexedStack` or another
state-preserving layout. Unmounted fields do not participate in validation.

Async validation retries when registered values change, up to ten attempts.
Continual changes produce a failed submission result. Values should be immutable
models: in-place mutations outside form APIs cannot be observed. Draft cleanup
after success preserves edits made while a request was pending.

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

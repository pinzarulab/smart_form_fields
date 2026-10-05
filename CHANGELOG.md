## 3.0.1

* Pin CI to Flutter `3.47.6` for reproducible Dart formatting checks.

## 3.0.0

* Return unified `SmartFormSubmitResult` from controller submission, combining
  validation, backend errors, success, and captured exceptions.
* Add subset and named-section validation with `SmartFormSection`.
* Add field reset/error commands and ordered `focusNext` navigation.
* Add explicit picker selection/clear/cancel results and optional clear buttons.
* Add form change callbacks and validated aggregate submission readiness.
* Retry validation when values change during asynchronous checks or result
  transformation, and support optional input locking during submission.
* Add declarative initial form/model values and dirty-preserving API refresh.
* Add typed repeated `SmartFieldArray` editors with stable row identities,
  add/remove/reorder commands, row validation, and list results.

## 2.0.1

* Preserve field input state and keyboard connections when validation-error
  animations add or change wrappers, fixing invalid fields losing focus on the
  first tap.

## 2.0.0

* Add typed `SmartFieldId<T>` identities across fields, results, validation
  dependencies, model adapters, and controller field access.
* Add `SmartFieldAccessor<T>`, field-specific listenables, richer field status,
  validation-error origins, and `SmartFormValueBuilder`/`SmartFormStatusBuilder`.
* Add clean initial-value and model loading through `setInitialValues`,
  `setInitialModel`, and configurable `SmartValueUpdateOptions`.
* Add `SmartFormAdapter<T>`, `SmartTypedFormResult<T>`, and `SmartModelForm<T>`
  for typed decoding, initial values, and submission.
* Add structured submission phases/results, automatic backend field-error
  application, fieldless errors, and application-owned submit-button builders.
* Add `SmartPickerField<T>` for bottom sheets, dialogs, and other custom picker
  presentations without manual form-state plumbing.
* Add view items for email, password, date, dropdown, picker, and conditional
  fields, plus consistent read-only, async-debounce, and result-transform APIs.
* Add conditional state/value policies, multiple dependency metadata, and
  snake_case JSON/class visibility definitions.
* Add arbitrary-layout forms, item separator builders, padding, named form
  constructors, and reveal hooks for tabs, steps, and accordions.
* Add application-owned `SmartFormMessages` resolution without bundled
  translation catalogs.
* Add reusable schema registries, full-response schema extraction, schema
  versions, unknown-field fallbacks, read-only fields, and conditional schemas.
* Add cooperative async-validation cancellation context and controlled async
  validators.

## 1.8.0

* Add typed/text helpers to `SmartFormResult`, including `valueOf<T>()`,
  `maybeText()`, and `text()`.
* Add value/text access to field view items, including `valueReader` for custom
  widget-backed items.
* Add `SmartTextFieldViewItem` so item-driven text fields can expose
  `item.text` directly while still building a normal `SmartTextField`.

## 1.7.0

* Add `SmartErrorAnimationBuilder` for custom field-error animations at the
  field, form, and theme levels.
* Add an example screen demonstrating `SmartForm.errorAnimationBuilder`.

## 1.6.0

* Add `slide`, `scale`, and `pulse` built-in error animations for smart fields.

## 1.5.6

* Prevent `SmartConditionalField`'s built-in animation from clipping focused
  outlined input labels while conditional content appears or disappears.

## 1.5.5

* Add configurable appear/disappear animations to `SmartConditionalField`,
  including duration, reverse duration, curves, alignment, and a custom
  transition builder.

## 1.5.4

* Add field-level draft exclusions with `excludeFromDraft` for sensitive values
  such as passwords, tokens, and card details.
* Add `SmartForm.onSubmit`, `SmartFormController.submit`, submission state, and
  `SmartSubmitButton` with duplicate-submission prevention and draft cleanup
  after successful submits.
* Add `SmartConditionalField` for showing and unregistering dependent fields
  based on another field's value.

## 1.5.3

* Add `SmartCallbackDraftStorage` so applications can persist drafts through
  their own controllers, domain use cases, repositories, or ObjectBox adapters
  without adding storage-specific dependencies to the package.

## 1.5.2

* Keep item-form drafts after validation; drafts are now cleared only after an
  actual successful submission explicitly calls `markSubmitted()`.
* Demonstrate and test automatic draft restoration across application
  restarts.

## 1.5.1

* Make the example's item-driven draft persist across application restarts
  using a `shared_preferences` storage adapter.
* Add example coverage for restoring a saved draft after rebuilding the
  application.

## 1.5.0

* Add observable form status with field-level dirty and asynchronous validation
  state as the foundation for draft persistence.
* Add debounced draft autosaving, restoration prompts, schema migrations,
  sensitive-field exclusions, expiration, explicit submission/discard flows,
  and navigation protection.
* Add JSON/DateTime serialization, in-memory storage, and transform storage for
  application-provided local encryption.
* Extend the item-driven example with autosave status, draft restoration,
  reset/submission cleanup, and guarded back navigation.

## 1.4.0

* Add a complete item-driven example page built exclusively with
  `SmartForm.items`, `SmartPhoneFieldViewItem`, and builder-backed field items.
* Demonstrate shared item spacing, validation, value patching, resetting,
  custom boolean fields, country selection, and parsed phone submission.

## 1.3.0

* Add the immutable `SmartFieldViewItem` contract and a builder-backed custom
  item for declarative field lists.
* Add `SmartPhoneFieldViewItem` and support concise
  `SmartPhoneField(item: phoneItem)` construction with optional direct
  overrides.
* Let `SmartForm` render `items` with configurable `itemSeparatorHeight` while
  preserving the existing `children` API.

## 1.2.0

* Add asynchronous result-value transformers to `SmartFormField` and
  `SmartTextField` while preserving their raw live values.
* Add `SmartPhoneValue` and `SmartPhoneField.valueParser` so validation results
  can contain both the formatted display number and canonical E.164 number.
* Wait for phone parsing before returning `SmartFormResult` and retain the
  formatted `String` behavior when no parser is configured.

## 1.1.0

* Add application-owned country selector widgets to `SmartPhoneField`.
* Support selectors inside the input decoration or in a separate container in
  the same row, with an optional custom separator.
* Keep phone formatting pluggable through `inputFormatters`, allowing apps to
  use `flutter_libphonenumber` and locale-specific country data without making
  its platform plugin a required dependency of every form user.

## 1.0.1

* Add `SmartApiErrors.parse` for recursively extracting validation errors from
  complete decoded backend responses.
* Add `setErrorsFromResponse` to `SmartFormController` and `SmartFormKey` with
  automatic snake_case/camelCase matching, path matching, explicit aliases,
  multiple-message joining, optional error clearing, and first-error scrolling.
* Recognize field maps, error object arrays, nested validation containers,
  JSON:API pointers, GraphQL paths, fieldless messages, and custom extractors.
* Return applied, unmapped, discovered, and general errors through
  `SmartApiErrorResult` so no backend validation information is lost.

## 1.0.0

* Make `SmartValidator` string-first so text, email, phone, and password
  validators no longer require `<String>`.
* Add `SmartValueValidator<T>` and `SmartValueValidators` for dates, typed
  dropdowns, and custom value fields.
* Add `SmartSchemaForm.fromClasses` with a typed mapper for creating forms from
  lists of application/API DTO classes such as email, password, and dropdown
  field models.
* Add `SmartFieldDefinition`, `SmartValidatorDefinition`, and typed mapping
  targets for every built-in generated field.
* Keep snake_case JSON construction through `SmartSchemaForm.fromJson` and
  backwards-compatible `SmartJson*` aliases.
* Add a complete API-model-class form example and 1.0 migration guide.

## 0.2.3

* Preserve existing validation errors when a parent rebuild supplies new
  validator function instances, including disabled dependent fields.
* Keep password and confirmation errors visible while first-error navigation
  focuses the password field after submission.

## 0.2.2

* Validate an `onUnfocus` `SmartDropdownField` when its menu is dismissed
  without a selection.
* Release dropdown focus after dismissal so the next field responds to its
  first tap.

## 0.2.1

* Prevent opening a `SmartDropdownField` menu from being treated as a real
  focus-loss validation event.
* In the default `onUnfocus` mode, validate dropdowns after the user selects an
  item so the menu opens and responds on the first tap.

## 0.2.0

* Add read-only `SmartValidationContext` snapshots and explicit dependency
  metadata for synchronous and asynchronous validators.
* Add `SmartValidators.matchesField`, `SmartValidators.requiredWhen`, custom
  dependent validators, and `SmartAsyncValidators.dependent`.
* Automatically revalidate previously validated dependent fields when source
  values change, while preserving async race protection and atomic patches.
* Detect unknown dependency names and dependency cycles with descriptive
  errors.
* Add snake_case JSON support for `matches_field`, `required_when`, and async
  validator `depends_on` metadata.
* Update the registration example to use dependency-aware password
  confirmation.

## 0.1.0

* Document the complete supported public API and enforce documentation in
  analysis.
* Add CI gates for formatting, analysis, package and example tests, coverage,
  and publication validation.
* Add Material 2, Material 3, accessibility, focus traversal, form lifecycle,
  theme update, and long-form integration coverage.
* Mark the package as ready for its first public minor release.

## 0.0.11

* Start first-invalid-field error animation only after scrolling and focus
  navigation complete.
* Apply the same ordering when scrolling to injected server errors.
* Keep automatic field validation animations immediate when no navigation is
  requested.

## 0.0.10

* Add a form-level `autovalidateMode` default to `SmartForm` and
  `SmartJsonForm`.
* Let descendant fields inherit the form mode while preserving field-level
  overrides.
* Support submit-only validation without repeating configuration on every
  field.

## 0.0.9

* Preserve direct focus transfer when tapping another field in the same form.
* Treat only a fully hidden keyboard as dismissal so keyboard-height changes
  between input types do not unfocus the destination field.
* Prevent valid values from receiving transient required errors during field
  navigation.

## 0.0.8

* Unfocus the active form field when the keyboard becomes hidden.
* Dismiss focus when tapping outside the active field, including blank space
  inside the form.
* Add opt-out flags and a keyboard visibility callback on `SmartForm`.

## 0.0.7

* Split the example bootstrap, app shell, and screens into focused files.
* Add separate registration, JSON/API form, and controller playground screens.
* Demonstrate reusable and custom fields, JSON registries, bottom-sheet input,
  dynamic/disabled fields, and the complete key/controller command surface.

## 0.0.6

* Add `SmartFormSchema` and `SmartJsonForm.fromJson` for API-driven forms.
* Support built-in text, email, phone, password, date, and dropdown JSON field
  types with synchronous validator configuration.
* Allow applications to register custom JSON field builders, custom validator
  builders, and named asynchronous validators.
* Use snake_case keys throughout the API-driven JSON form schema.
* Document canonical keys such as `scroll_to_first_error`, `label_text`,
  `initial_value`, and `async_validators`.

## 0.0.5

* Complete the README guidance for installation, controller lifecycle, custom
  fields, async validation, server errors, disabled fields, and navigation.
* Demonstrate shared `SmartFormTheme` behavior in the example application.
* Align the implementation plan and public API documentation with
  application-owned validation localization.

## 0.0.4

* Add `SmartFormTheme` and `SmartFormThemeData` for shared scrolling, focus,
  and error-animation behavior.
* Allow values set directly on `SmartForm` to override inherited defaults.
* Keep validation-message localization application-owned without adding
  bundled language catalogs.

## 0.0.3

* Add reusable email, password, phone, date, and generic dropdown fields.
* Expand the registration example with birth-date and country fields.
* Add focused widget coverage for every reusable field and date-picker
  interaction.

## 0.0.2

* Validate fields on focus loss by default.
* Keep explicit form submission validation immediate and support opt-in
  change-time validation with `AutovalidateMode.onUserInteraction`.
* Prevent parent rebuilds from validating an `onUnfocus` field while it remains
  focused.
* Expand the example and widget tests for focus-loss and submission validation.

## 0.0.1

* Scaffold the Flutter package.
* Add `SmartForm`, `SmartFormKey`, and `SmartFormController` foundations.
* Add immutable `SmartFormResult` snapshots.
* Add lifecycle-safe field registration with duplicate-name detection,
  dynamic removal, nested-form isolation, and visual-order updates.
* Add generic and text fields with race-safe synchronous and asynchronous
  validation.
* Add built-in required, email, length, pattern, number, minimum, and maximum
  validators.
* Add configurable shake, fade, or disabled error animations with reduced
  motion support.
* Harden first-error scrolling and focus for nested scrollables, disappearing
  fields, and navigation failures.

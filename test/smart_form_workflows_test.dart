import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets(
    'initial values are applied when conditional fields mount later',
    (tester) async {
      final controller = SmartFormController();
      await tester.pumpWidget(
        _app(
          SmartForm(
            controller: controller,
            initialValues: const {'type': 'personal', 'company': 'API company'},
            children: [
              const SmartTextField(name: 'type'),
              SmartConditionalField(
                dependsOn: 'type',
                condition: (value, _) => value == 'business',
                child: const SmartTextField(name: 'company'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.values.containsKey('company'), isFalse);
      controller.setValue('type', 'business');
      await tester.pumpAndSettle();
      expect(controller.valueOf<String>('company'), 'API company');
      expect(controller.fieldStatuses['company']!.isDirty, isFalse);
    },
  );

  testWidgets('successful submission preserves a newer draft edit', (
    tester,
  ) async {
    final controller = SmartFormController();
    final storage = SmartMemoryDraftStorage();
    final draft = SmartFormDraftController(
      id: 'pending-edit',
      storage: storage,
      autosaveDebounce: Duration.zero,
    );
    final pending = Completer<void>();
    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          draftController: draft,
          onSubmit: (_) => pending.future,
          children: const [
            SmartTextField(name: 'name', initialValue: 'Original'),
          ],
        ),
      ),
    );
    await tester.pump();
    controller.setValue('name', 'Submitted');
    await tester.pump();
    final future = controller.submit();
    await tester.pump();
    controller.setValue('name', 'Newer edit');
    await tester.pump();
    await draft.saveNow();
    pending.complete();
    final result = await future;
    expect(result.isSuccess, isTrue);
    expect(result.values['name'], 'Submitted');
    expect(await storage.read('pending-edit'), isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
    draft.dispose();
    controller.dispose();
  });

  testWidgets('result conversion retries when a newer value arrives', (
    tester,
  ) async {
    final controller = SmartFormController();
    final converting = Completer<Object?>();
    var count = 0;
    String? submitted;
    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          onSubmit: (values) => submitted = values['name'] as String?,
          children: [
            SmartTextField(
              name: 'name',
              initialValue: 'old',
              resultValueTransformer: (value) {
                count++;
                return count == 1 ? converting.future : value!.toUpperCase();
              },
            ),
          ],
        ),
      ),
    );
    final future = controller.submit();
    await tester.pump();
    controller.setValue('name', 'new');
    converting.complete('OLD');
    final result = await future;
    expect(result.isSuccess, isTrue);
    expect(submitted, 'NEW');
    expect(count, 2);
  });

  testWidgets('submission returns success, rejection and captured exception', (
    tester,
  ) async {
    final controller = SmartFormController();
    var mode = 0;
    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          scrollToFirstError: false,
          focusFirstError: false,
          onSubmitResult: (_) {
            if (mode == 1) {
              return const SmartSubmissionResult.rejected(
                fieldErrors: {'name': 'Already used'},
                generalErrors: ['Try again'],
                scrollToFirstError: false,
              );
            }
            if (mode == 2) throw StateError('Offline');
            return const SmartSubmissionResult.success();
          },
          children: const [SmartTextField(name: 'name', initialValue: 'Ana')],
        ),
      ),
    );
    expect((await controller.submit()).isSuccess, isTrue);
    mode = 1;
    final rejected = await controller.submit();
    expect(rejected.isSuccess, isFalse);
    expect(rejected.errors['name'], 'Already used');
    expect(rejected.generalErrors, ['Try again']);
    mode = 2;
    final failed = await controller.submit();
    expect(failed.phase, SmartSubmissionPhase.failed);
    expect(failed.error, isA<StateError>());
    expect(failed.stackTrace, isNotNull);
  });

  testWidgets(
    'sections validate only their fields and readiness needs validation',
    (tester) async {
      final controller = SmartFormController();
      await tester.pumpWidget(
        _app(
          SmartForm(
            controller: controller,
            scrollToFirstError: false,
            focusFirstError: false,
            children: [
              SmartFormSection(
                name: 'identity',
                child: SmartTextField(
                  name: 'name',
                  validators: [SmartValidators.required()],
                ),
              ),
              SmartFormSection(
                name: 'contact',
                child: SmartEmailField(name: 'email', required: true),
              ),
            ],
          ),
        ),
      );
      expect(controller.canSubmit, isFalse);
      final result = await controller.validateSection('identity');
      expect(result.errors.keys, ['name']);
      expect(controller.fieldStatuses['email']!.hasValidated, isFalse);
      expect(controller.hasErrors, isTrue);
      controller.setValue('name', 'Ana');
      controller.setValue('email', 'ana@example.com');
      await controller.validate();
      expect(controller.hasValidated, isTrue);
      expect(controller.isValid, isTrue);
      expect(controller.canSubmit, isTrue);
      controller.setValue('name', 'New');
      expect(controller.canSubmit, isFalse);
    },
  );

  testWidgets(
    'typed field commands reset values/errors and focusNext skips locked fields',
    (tester) async {
      const first = SmartFieldId<String>('first');
      final controller = SmartFormController();
      await tester.pumpWidget(
        _app(
          SmartForm(
            controller: controller,
            children: const [
              SmartTextField(fieldId: first, initialValue: 'Original'),
              SmartTextField(name: 'locked', readOnly: true),
              SmartTextField(name: 'next'),
            ],
          ),
        ),
      );
      final field = controller.field(first);
      field.fieldValue = 'Edited';
      field.setError('Server error');
      expect(field.value.errorText, 'Server error');
      field.clearError();
      expect(field.value.errorText, isNull);
      field.reset();
      expect(field.fieldValue, 'Original');
      await field.focus();
      await tester.pump();
      await controller.focusNext();
      await tester.pump();
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.last.focusNode!.hasFocus, isTrue);
    },
  );

  testWidgets('API refresh keeps dirty fields and updates reset baseline', (
    tester,
  ) async {
    final controller = SmartFormController();
    var initial = <String, Object?>{'name': 'API', 'email': 'old@example.com'};
    late StateSetter rebuild;
    final changes = <Map<String, Object?>>[];
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (_, setState) {
            rebuild = setState;
            return SmartForm(
              controller: controller,
              initialValues: initial,
              preserveDirtyFields: true,
              onChanged: changes.add,
              children: const [
                SmartTextField(name: 'name'),
                SmartEmailField(name: 'email'),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(controller.isDirty, isFalse);
    controller.setValue('name', 'Local');
    rebuild(() => initial = {'name': 'Remote', 'email': 'new@example.com'});
    await tester.pump();
    await tester.pump();
    expect(controller.valueOf<String>('name'), 'Local');
    expect(controller.valueOf<String>('email'), 'new@example.com');
    controller.reset();
    expect(controller.valueOf<String>('name'), 'API');
    expect(controller.valueOf<String>('email'), 'new@example.com');
    expect(changes.last['email'], 'new@example.com');
  });

  testWidgets(
    'model initialValue loads without post-frame controller commands',
    (tester) async {
      final controller = SmartFormController();
      final adapter = SmartFormAdapter<String>(
        fromValues: (v) => v.valueOf<String>('name')!,
        toValues: (v) => {'name': v},
      );
      await tester.pumpWidget(
        _app(
          SmartModelForm<String>(
            controller: controller,
            adapter: adapter,
            initialValue: 'Model name',
            children: const [SmartTextField(name: 'name')],
          ),
        ),
      );
      await tester.pump();
      expect(controller.valueOf<String>('name'), 'Model name');
      expect(controller.isDirty, isFalse);
    },
  );

  testWidgets(
    'changes during async validation are revalidated before submission',
    (tester) async {
      final controller = SmartFormController();
      final pending = Completer<String?>();
      var calls = 0;
      var submissions = 0;
      await tester.pumpWidget(
        _app(
          SmartForm(
            controller: controller,
            scrollToFirstError: false,
            focusFirstError: false,
            onSubmit: (_) => submissions++,
            children: [
              SmartTextField(
                name: 'name',
                initialValue: 'good',
                autovalidateMode: AutovalidateMode.disabled,
                asyncValidators: [
                  (value) async {
                    calls++;
                    if (calls == 1) return pending.future;
                    return value == 'bad' ? 'Invalid new value' : null;
                  },
                ],
              ),
            ],
          ),
        ),
      );
      final future = controller.submit();
      await tester.pump();
      controller.setValue('name', 'bad');
      pending.complete(null);
      final result = await future;
      expect(calls, 2);
      expect(submissions, 0);
      expect(result.values['name'], 'bad');
      expect(result.errors['name'], 'Invalid new value');
      expect(result.phase, SmartSubmissionPhase.invalid);
    },
  );

  testWidgets('submission can lock input and prevent duplicate requests', (
    tester,
  ) async {
    final controller = SmartFormController();
    final pending = Completer<void>();
    var count = 0;
    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          lockWhileSubmitting: true,
          onSubmit: (_) {
            count++;
            return pending.future;
          },
          children: const [SmartTextField(name: 'name', initialValue: 'Ana')],
        ),
      ),
    );
    final first = controller.submit();
    final second = controller.submit();
    expect(identical(first, second), isTrue);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    pending.complete();
    expect((await first).isSuccess, isTrue);
    await tester.pump();
    expect(count, 1);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
  });

  testWidgets('picker distinguishes cancel and clear and has a clear button', (
    tester,
  ) async {
    final controller = SmartFormController();
    var outcome = const SmartPickerResult<String>.cancelled();
    await tester.pumpWidget(
      _app(
        SmartForm(
          controller: controller,
          children: [
            SmartPickerField<String>(
              name: 'country',
              initialValue: 'Moldova',
              allowClear: true,
              onPickResult: (_, _) => outcome,
              displayBuilder: (_, value, _) => Text(value ?? 'Choose country'),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Moldova'));
    await tester.pumpAndSettle();
    expect(controller.valueOf<String>('country'), 'Moldova');
    outcome = const SmartPickerResult.cleared();
    await tester.tap(find.text('Moldova'));
    await tester.pumpAndSettle();
    expect(controller.valueOf<String>('country'), isNull);
    outcome = const SmartPickerResult.selected('Romania');
    await tester.tap(find.text('Choose country'));
    await tester.pumpAndSettle();
    expect(controller.valueOf<String>('country'), 'Romania');
    await tester.tap(find.byTooltip('Clear selection'));
    await tester.pumpAndSettle();
    expect(controller.valueOf<String>('country'), isNull);
  });

  testWidgets(
    'repeated rows retain identities on reorder and produce typed lists',
    (tester) async {
      final form = SmartFormController();
      final rows = SmartFieldArrayController<String>();
      const id = SmartFieldId<List<String>>('contacts');
      await tester.pumpWidget(
        _app(
          SmartForm(
            controller: form,
            scrollToFirstError: false,
            focusFirstError: false,
            children: [
              SmartFieldArray<String>(
                fieldId: id,
                controller: rows,
                initialValue: const ['Ana', 'Dan'],
                itemValidators: [SmartValidators.required()],
                itemBuilder: (_, item, index) =>
                    Text('${item.id}: ${item.value}'),
              ),
            ],
          ),
        ),
      );
      final firstId = rows.items.first.id;
      rows.move(0, 1);
      await tester.pump();
      expect(rows.items.last.id, firstId);
      rows.add('');
      await tester.pump();
      final invalid = await form.validate();
      await tester.pumpAndSettle();
      expect(invalid.isValid, isFalse);
      expect(rows.items.last.errorText, isNotNull);
      rows.setValue(2, 'Mara');
      rows.removeAt(0);
      await tester.pump();
      final result = await form.validate();
      expect(result.valueFor(id), ['Ana', 'Mara']);
      form.reset();
      await tester.pump();
      expect(rows.values, ['Ana', 'Dan']);
      expect(form.isDirty, isFalse);
    },
  );
}

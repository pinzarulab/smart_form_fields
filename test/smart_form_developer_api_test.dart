import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

void main() {
  const emailId = SmartFieldId<String>('email');

  testWidgets('typed ids, accessors, model adapters, and baselines work', (
    tester,
  ) async {
    final controller = SmartFormController();
    final adapter = SmartFormAdapter<_Profile>(
      fromValues: (values) => _Profile(values.get(emailId) ?? ''),
      toValues: (model) => <Object, Object?>{emailId: model.email},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            controller: controller,
            children: const <Widget>[
              SmartTextField(fieldId: emailId, initialValue: 'old@example.com'),
            ],
          ),
        ),
      ),
    );

    final field = controller.field<String>(emailId);
    expect(field.fieldValue, 'old@example.com');

    controller.setInitialModel(const _Profile('api@example.com'), adapter);
    await tester.pump();
    expect(field.fieldValue, 'api@example.com');
    expect(field.value.isDirty, isFalse);
    expect(field.value.isTouched, isFalse);

    field.fieldValue = 'new@example.com';
    await tester.pump();
    expect(field.value.isDirty, isTrue);

    final typed = await controller.validateAs(adapter);
    expect(typed.value, const _Profile('new@example.com'));

    controller.dispose();
  });

  testWidgets('form-level messages resolve validator defaults', (tester) async {
    final controller = SmartFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            controller: controller,
            messages: const _Messages(),
            scrollToFirstError: false,
            focusFirstError: false,
            children: <Widget>[
              SmartTextField(
                fieldId: emailId,
                validators: <SmartValidator>[SmartValidators.required()],
              ),
            ],
          ),
        ),
      ),
    );

    final result = await controller.validate();
    await tester.pump();
    expect(result.errorOf(emailId), 'app-required');
    expect(find.text('app-required'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('structured submission applies handled backend errors', (
    tester,
  ) async {
    final controller = SmartFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            controller: controller,
            scrollToFirstError: false,
            focusFirstError: false,
            onSubmitResult: (_) async => const SmartSubmissionResult.rejected(
              fieldErrors: <String, String>{'email': 'Already used'},
              generalErrors: <String>['Registration rejected'],
              scrollToFirstError: false,
            ),
            children: const <Widget>[
              SmartTextField(fieldId: emailId, initialValue: 'a@example.com'),
            ],
          ),
        ),
      ),
    );

    await controller.submit();
    await tester.pump();
    expect(controller.submissionPhase, SmartSubmissionPhase.rejected);
    expect(controller.submissionGeneralErrors, <String>[
      'Registration rejected',
    ]);
    expect(
      controller.field(emailId).value.errorSource,
      SmartFieldErrorSource.server,
    );
    expect(find.text('Already used'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('conditional preserved values can be excluded while hidden', (
    tester,
  ) async {
    final controller = SmartFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            controller: controller,
            children: <Widget>[
              const SmartTextField(name: 'kind', initialValue: 'person'),
              SmartConditionalField(
                dependsOn: 'kind',
                hiddenBehavior: SmartHiddenFieldBehavior.preserveAndExclude,
                condition: (value, _) => value == 'business',
                child: const SmartTextField(
                  name: 'company',
                  initialValue: 'Acme',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(controller.fieldStatuses, contains('company'));
    expect(controller.values, isNot(contains('company')));

    controller.setValue<String>('kind', 'business');
    await tester.pumpAndSettle();
    expect(controller.values['company'], 'Acme');

    controller.setValue<String>('kind', 'person');
    await tester.pumpAndSettle();
    expect(controller.values, isNot(contains('company')));
    expect(controller.fieldStatuses['company']!.value, 'Acme');
    controller.dispose();
  });

  testWidgets('picker uses application-owned presentation callback', (
    tester,
  ) async {
    final controller = SmartFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm(
            controller: controller,
            children: <Widget>[
              SmartPickerField<String>(
                name: 'country',
                onPick: (_, _) async => 'md',
                displayBuilder: (_, value, _) => Text(value ?? 'Choose'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(controller.valueOf<String>('country'), 'md');
    expect(find.text('md'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('reveal hook runs before direct field focus', (tester) async {
    final controller = SmartFormController();
    var revealed = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartForm.withChild(
            controller: controller,
            onRevealField: (name) => revealed = name,
            child: const Column(
              children: <Widget>[SmartTextField(name: 'inside_tab')],
            ),
          ),
        ),
      ),
    );

    final future = controller.focusField('inside_tab');
    await tester.pump();
    await future;
    expect(revealed, 'inside_tab');
    controller.dispose();
  });

  test('schema can be extracted from a full response', () {
    final schema = SmartFormSchema.fromResponse(<String, Object?>{
      'data': <String, Object?>{
        'form': <String, Object?>{'schema_version': 2, 'fields': <Object?>[]},
      },
    });
    expect(schema.schemaVersion, 2);
    expect(schema.fields, isEmpty);
  });
}

final class _Profile {
  const _Profile(this.email);

  final String email;

  @override
  bool operator ==(Object other) => other is _Profile && other.email == email;

  @override
  int get hashCode => email.hashCode;
}

final class _Messages implements SmartFormMessages {
  const _Messages();

  @override
  String get required => 'app-required';

  @override
  String get invalidEmail => 'app-email';

  @override
  String exactLength(int expected) => 'exact-$expected';

  @override
  String minimumLength(int minimum) => 'min-length-$minimum';

  @override
  String maximumLength(int maximum) => 'max-length-$maximum';

  @override
  String get invalidPattern => 'app-pattern';

  @override
  String get invalidNumber => 'app-number';

  @override
  String minimumNumber(num minimum) => 'min-$minimum';

  @override
  String maximumNumber(num maximum) => 'max-$maximum';

  @override
  String get valuesDoNotMatch => 'app-match';
}

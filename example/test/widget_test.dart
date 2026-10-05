import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_form_fields_example/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders the example hub', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());

    expect(find.text('Package examples'), findsOneWidget);
    for (final title in const <String>[
      'Form workflows',
      'Registration form',
      'Typed developer API',
      'Item-driven form',
      'Class-defined form',
      'JSON API form',
      'Controller playground',
      'Custom error animation',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        250,
        scrollable: _pageScrollable(),
      );
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('workflow example validates sections and repeated contacts', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Form workflows');
    expect(find.text('mara@example.com'), findsOneWidget);
    final next = find.widgetWithText(FilledButton, 'Next step');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 2'), findsOneWidget);

    final add = find.widgetWithText(TextButton, 'Add contact');
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Save form');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Contact name is required'), findsWidgets);

    final contact = find.widgetWithText(TextField, 'Contact 2');
    await tester.ensureVisible(contact);
    await tester.enterText(contact, 'Dan');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Saved Mara with 2 contacts.'), findsOneWidget);
  });

  testWidgets('validates the item-driven form without deleting its draft', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Item-driven form');

    expect(find.text('Built entirely from field items'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Display name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Phone'), findsOneWidget);
    expect(find.text('Account type'), findsOneWidget);
    expect(find.text('Product updates'), findsOneWidget);

    final fillButton = find.widgetWithText(TextButton, 'Fill item sample');
    await tester.ensureVisible(fillButton);
    await tester.tap(fillButton);
    await tester.pump();

    expect(find.text('mara@example.com'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    final validateButton = find.widgetWithText(FilledButton, 'Validate items');
    await tester.tap(validateButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Items form is valid for Mara Ionescu: +37378059426'),
      findsOneWidget,
    );
    expect(find.text('Draft saved'), findsOneWidget);
  });

  testWidgets('autosaves and clears the item-driven draft', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Item-driven form');

    final nameField = find.widgetWithText(TextField, 'Display name');
    await tester.enterText(nameField, 'Draft name');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Draft saved'), findsOneWidget);

    final resetButton = find.widgetWithText(TextButton, 'Reset items');
    await tester.ensureVisible(resetButton);
    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    expect(find.text('No unfinished draft'), findsOneWidget);
    expect(find.text('Draft name'), findsNothing);
  });

  testWidgets('restores the item-driven draft after an app restart', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Item-driven form');

    await tester.enterText(
      find.widgetWithText(TextField, 'Display name'),
      'Restart-safe draft',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Draft saved'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Item-driven form');

    expect(find.text('Restart-safe draft'), findsOneWidget);
    expect(find.text('You have an unfinished item-form draft.'), findsNothing);
    expect(find.text('Draft saved'), findsOneWidget);
  });

  testWidgets('renders the registration example', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Registration form');

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'First name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Birth date'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Account type'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Company name'), findsNothing);
    expect(find.text('Product updates'), findsOneWidget);
  });

  testWidgets('shows validation errors for an empty submission', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Registration form');

    final submitButton = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Account type is required'), findsOneWidget);
  });

  testWidgets('validates email after focus leaves the field', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Registration form');

    final emailField = find.widgetWithText(TextField, 'Email');
    await tester.ensureVisible(emailField);
    await tester.tap(emailField);
    await tester.enterText(emailField, 'invalid');
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsNothing);

    final phoneField = find.widgetWithText(TextField, 'Phone');
    await tester.ensureVisible(phoneField);
    await tester.tap(phoneField);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('fills and validates the sample account', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Registration form');

    final fillButton = find.widgetWithText(TextButton, 'Fill sample');
    await tester.ensureVisible(fillButton);
    await tester.tap(fillButton);
    await tester.pumpAndSettle();

    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('Smart Moldova SRL'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    final submitButton = find.widgetWithText(FilledButton, 'Create account');
    await tester.tap(submitButton);
    await tester.pump();
    expect(find.text('Creating account...'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(
      find.text('Account data is valid for ana@example.com'),
      findsOneWidget,
    );
  });

  testWidgets('shows conditional company field for business accounts', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Registration form');

    expect(find.widgetWithText(TextField, 'Company name'), findsNothing);

    final accountType = find.text('Account type');
    await tester.ensureVisible(accountType);
    await tester.tap(accountType);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Business').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Company name'), findsOneWidget);
  });

  testWidgets('keeps both password errors visible after submission', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Registration form');

    final fillButton = find.widgetWithText(TextButton, 'Fill sample');
    await tester.ensureVisible(fillButton);
    await tester.tap(fillButton);
    await tester.pumpAndSettle();

    final passwordField = find.widgetWithText(TextField, 'Password');
    await tester.ensureVisible(passwordField);
    await tester.enterText(passwordField, 'admin');

    final confirmationField = find.widgetWithText(
      TextField,
      'Confirm password',
    );
    await tester.ensureVisible(confirmationField);
    await tester.enterText(confirmationField, 'different');

    final submitButton = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('builds and validates the JSON API example', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'JSON API form');

    expect(
      find.text('Rendered from a snake_case API response'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Work email'), findsOneWidget);
    expect(find.text('Accept API usage terms'), findsOneWidget);

    final fillButton = find.widgetWithText(TextButton, 'Fill JSON sample');
    await tester.scrollUntilVisible(
      fillButton,
      300,
      scrollable: _pageScrollable(),
    );
    await tester.tap(fillButton);
    await tester.pump();

    expect(find.text('api@example.com'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    final validateButton = find.widgetWithText(
      FilledButton,
      'Validate JSON form',
    );
    await tester.tap(validateButton);
    await tester.pump();
    expect(find.text('Validating JSON…'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.textContaining('JSON values:'), findsOneWidget);
  });

  testWidgets('builds and validates the API model class example', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Class-defined form');

    expect(find.text('Rendered from API model classes'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Display name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Confirm password'), findsOneWidget);

    final fillButton = find.widgetWithText(TextButton, 'Fill class sample');
    await tester.scrollUntilVisible(
      fillButton,
      300,
      scrollable: _pageScrollable(),
    );
    await tester.tap(fillButton);
    await tester.pump();

    final validateButton = find.widgetWithText(
      FilledButton,
      'Validate class form',
    );
    await tester.tap(validateButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Class schema values:'), findsOneWidget);
  });

  testWidgets('demonstrates controller and bottom-sheet operations', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Controller playground');

    expect(find.text('Imperative form controls'), findsOneWidget);
    expect(find.text('Disabled account ID'), findsOneWidget);

    final patchButton = find.widgetWithText(OutlinedButton, 'Patch values');
    await tester.scrollUntilVisible(
      patchButton,
      300,
      scrollable: _pageScrollable(),
    );
    await tester.tap(patchButton);
    await tester.pump();
    expect(find.text('Smart checkout'), findsOneWidget);

    final picker = find.text('Monthly');
    expect(picker, findsOneWidget);

    final field = find.text('Monthly').first;
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(find.text('Quarterly'), findsOneWidget);
    await tester.tap(find.text('Quarterly'));
    await tester.pumpAndSettle();
    expect(find.text('Quarterly'), findsOneWidget);

    final removeButton = find.widgetWithText(
      OutlinedButton,
      'Remove dynamic field',
    );
    await tester.ensureVisible(removeButton);
    await tester.tap(removeButton);
    await tester.pump();
    expect(
      find.widgetWithText(TextField, 'Dynamic referral code'),
      findsNothing,
    );
  });

  testWidgets('demonstrates custom error animation builder', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Custom error animation');

    expect(find.text('Application-owned error animation'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Display name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);

    final validateButton = find.widgetWithText(
      FilledButton,
      'Validate custom animation',
    );
    await tester.tap(validateButton);
    await tester.pump();

    expect(find.text('Display name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.byType(Transform), findsWidgets);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    final fillButton = find.widgetWithText(TextButton, 'Fill sample');
    await tester.ensureVisible(fillButton);
    await tester.tap(fillButton);
    await tester.pump();
    await tester.tap(validateButton);
    await tester.pumpAndSettle();

    expect(find.text('Custom animation form is valid.'), findsOneWidget);
  });

  testWidgets(
    'demonstrates typed developer API model form, accessors, and rejection',
    (tester) async {
      await tester.pumpWidget(const SmartFormFieldsExampleApp());
      await _openExample(tester, 'Typed developer API');

      expect(find.text('Mara Ionescu'), findsOneWidget);
      expect(find.text('mara@example.com'), findsOneWidget);
      expect(find.text('isDirty: false (none)'), findsOneWidget);

      // Test Set Email via Accessor button
      final setViaAccessorBtn = find.widgetWithText(
        OutlinedButton,
        'Set Email via Accessor',
      );
      await tester.ensureVisible(setViaAccessorBtn);
      await tester.tap(setViaAccessorBtn);
      await tester.pump();

      expect(find.text('dev@smartform.io'), findsWidgets);
      expect(find.text('isDirty: true (email)'), findsOneWidget);

      // Reset
      final resetBtn = find.widgetWithText(ActionChip, 'Reset Form');
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pump();
      expect(find.text('isDirty: false (none)'), findsOneWidget);

      // Server rejection test
      final emailField = find.widgetWithText(TextField, 'Email');
      await tester.ensureVisible(emailField);
      await tester.enterText(emailField, 'taken@example.com');
      await tester.pump();

      final submitBtn = find.byType(FilledButton).first;
      await tester.ensureVisible(submitBtn);

      await tester.tap(submitBtn);
      await tester.pump();
      expect(find.text('Saving Profile…'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(
        find.text('Email is already taken by another account.'),
        findsOneWidget,
      );
      expect(
        find.text('Server rejected registration: account conflict occurred.'),
        findsOneWidget,
      );
      expect(find.text('Phase: rejected'), findsOneWidget);
    },
  );

  testWidgets('demonstrates multi-step reveal hook navigation', (tester) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Typed developer API');

    // Switch to tab 2: Steps & Reveal
    await tester.tap(find.text('Steps & Reveal'));
    await tester.pumpAndSettle();

    expect(find.text('Step 1: Account Setup'), findsOneWidget);

    // Switch step to Step 2
    final step2Btn = find.widgetWithText(FilledButton, 'Step 2: Profile Info');
    await tester.tap(step2Btn);
    await tester.pumpAndSettle();

    expect(find.text('Step 2: Personal Details'), findsOneWidget);

    // Validate All Steps while on Step 2; Step 1 has invalid empty username & password
    final validateAllBtn = find.widgetWithText(
      FilledButton,
      'Validate All Steps',
    );
    await tester.tap(validateAllBtn);
    await tester.pumpAndSettle();

    // onRevealField should have automatically switched back to Step 1!
    expect(find.text('Step 1: Account Setup'), findsOneWidget);
    expect(find.text('Last revealed field: step_username'), findsOneWidget);
  });

  testWidgets('demonstrates convenience view items and schema fallback', (
    tester,
  ) async {
    await tester.pumpWidget(const SmartFormFieldsExampleApp());
    await _openExample(tester, 'Typed developer API');

    // Switch to tab 3: Items & Schemas
    await tester.tap(find.text('Items & Schemas'));
    await tester.pumpAndSettle();

    expect(find.text('Email View Item'), findsOneWidget);
    expect(find.text('Password View Item'), findsOneWidget);
    expect(find.text('Plan View Item'), findsOneWidget);
    expect(find.text('Picker View Item'), findsOneWidget);

    // Verify unknown field fallback builder
    final fallbackFinder = find.text(
      'Unknown field type "color_palette_picker" for "theme_color". '
      'Handled via SmartFormSchemaRegistry.unknownFieldBuilder fallback!',
    );
    await tester.scrollUntilVisible(
      fallbackFinder,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(fallbackFinder, findsOneWidget);
    expect(find.text('System Assigned ID (Read-Only)'), findsOneWidget);
  });
}

Future<void> _openExample(WidgetTester tester, String title) async {
  final link = find.text(title);
  await tester.scrollUntilVisible(link, 250, scrollable: _pageScrollable());
  await tester.tap(link);
  await tester.pumpAndSettle();
}

Finder _pageScrollable() {
  return find
      .descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      )
      .first;
}

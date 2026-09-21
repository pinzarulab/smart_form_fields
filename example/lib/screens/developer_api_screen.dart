import 'package:flutter/material.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

const _nameField = SmartFieldId<String>('display_name');
const _emailField = SmartFieldId<String>('email');
const _countryField = SmartFieldId<String>('country');
const _accountTypeField = SmartFieldId<String>('account_type');

class DeveloperApiExamplePage extends StatefulWidget {
  const DeveloperApiExamplePage({super.key});

  @override
  State<DeveloperApiExamplePage> createState() => _DeveloperApiExamplePageState();
}

class _DeveloperApiExamplePageState extends State<DeveloperApiExamplePage> {
  final _controller = SmartFormController();
  late final SmartFormAdapter<_Profile> _adapter = SmartFormAdapter<_Profile>(
    fromValues: (values) => _Profile(
      name: values.get(_nameField) ?? '',
      email: values.get(_emailField) ?? '',
      country: values.get(_countryField),
    ),
    toValues: (profile) => <Object, Object?>{
      _nameField: profile.name,
      _emailField: profile.email,
      _countryField: profile.country,
    },
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.setInitialModel(
          const _Profile(name: 'Mara Ionescu', email: 'mara@example.com', country: 'Moldova'),
          _adapter,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _pickCountry(BuildContext context, String? current) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final country in const <String>['Moldova', 'Romania', 'Ukraine'])
              ListTile(
                title: Text(country),
                trailing: country == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, country),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer API')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          SmartModelForm<_Profile>(
            controller: _controller,
            adapter: _adapter,
            onSubmitResult: (profile, _) async {
              if (profile.email == 'used@example.com') {
                return const SmartSubmissionResult.rejected(
                  fieldErrors: <String, String>{'email': 'This email is already used'},
                  generalErrors: <String>['Profile was not saved'],
                );
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${profile.name}')));
              }
              return const SmartSubmissionResult.success();
            },
            itemSeparatorHeight: 16,
            children: <Widget>[
              SmartTextField(
                fieldId: _nameField,
                decoration: const InputDecoration(labelText: 'Display name'),
                validators: <SmartValidator>[SmartValidators.required()],
              ),
              SizedBox(height: 16),
              SmartEmailField(
                fieldId: _emailField,
                required: true,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 16),

              SmartPickerField<String>(
                fieldId: _countryField,
                onPick: _pickCountry,
                displayBuilder: (_, value, _) => Text(value ?? 'Choose country'),
                decoration: const InputDecoration(labelText: 'Country'),
                validators: <SmartValueValidator<String>>[SmartValueValidators.required<String>()],
              ),
              SizedBox(height: 16),

              SmartDropdownField<String>(
                fieldId: _accountTypeField,
                items: const <String>['personal', 'business'],
                itemLabelBuilder: (value) => value,
                initialValue: 'personal',
                decoration: const InputDecoration(labelText: 'Account type'),
              ),
              SizedBox(height: 16),

              SmartConditionalField(
                dependsOn: _accountTypeField,
                hiddenBehavior: SmartHiddenFieldBehavior.preserveAndExclude,
                condition: (value, _) => value == 'business',
                child: SmartTextField(
                  name: 'company_name',
                  decoration: const InputDecoration(labelText: 'Company'),
                  validators: <SmartValidator>[SmartValidators.required()],
                ),
              ),
              SizedBox(height: 16),

              SmartFormValueBuilder<String>(
                controller: _controller,
                field: _emailField,
                builder: (_, state, _) => Text(
                  'Email state: dirty=${state.isDirty}, '
                  'validated=${state.hasValidated}',
                ),
              ),
              SizedBox(height: 16),

              SmartSubmitButton.builder(
                controller: _controller,
                onRejected: (_) {
                  final errors = _controller.submissionGeneralErrors;
                  if (errors.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errors.join('\n'))));
                  }
                },
                builder: (context, phase, onPressed) => FilledButton.icon(
                  onPressed: onPressed,
                  icon: phase == SmartSubmissionPhase.submitting
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(phase == SmartSubmissionPhase.submitting ? 'Saving…' : 'Save typed model'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _Profile {
  const _Profile({required this.name, required this.email, this.country});

  final String name;
  final String email;
  final String? country;
}

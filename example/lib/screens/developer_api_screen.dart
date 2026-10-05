import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

// Typed field identities used throughout Tab 1.
const _nameField = SmartFieldId<String>('display_name');
const _emailField = SmartFieldId<String>('email');
const _countryField = SmartFieldId<String>('country');
const _accountTypeField = SmartFieldId<String>('account_type');
const _companyField = SmartFieldId<String>('company_name');

/// Comprehensive showcase of the smart_form_fields 2.0 developer API.
class DeveloperApiExamplePage extends StatefulWidget {
  const DeveloperApiExamplePage({super.key});

  @override
  State<DeveloperApiExamplePage> createState() =>
      _DeveloperApiExamplePageState();
}

class _DeveloperApiExamplePageState extends State<DeveloperApiExamplePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer API (v2.0)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.tune), text: 'Model & State'),
            Tab(icon: Icon(Icons.layers_outlined), text: 'Steps & Reveal'),
            Tab(icon: Icon(Icons.widgets_outlined), text: 'Items & Schemas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          _ModelAndReactiveStateTab(),
          _MultiStepAndRevealTab(),
          _ItemsAndSchemasTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 1: MODEL FORM & REACTIVE STATE
// ---------------------------------------------------------------------------

final class _UserProfile {
  const _UserProfile({
    required this.name,
    required this.email,
    this.country,
    this.accountType = 'personal',
    this.companyName,
  });

  final String name;
  final String email;
  final String? country;
  final String accountType;
  final String? companyName;
}

class _CustomBrandedMessages implements SmartFormMessages {
  const _CustomBrandedMessages();

  @override
  String get required => 'This field is mandatory.';

  @override
  String get invalidEmail => 'Please enter a valid work or personal email.';

  @override
  String exactLength(int expected) => 'Must be exactly $expected characters.';

  @override
  String minimumLength(int minimum) => 'Requires at least $minimum characters.';

  @override
  String maximumLength(int maximum) => 'Cannot exceed $maximum characters.';

  @override
  String get invalidPattern => 'Format requirement not met.';

  @override
  String get invalidNumber => 'Please provide a valid number.';

  @override
  String minimumNumber(num minimum) => 'Must be at least $minimum.';

  @override
  String maximumNumber(num maximum) => 'Cannot exceed $maximum.';

  @override
  String get valuesDoNotMatch => 'Confirmation does not match.';
}

class _ModelAndReactiveStateTab extends StatefulWidget {
  const _ModelAndReactiveStateTab();

  @override
  State<_ModelAndReactiveStateTab> createState() =>
      _ModelAndReactiveStateTabState();
}

class _ModelAndReactiveStateTabState extends State<_ModelAndReactiveStateTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final SmartFormController _controller = SmartFormController();

  SmartHiddenFieldBehavior _hiddenBehavior =
      SmartHiddenFieldBehavior.preserveAndExclude;
  bool _useCustomMessages = false;

  late final SmartFormAdapter<_UserProfile> _adapter =
      SmartFormAdapter<_UserProfile>(
        fromValues: (values) => _UserProfile(
          name: values.get(_nameField) ?? '',
          email: values.get(_emailField) ?? '',
          country: values.get(_countryField),
          accountType: values.get(_accountTypeField) ?? 'personal',
          companyName: values.contains(_companyField)
              ? values.get(_companyField)
              : null,
        ),
        toValues: (user) => <Object, Object?>{
          _nameField: user.name,
          _emailField: user.email,
          _countryField: user.country,
          _accountTypeField: user.accountType,
          _companyField: user.companyName,
        },
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadBaselineModel() {
    if (!_controller.isAttached) return;
    _controller.setInitialModel(
      const _UserProfile(
        name: 'Mara Ionescu',
        email: 'mara@example.com',
        country: 'Moldova',
        accountType: 'personal',
      ),
      _adapter,
    );
  }

  void _patchDirtyValues() {
    _controller.patchValue(<String, Object?>{
      _nameField.name: 'Mara Ionescu-Popescu',
      _accountTypeField.name: 'business',
      _companyField.name: 'TechNord SRL',
    }, options: SmartValueUpdateOptions.patch);
  }

  Future<String?> _pickCountry(BuildContext context, String? current) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final country in const <String>[
              'Moldova',
              'Romania',
              'Ukraine',
              'Restricted Country',
            ])
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
    super.build(context);
    final theme = Theme.of(context);

    return SmartModelForm<_UserProfile>(
      controller: _controller,
      adapter: _adapter,
      initialValue: const _UserProfile(
        name: 'Mara Ionescu',
        email: 'mara@example.com',
        country: 'Moldova',
      ),
      messages: _useCustomMessages ? const _CustomBrandedMessages() : null,
      onSubmitResult: (user, rawResult) async {
        final messenger = ScaffoldMessenger.of(context);
        // Simulated backend submission handling
        await Future<void>.delayed(const Duration(milliseconds: 600));

        // Server-side conflict check demonstration
        if (user.email.toLowerCase() == 'taken@example.com') {
          return const SmartSubmissionResult.rejected(
            fieldErrors: <String, String>{
              'email': 'Email is already taken by another account.',
            },
            generalErrors: <String>[
              'Server rejected registration: account conflict occurred.',
            ],
          );
        }

        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Profile saved successfully: ${user.name} (${user.email})',
              ),
            ),
          );
        }
        return const SmartSubmissionResult.success();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Controls / Options Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Form Configuration & Baselines',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        ActionChip(
                          avatar: const Icon(Icons.refresh, size: 18),
                          label: const Text('Load Initial Model (Clean)'),
                          onPressed: _loadBaselineModel,
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.edit_note, size: 18),
                          label: const Text('Patch Values (Dirty)'),
                          onPressed: _patchDirtyValues,
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.restart_alt, size: 18),
                          label: const Text('Reset Form'),
                          onPressed: () => _controller.reset(),
                        ),
                        FilterChip(
                          label: const Text('Custom Branded Messages'),
                          selected: _useCustomMessages,
                          onSelected: (val) {
                            setState(() => _useCustomMessages = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Conditional Hidden Policy:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: SmartHiddenFieldBehavior.values.map((behavior) {
                        return ChoiceChip(
                          label: Text(behavior.name),
                          selected: _hiddenBehavior == behavior,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _hiddenBehavior = behavior);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Form fields
            SmartTextField(
              fieldId: _nameField,
              decoration: const InputDecoration(
                labelText: 'Display name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validators: <SmartValidator>[SmartValidators.required()],
            ),
            const SizedBox(height: 16),

            SmartEmailField(
              fieldId: _emailField,
              required: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                helperText: 'Try "taken@example.com" to see backend rejection',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              asyncValidationDebounce: const Duration(milliseconds: 300),
              asyncValidators: <SmartAsyncValidator<String>>[
                // Cooperative controlled async validator demonstration
                SmartAsyncValidators.controlled<String>(
                  validator: (value, context) async {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    await Future<void>.delayed(
                      const Duration(milliseconds: 400),
                    );
                    context.throwIfCancelled();
                    if (value.toLowerCase() == 'taken_async@example.com') {
                      return 'Taken asynchronously!';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            SmartPickerField<String>(
              fieldId: _countryField,
              onPick: _pickCountry,
              displayBuilder: (_, value, _) => Row(
                children: <Widget>[
                  Icon(
                    Icons.flag_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(value ?? 'Choose Country (Bottom Sheet)'),
                ],
              ),
              decoration: const InputDecoration(labelText: 'Country'),
              validators: <SmartValueValidator<String>>[
                SmartValueValidators.required<String>(),
              ],
            ),
            const SizedBox(height: 16),

            SmartDropdownField<String>(
              fieldId: _accountTypeField,
              items: const <String>['personal', 'business'],
              itemLabelBuilder: (value) =>
                  value == 'business' ? 'Business Account' : 'Personal Account',
              initialValue: 'personal',
              decoration: const InputDecoration(
                labelText: 'Account type',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // SmartConditionalField with multi-field dependencies
            SmartConditionalField(
              dependsOn: _accountTypeField,
              dependsOnFields: <Object>{_countryField},
              hiddenBehavior: _hiddenBehavior,
              condition: (value, context) {
                final country = context.valueOf<String>(_countryField.name);
                return value == 'business' && country != 'Restricted Country';
              },
              child: SmartTextField(
                fieldId: _companyField,
                decoration: const InputDecoration(
                  labelText: 'Company name',
                  helperText:
                      'Visible for Business (except Restricted Country)',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validators: <SmartValidator>[SmartValidators.required()],
              ),
            ),
            const SizedBox(height: 24),

            // SmartSubmitButton.builder
            SmartSubmitButton.builder(
              controller: _controller,
              builder: (context, phase, onPressed) {
                final isBusy =
                    phase == SmartSubmissionPhase.validating ||
                    phase == SmartSubmissionPhase.submitting;

                return FilledButton.icon(
                  onPressed: onPressed,
                  icon: isBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    isBusy
                        ? 'Saving Profile…'
                        : 'Submit Typed Model (SmartSubmitButton.builder)',
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Live Field Accessor & ValueBuilder Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Email Field Accessor & ValueBuilder',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SmartFormValueBuilder<String>(
                      controller: _controller,
                      field: _emailField,
                      builder: (context, snapshot, _) {
                        final source = snapshot.errorSource?.name ?? 'none';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Current Value: "${snapshot.value ?? ''}"'),
                            Text(
                              'dirty: ${snapshot.isDirty} | '
                              'touched: ${snapshot.isTouched} | '
                              'validated: ${snapshot.hasValidated} | '
                              'validating: ${snapshot.isValidating}',
                              style: theme.textTheme.bodySmall,
                            ),
                            if (snapshot.errorText != null)
                              Text(
                                'Error: ${snapshot.errorText} (source: $source)',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: () {
                            final emailAccessor = _controller.field(
                              _emailField,
                            );
                            emailAccessor.validate();
                          },
                          child: const Text('Validate Email Accessor'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            final emailAccessor = _controller.field(
                              _emailField,
                            );
                            emailAccessor.fieldValue = 'dev@smartform.io';
                          },
                          child: const Text('Set Email via Accessor'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            _controller.field(_emailField).focus();
                          },
                          child: const Text('Focus Email'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Aggregate Form Status via SmartFormStatusBuilder
            SmartFormStatusBuilder(
              controller: _controller,
              builder: (context, controller) {
                final generalErrors = controller.submissionGeneralErrors;
                return Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.insights,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SmartFormStatusBuilder Overview',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Chip(
                              label: Text(
                                'Phase: ${controller.submissionPhase.name}',
                                style: theme.textTheme.labelSmall,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'isDirty: ${controller.isDirty} '
                          '(${controller.dirtyFields.isEmpty ? 'none' : controller.dirtyFields.join(', ')})',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          'isValidating: ${controller.isValidating} '
                          '(${controller.validatingFields.isEmpty ? 'none' : controller.validatingFields.join(', ')})',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (generalErrors.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.onErrorContainer,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    generalErrors.join('\n'),
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 2: MULTI-STEP & ARBITRARY LAYOUT WITH REVEAL HOOKS
// ---------------------------------------------------------------------------

class _MultiStepAndRevealTab extends StatefulWidget {
  const _MultiStepAndRevealTab();

  @override
  State<_MultiStepAndRevealTab> createState() => _MultiStepAndRevealTabState();
}

class _MultiStepAndRevealTabState extends State<_MultiStepAndRevealTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final SmartFormController _stepController = SmartFormController();
  int _activeStep = 0;
  String? _lastRevealedField;

  static const _step1Fields = <String>{'step_username', 'step_password'};
  static const _step2Fields = <String>{'step_fullname', 'step_bio'};

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  void _onRevealField(String fieldName) {
    setState(() {
      _lastRevealedField = fieldName;
      if (_step1Fields.contains(fieldName)) {
        _activeStep = 0;
      } else if (_step2Fields.contains(fieldName)) {
        _activeStep = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Arbitrary Layout & Reveal Navigation',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'SmartForm.withChild wraps custom containers. '
                    'When validation fails on a hidden step or tab, onRevealField '
                    'is invoked before scrolling & focus!',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (_lastRevealedField != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      'Last revealed field: $_lastRevealedField',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stepper / Tab header
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: _activeStep == 0
                        ? theme.colorScheme.primaryContainer
                        : null,
                  ),
                  onPressed: () => setState(() => _activeStep = 0),
                  child: const Text('Step 1: Credentials'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: _activeStep == 1
                        ? theme.colorScheme.primaryContainer
                        : null,
                  ),
                  onPressed: () => setState(() => _activeStep = 1),
                  child: const Text('Step 2: Profile Info'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // SmartForm.withChild wrapping step content
          SmartForm.withChild(
            controller: _stepController,
            onRevealField: _onRevealField,
            padding: const EdgeInsets.all(8),
            child: IndexedStack(
              index: _activeStep,
              children: <Widget>[
                // Step 1
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Step 1: Account Setup',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    SmartTextField(
                      name: 'step_username',
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validators: <SmartValidator>[SmartValidators.required()],
                    ),
                    const SizedBox(height: 16),
                    SmartPasswordField(
                      name: 'step_password',
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      minLength: 6,
                    ),
                  ],
                ),
                // Step 2
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Step 2: Personal Details',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    SmartTextField(
                      name: 'step_fullname',
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validators: <SmartValidator>[SmartValidators.required()],
                    ),
                    const SizedBox(height: 16),
                    SmartTextField(
                      name: 'step_bio',
                      decoration: const InputDecoration(
                        labelText: 'Short Bio',
                        prefixIcon: Icon(Icons.description),
                      ),
                      validators: <SmartValidator>[SmartValidators.required()],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit & Validate Buttons
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      setState(() => _activeStep = (_activeStep == 0 ? 1 : 0)),
                  child: Text(
                    _activeStep == 0 ? 'Go to Step 2' : 'Back to Step 1',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final result = await _stepController.validate();
                    if (result.isValid && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All steps valid and verified!'),
                        ),
                      );
                    }
                  },
                  child: const Text('Validate All Steps'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 3: CONVENIENCE VIEW ITEMS & REUSABLE SCHEMA REGISTRY
// ---------------------------------------------------------------------------

class _ItemsAndSchemasTab extends StatefulWidget {
  const _ItemsAndSchemasTab();

  @override
  State<_ItemsAndSchemasTab> createState() => _ItemsAndSchemasTabState();
}

class _ItemsAndSchemasTabState extends State<_ItemsAndSchemasTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final SmartFormController _itemsController = SmartFormController();
  final SmartFormController _schemaController = SmartFormController();

  late final SmartEmailFieldViewItem _emailItem = SmartEmailFieldViewItem(
    name: 'item_email',
    required: true,
    decoration: const InputDecoration(
      labelText: 'Email View Item',
      prefixIcon: Icon(Icons.mail_outline),
    ),
  );

  late final SmartPasswordFieldViewItem _passwordItem =
      SmartPasswordFieldViewItem(
        name: 'item_password',
        required: true,
        minLength: 8,
        decoration: const InputDecoration(
          labelText: 'Password View Item',
          prefixIcon: Icon(Icons.key_outlined),
        ),
      );

  late final SmartDateFieldViewItem _dateItem = SmartDateFieldViewItem(
    name: 'item_date',
    firstDate: DateTime(1900),
    lastDate: DateTime(2030),
    initialValue: DateTime(2000, 1, 1),
    decoration: const InputDecoration(
      labelText: 'Date View Item',
      prefixIcon: Icon(Icons.calendar_today_outlined),
    ),
  );

  late final SmartDropdownFieldViewItem<String> _dropdownItem =
      SmartDropdownFieldViewItem<String>(
        name: 'item_plan',
        items: const <String>['Starter', 'Professional', 'Enterprise'],
        itemLabelBuilder: (val) => '$val Plan',
        initialValue: 'Professional',
        decoration: const InputDecoration(
          labelText: 'Plan View Item',
          prefixIcon: Icon(Icons.workspace_premium_outlined),
        ),
      );

  late final SmartPickerFieldViewItem<String> _pickerItem =
      SmartPickerFieldViewItem<String>(
        name: 'item_region',
        initialValue: 'Europe-Central',
        onPick: (context, current) async {
          return await showDialog<String>(
            context: context,
            builder: (dialogCtx) => SimpleDialog(
              title: const Text('Select Deployment Region'),
              children: <Widget>[
                for (final region in const <String>[
                  'US-East',
                  'US-West',
                  'Europe-Central',
                  'Asia-Pacific',
                ])
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(dialogCtx, region),
                    child: Text(region),
                  ),
              ],
            ),
          );
        },
        displayBuilder: (context, val, _) => Text(val ?? 'Select region'),
        decoration: const InputDecoration(
          labelText: 'Picker View Item',
          prefixIcon: Icon(Icons.dns_outlined),
        ),
      );

  late final SmartConditionalFieldViewItem _conditionalItem =
      SmartConditionalFieldViewItem(
        dependsOn: 'item_plan',
        condition: (val, _) => val == 'Enterprise',
        child: SmartTextFieldViewItem(
          name: 'item_custom_sla',
          decoration: const InputDecoration(
            labelText: 'Enterprise SLA Level',
            prefixIcon: Icon(Icons.handshake_outlined),
          ),
        ),
      );

  @override
  void dispose() {
    _emailItem.dispose();
    _passwordItem.dispose();
    _itemsController.dispose();
    _schemaController.dispose();
    super.dispose();
  }

  // Simulated full API response with schema version, read-only field, and unknown field type
  static const _mockApiResponse = <String, Object?>{
    'status': 'ok',
    'timestamp': 1716300000,
    'data': <String, Object?>{
      'form_payload': <String, Object?>{
        'schema_version': 2,
        'scroll_to_first_error': true,
        'fields': <Object?>[
          <String, Object?>{
            'type': 'text',
            'name': 'api_assigned_id',
            'label_text': 'System Assigned ID (Read-Only)',
            'initial_value': 'SYS-99482',
            'read_only': true,
          },
          <String, Object?>{
            'type': 'color_palette_picker', // Unregistered custom type
            'name': 'theme_color',
            'label_text': 'App Theme Color',
          },
          <String, Object?>{
            'type': 'text',
            'name': 'org_name',
            'label_text': 'Organization Name',
            'required': true,
          },
        ],
      },
    },
  };

  late final SmartFormSchemaRegistry _schemaRegistry = SmartFormSchemaRegistry(
    unknownFieldBuilder: (context, fieldDef, validators, asyncValidators) {
      return Card(
        color: Colors.amber.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Icon(Icons.help_outline, color: Colors.amber.shade900),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unknown field type "${fieldDef.type}" for "${fieldDef.name}". '
                  'Handled via SmartFormSchemaRegistry.unknownFieldBuilder fallback!',
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'SmartForm.withItems & Convenience View Items',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Render forms declaratively from SmartFieldViewItem instances '
                    '(email, password, date, dropdown, picker, conditional) with itemSeparatorBuilder.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          SmartForm.withItems(
            controller: _itemsController,
            itemSeparatorBuilder: (context, index) => const Divider(height: 24),
            items: <SmartFieldViewItem>[
              _emailItem,
              _passwordItem,
              _dateItem,
              _dropdownItem,
              _pickerItem,
              _conditionalItem,
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final res = await _itemsController.validate();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res.isValid
                          ? 'View items form valid! Email: ${_emailItem.text}'
                          : 'View items validation failed with ${res.errors.length} error(s)',
                    ),
                  ),
                );
              }
            },
            child: const Text('Validate View Items Form'),
          ),
          const SizedBox(height: 32),

          // Schema Registry and Extraction from Full Response
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'SmartSchemaForm.fromResponse & Registry',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Extracts schema from nested API response path '
                    '["data", "form_payload"], supports schema_version: 2, '
                    'read_only fields, and unknown-field fallback builder.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          SmartSchemaForm.fromResponse(
            controller: _schemaController,
            response: _mockApiResponse,
            path: const <Object>['data', 'form_payload'],
            registry: _schemaRegistry,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              final res = await _schemaController.validate();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res.isValid
                          ? 'Schema form valid: ${res.values}'
                          : 'Schema form has ${res.errors.length} error(s)',
                    ),
                  ),
                );
              }
            },
            child: const Text('Validate Schema Response Form'),
          ),
        ],
      ),
    );
  }
}

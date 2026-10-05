import 'package:flutter/material.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

class WorkflowFormExamplePage extends StatefulWidget {
  const WorkflowFormExamplePage({super.key});

  @override
  State<WorkflowFormExamplePage> createState() =>
      _WorkflowFormExamplePageState();
}

class _WorkflowFormExamplePageState extends State<WorkflowFormExamplePage> {
  final _form = SmartFormController();
  final _contacts = SmartFieldArrayController<String>();
  int _step = 0;
  Map<String, Object?> _initial = const {
    'name': 'Mara',
    'email': 'mara@example.com',
    'country': 'Moldova',
  };
  String _message = 'Edit a field, refresh API data, or add contact rows.';

  @override
  void dispose() {
    _form.dispose();
    _contacts.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final result = await _form.validateSection(
      'identity',
      scrollToError: false,
      focusFirstError: false,
    );
    if (mounted && result.isValid) setState(() => _step = 1);
  }

  Future<void> _submit() async {
    final result = await _form.submit();
    if (!mounted) return;
    setState(
      () => _message = result.isSuccess
          ? 'Saved ${result.text('name')} with ${result.valueOf<List<String>>('contacts')!.length} contacts.'
          : result.error != null
          ? 'Submission failed: ${result.error}'
          : result.generalErrors.isNotEmpty
          ? result.generalErrors.join('\n')
          : 'Fix the highlighted fields.',
    );
  }

  Future<SmartPickerResult<String>> _pickCountry(
    BuildContext context,
    String? value,
  ) async {
    return await showModalBottomSheet<SmartPickerResult<String>>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final country in ['Moldova', 'Romania', 'Ukraine'])
                  ListTile(
                    title: Text(country),
                    onTap: () => Navigator.pop(
                      context,
                      SmartPickerResult.selected(country),
                    ),
                  ),
                ListTile(
                  title: const Text('Clear country'),
                  onTap: () => Navigator.pop(
                    context,
                    const SmartPickerResult<String>.cleared(),
                  ),
                ),
              ],
            ),
          ),
        ) ??
        const SmartPickerResult.cancelled();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Form workflows (v3)')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: SmartForm(
        controller: _form,
        initialValues: _initial,
        preserveDirtyFields: true,
        lockWhileSubmitting: true,
        onRevealField: (name) {
          setState(() => _step = name == 'contacts' ? 1 : 0);
        },
        onSubmitResult: (result) async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          if (result.text('email') == 'used@example.com') {
            return const SmartSubmissionResult.rejected(
              fieldErrors: {'email': 'Email is already registered'},
              generalErrors: ['Use a different email address.'],
            );
          }
          return const SmartSubmissionResult.success();
        },
        children: [
          Text(
            'Step ${_step + 1} of 2',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          IndexedStack(
            index: _step,
            children: [
              SmartFormSection(
                name: 'identity',
                child: Column(
                  children: [
                    SmartTextField(
                      name: 'name',
                      validators: [SmartValidators.required()],
                      decoration: const InputDecoration(labelText: 'Name'),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _form.focusNext(),
                    ),
                    const SizedBox(height: 16),
                    SmartEmailField(
                      name: 'email',
                      required: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        helperText:
                            'Use used@example.com to see a backend rejection.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SmartPickerField<String>(
                      name: 'country',
                      allowClear: true,
                      onPickResult: _pickCountry,
                      decoration: const InputDecoration(labelText: 'Country'),
                      displayBuilder: (_, value, _) =>
                          Text(value ?? 'Choose country'),
                    ),
                  ],
                ),
              ),
              SmartFormSection(
                name: 'contacts',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Additional contact names'),
                    const SizedBox(height: 12),
                    SmartFieldArray<String>(
                      name: 'contacts',
                      controller: _contacts,
                      initialValue: const ['Ana'],
                      itemValidators: [
                        SmartValidators.required(
                          message: 'Contact name is required',
                        ),
                      ],
                      itemBuilder: (_, item, index) => Row(
                        children: [
                          Expanded(
                            child: _ContactEditor(item: item, index: index),
                          ),
                          IconButton(
                            tooltip: 'Move contact up',
                            icon: const Icon(Icons.arrow_upward),
                            onPressed: index > 0 && !item.readOnly
                                ? () => _contacts.move(index, index - 1)
                                : null,
                          ),
                          IconButton(
                            tooltip: 'Remove contact',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: item.readOnly
                                ? null
                                : () => _contacts.removeAt(index),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _contacts.add(''),
                      icon: const Icon(Icons.add),
                      label: const Text('Add contact'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SmartFormStatusBuilder(
            controller: _form,
            builder: (_, state) => Column(
              children: [
                Text(
                  'Changed: ${state.dirtyFields.join(', ')}\n'
                  'Validated: ${state.hasValidated} · Ready: ${state.canSubmit}',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_step == 1)
                      TextButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () => setState(() => _step = 0),
                        child: const Text('Back'),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: state.isSubmitting
                          ? null
                          : _step == 0
                          ? _next
                          : _submit,
                      child: Text(
                        state.isSubmitting
                            ? 'Saving…'
                            : _step == 0
                            ? 'Next step'
                            : 'Save form',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => setState(
                  () => _initial = {
                    'name': 'Updated API name',
                    'email': 'updated@example.com',
                    'country': 'Romania',
                  },
                ),
                child: const Text('Refresh API (keep edits)'),
              ),
              TextButton(
                onPressed: _form.reset,
                child: const Text('Reset form'),
              ),
              TextButton(
                onPressed: () => _form.resetField('email'),
                child: const Text('Reset email'),
              ),
            ],
          ),
          Text(_message),
        ],
      ),
    ),
  );
}

class _ContactEditor extends StatefulWidget {
  const _ContactEditor({required this.item, required this.index});
  final SmartArrayItem<String> item;
  final int index;

  @override
  State<_ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<_ContactEditor> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.item.value);
    widget.item.addListener(_sync);
  }

  void _sync() {
    if (_text.text != widget.item.value) _text.text = widget.item.value;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.item.removeListener(_sync);
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _text,
    focusNode: widget.item.focusNode,
    readOnly: widget.item.readOnly,
    onChanged: widget.item.setValue,
    decoration: InputDecoration(
      labelText: 'Contact ${widget.index + 1}',
      errorText: widget.item.errorText,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/family_tree_provider.dart';
import '../../models/index.dart';
import '../responsive_screen.dart';

/// Tạo mới (existing == null) hoặc sửa thông tin 1 Person trong cây
/// [familyTreeId] đang mở.
Future<void> showPersonFormModal(
  BuildContext context, {
  required String familyTreeId,
  Person? existing,
}) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));
  final provider = context.read<FamilyTreeProvider>();
  final content = ChangeNotifierProvider.value(
    value: provider,
    child: _PersonFormContent(familyTreeId: familyTreeId, existing: existing),
  );

  if (isDesktop) {
    return showDialog<void>(context: context, builder: (context) => Dialog(child: content));
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: content,
    ),
  );
}

class _PersonFormContent extends StatefulWidget {
  const _PersonFormContent({required this.familyTreeId, this.existing});

  final String familyTreeId;
  final Person? existing;

  @override
  State<_PersonFormContent> createState() => _PersonFormContentState();
}

class _PersonFormContentState extends State<_PersonFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.existing?.fullName);
  late final TextEditingController _placeOfBirthController =
      TextEditingController(text: widget.existing?.placeOfBirth);
  late final TextEditingController _noteController =
      TextEditingController(text: widget.existing?.note);

  late Gender _gender = widget.existing?.gender ?? Gender.male;
  late DateTime? _birthDate = widget.existing?.birthDate;
  late bool _isDeceased = widget.existing?.isDeceased ?? false;
  late DateTime? _deathDate = widget.existing?.deathDate;
  late DateTime? _memorialDate = widget.existing?.memorialDate;

  @override
  void dispose() {
    _nameController.dispose();
    _placeOfBirthController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(now.year - 30),
      firstDate: DateTime(1850),
      lastDate: now,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<FamilyTreeProvider>();
    final name = _nameController.text.trim();
    final placeOfBirth = _placeOfBirthController.text.trim();
    final note = _noteController.text.trim();

    if (widget.existing == null) {
      await provider.addPerson(Person.create(
        familyTreeId: widget.familyTreeId,
        fullName: name,
        gender: _gender,
        birthDate: _birthDate,
        isDeceased: _isDeceased,
        deathDate: _isDeceased ? _deathDate : null,
        memorialDate: _isDeceased ? _memorialDate : null,
        placeOfBirth: placeOfBirth.isEmpty ? null : placeOfBirth,
        note: note.isEmpty ? null : note,
      ));
    } else {
      await provider.updatePerson(widget.existing!.copyWith(
        fullName: name,
        gender: _gender,
        birthDate: _birthDate,
        isDeceased: _isDeceased,
        deathDate: _isDeceased ? _deathDate : null,
        memorialDate: _isDeceased ? _memorialDate : null,
        placeOfBirth: placeOfBirth.isEmpty ? null : placeOfBirth,
        note: note.isEmpty ? null : note,
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = MaterialLocalizations.of(context).formatMediumDate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? l10n.addPerson : l10n.editPerson,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.fullName),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Gender>(
              initialValue: _gender,
              decoration: InputDecoration(labelText: l10n.gender),
              items: [
                DropdownMenuItem(value: Gender.male, child: Text(l10n.genderMale)),
                DropdownMenuItem(value: Gender.female, child: Text(l10n.genderFemale)),
                DropdownMenuItem(value: Gender.other, child: Text(l10n.genderOther)),
              ],
              onChanged: (value) => setState(() => _gender = value ?? _gender),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.birthDate),
              subtitle: Text(_birthDate != null ? dateFormat(_birthDate!) : '—'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await _pickDate(_birthDate);
                if (picked != null) setState(() => _birthDate = picked);
              },
            ),
            TextFormField(
              controller: _placeOfBirthController,
              decoration: InputDecoration(labelText: l10n.placeOfBirth),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.isDeceased),
              value: _isDeceased,
              onChanged: (value) => setState(() => _isDeceased = value),
            ),
            if (_isDeceased) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.deathDate),
                subtitle: Text(_deathDate != null ? dateFormat(_deathDate!) : '—'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await _pickDate(_deathDate);
                  if (picked != null) setState(() => _deathDate = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.memorialDate),
                subtitle: Text(_memorialDate != null ? dateFormat(_memorialDate!) : '—'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await _pickDate(_memorialDate);
                  if (picked != null) setState(() => _memorialDate = picked);
                },
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(labelText: l10n.note),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _submit, child: Text(l10n.save)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

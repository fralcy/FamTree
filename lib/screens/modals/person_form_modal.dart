import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/family_tree_provider.dart';
import '../../core/widgets/gender_dropdown.dart';
import '../../core/widgets/lunar_date_field.dart';
import '../../core/widgets/modal_shell.dart';
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
  late LunarDate? _birthDate = widget.existing?.birthDate;
  late bool _isDeceased = widget.existing?.isDeceased ?? false;
  late LunarDate? _deathDate = widget.existing?.deathDate;
  late LunarDate? _memorialDate = widget.existing?.memorialDate;

  @override
  void dispose() {
    _nameController.dispose();
    _placeOfBirthController.dispose();
    _noteController.dispose();
    super.dispose();
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
        clearBirthDate: _birthDate == null,
        isDeceased: _isDeceased,
        deathDate: _isDeceased ? _deathDate : null,
        clearDeathDate: !_isDeceased || _deathDate == null,
        memorialDate: _isDeceased ? _memorialDate : null,
        clearMemorialDate: !_isDeceased || _memorialDate == null,
        placeOfBirth: placeOfBirth.isEmpty ? null : placeOfBirth,
        note: note.isEmpty ? null : note,
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: ModalShell(
        title: widget.existing == null ? l10n.addPerson : l10n.editPerson,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          FilledButton(onPressed: _submit, child: Text(l10n.save)),
        ],
        children: [
          ResponsiveFieldRow(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.fullName, isDense: true),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
                autofocus: true,
              ),
              GenderDropdown(
                value: _gender,
                onChanged: (value) => setState(() => _gender = value ?? _gender),
              ),
            ],
          ),
          LunarDateField(
            label: l10n.birthDate,
            value: _birthDate,
            onChanged: (v) => setState(() => _birthDate = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _placeOfBirthController,
            decoration: InputDecoration(labelText: l10n.placeOfBirth, isDense: true),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.isDeceased),
            value: _isDeceased,
            onChanged: (value) => setState(() => _isDeceased = value),
          ),
          if (_isDeceased) ...[
            const SizedBox(height: 8),
            LunarDateField(
              label: l10n.deathDate,
              value: _deathDate,
              onChanged: (v) => setState(() => _deathDate = v),
            ),
            const SizedBox(height: 12),
            LunarDateField(
              label: l10n.memorialDate,
              value: _memorialDate,
              onChanged: (v) => setState(() => _memorialDate = v),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            decoration: InputDecoration(labelText: l10n.note, isDense: true),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

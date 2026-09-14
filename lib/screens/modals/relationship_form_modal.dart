import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/family_tree_provider.dart';
import '../../models/index.dart';
import '../responsive_screen.dart';

enum RelationshipModalKind { spouse, child, parent }

/// Thêm 1 quan hệ mới xuất phát từ [anchor]:
/// - [RelationshipModalKind.spouse]: tạo marriage(anchor, người chọn/mới).
/// - [RelationshipModalKind.child]: tạo parentChild(anchor -> người chọn/mới).
/// - [RelationshipModalKind.parent]: tạo parentChild(người chọn/mới -> anchor).
Future<void> showRelationshipFormModal(
  BuildContext context, {
  required String familyTreeId,
  required Person anchor,
  required RelationshipModalKind kind,
}) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));
  final provider = context.read<FamilyTreeProvider>();
  final content = ChangeNotifierProvider.value(
    value: provider,
    child: _RelationshipFormContent(familyTreeId: familyTreeId, anchor: anchor, kind: kind),
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

class _RelationshipFormContent extends StatefulWidget {
  const _RelationshipFormContent({
    required this.familyTreeId,
    required this.anchor,
    required this.kind,
  });

  final String familyTreeId;
  final Person anchor;
  final RelationshipModalKind kind;

  @override
  State<_RelationshipFormContent> createState() => _RelationshipFormContentState();
}

class _RelationshipFormContentState extends State<_RelationshipFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _newNameController = TextEditingController();

  bool _useExisting = false;
  String? _selectedPersonId;
  Gender _newGender = Gender.male;
  ChildType _childType = ChildType.biological;
  DateTime? _marriageStart;
  DateTime? _marriageEnd;

  @override
  void dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  List<Person> _selectablePersons(FamilyTreeProvider provider) {
    final excludedIds = <String>{widget.anchor.id};
    if (widget.kind == RelationshipModalKind.spouse) {
      excludedIds.addAll(provider.spousesOf(widget.anchor.id).map((p) => p.id));
    } else if (widget.kind == RelationshipModalKind.child) {
      excludedIds.addAll(provider.childrenOf(widget.anchor.id).map((p) => p.id));
    } else {
      excludedIds.addAll(provider.parentsOf(widget.anchor.id).map((p) => p.id));
    }
    return provider.persons.where((p) => !excludedIds.contains(p.id)).toList();
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(1850),
      lastDate: now,
    );
  }

  Future<void> _submit(FamilyTreeProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    String otherPersonId;
    if (_useExisting) {
      if (_selectedPersonId == null) return;
      otherPersonId = _selectedPersonId!;
    } else {
      final newPerson = Person.create(
        familyTreeId: widget.familyTreeId,
        fullName: _newNameController.text.trim(),
        gender: _newGender,
      );
      await provider.addPerson(newPerson);
      otherPersonId = newPerson.id;
    }

    switch (widget.kind) {
      case RelationshipModalKind.spouse:
        await provider.addRelationship(Relationship.createMarriage(
          familyTreeId: widget.familyTreeId,
          personAId: widget.anchor.id,
          personBId: otherPersonId,
          startDate: _marriageStart,
          endDate: _marriageEnd,
        ));
      case RelationshipModalKind.child:
        await provider.addRelationship(Relationship.createParentChild(
          familyTreeId: widget.familyTreeId,
          parentId: widget.anchor.id,
          childId: otherPersonId,
          childType: _childType,
        ));
      case RelationshipModalKind.parent:
        await provider.addRelationship(Relationship.createParentChild(
          familyTreeId: widget.familyTreeId,
          parentId: otherPersonId,
          childId: widget.anchor.id,
          childType: _childType,
        ));
    }

    if (mounted) Navigator.of(context).pop();
  }

  String _titleFor(AppLocalizations l10n) {
    switch (widget.kind) {
      case RelationshipModalKind.spouse:
        return l10n.addSpouse;
      case RelationshipModalKind.child:
        return l10n.addChild;
      case RelationshipModalKind.parent:
        return l10n.addParent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<FamilyTreeProvider>();
    final selectable = _selectablePersons(provider);
    final dateFormat = MaterialLocalizations.of(context).formatMediumDate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_titleFor(l10n), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.addPerson)),
                ButtonSegment(value: true, label: Text(l10n.selectPerson)),
              ],
              selected: {_useExisting},
              onSelectionChanged: (selection) =>
                  setState(() => _useExisting = selection.first),
            ),
            const SizedBox(height: 12),
            if (_useExisting)
              DropdownButtonFormField<String>(
                initialValue: _selectedPersonId,
                decoration: InputDecoration(labelText: l10n.selectPerson),
                items: [
                  for (final p in selectable)
                    DropdownMenuItem(value: p.id, child: Text(p.fullName)),
                ],
                onChanged: (value) => setState(() => _selectedPersonId = value),
                validator: (value) => value == null ? l10n.fieldRequired : null,
              )
            else ...[
              TextFormField(
                controller: _newNameController,
                decoration: InputDecoration(labelText: l10n.fullName),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Gender>(
                initialValue: _newGender,
                decoration: InputDecoration(labelText: l10n.gender),
                items: [
                  DropdownMenuItem(value: Gender.male, child: Text(l10n.genderMale)),
                  DropdownMenuItem(value: Gender.female, child: Text(l10n.genderFemale)),
                  DropdownMenuItem(value: Gender.other, child: Text(l10n.genderOther)),
                ],
                onChanged: (value) => setState(() => _newGender = value ?? _newGender),
              ),
            ],
            if (widget.kind != RelationshipModalKind.spouse) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<ChildType>(
                initialValue: _childType,
                decoration: InputDecoration(labelText: l10n.relationshipTypeParentChild),
                items: [
                  DropdownMenuItem(
                    value: ChildType.biological,
                    child: Text(l10n.childTypeBiological),
                  ),
                  DropdownMenuItem(
                    value: ChildType.adopted,
                    child: Text(l10n.childTypeAdopted),
                  ),
                  DropdownMenuItem(value: ChildType.step, child: Text(l10n.childTypeStep)),
                ],
                onChanged: (value) => setState(() => _childType = value ?? _childType),
              ),
            ],
            if (widget.kind == RelationshipModalKind.spouse) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.marriageStartDate),
                subtitle: Text(_marriageStart != null ? dateFormat(_marriageStart!) : '—'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await _pickDate(_marriageStart);
                  if (picked != null) setState(() => _marriageStart = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.marriageEndDate),
                subtitle: Text(_marriageEnd != null ? dateFormat(_marriageEnd!) : '—'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await _pickDate(_marriageEnd);
                  if (picked != null) setState(() => _marriageEnd = picked);
                },
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: () => _submit(provider), child: Text(l10n.save)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

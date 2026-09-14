import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/family_tree_provider.dart';
import '../../core/widgets/autocomplete_field.dart';
import '../../core/widgets/child_type_dropdown.dart';
import '../../core/widgets/gender_dropdown.dart';
import '../../core/widgets/lunar_date_field.dart';
import '../../core/widgets/modal_shell.dart';
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
  late Gender _newGender = widget.kind == RelationshipModalKind.spouse
      ? widget.anchor.gender.opposite
      : Gender.male;
  ChildType _childType = ChildType.biological;
  LunarDate? _marriageStart;
  LunarDate? _marriageEnd;
  String? _constraintError;

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

  /// Ràng buộc tối đa 2 cha/mẹ RUỘT khác giới tính cho 1 người. Chỉ áp
  /// dụng khi type=parentChild và childType=biological — con nuôi/con
  /// riêng không giới hạn số lượng.
  String? _validateBiologicalParentConstraint(FamilyTreeProvider provider, AppLocalizations l10n) {
    if (widget.kind == RelationshipModalKind.spouse) return null;
    if (_childType != ChildType.biological) return null;

    final String? childId;
    final Gender newParentGender;
    if (widget.kind == RelationshipModalKind.parent) {
      childId = widget.anchor.id;
      newParentGender = _useExisting
          ? provider.persons.firstWhere((p) => p.id == _selectedPersonId).gender
          : _newGender;
    } else {
      // kind == child: anchor trở thành cha/mẹ của otherPerson.
      if (_useExisting) {
        childId = _selectedPersonId;
      } else {
        childId = null; // người con mới tạo, chắc chắn chưa có cha/mẹ nào.
      }
      newParentGender = widget.anchor.gender;
    }
    if (childId == null) return null;

    final existingBioParents = provider.biologicalParentsOf(childId);
    if (existingBioParents.length >= 2) {
      return l10n.maxBiologicalParentsReached;
    }
    if (existingBioParents.any((p) => p.gender == newParentGender)) {
      return l10n.biologicalParentsMustDifferGender;
    }
    return null;
  }

  Future<void> _submit(FamilyTreeProvider provider, AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final constraintError = _validateBiologicalParentConstraint(provider, l10n);
    if (constraintError != null) {
      setState(() => _constraintError = constraintError);
      return;
    }

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

    return Form(
      key: _formKey,
      child: ModalShell(
        title: _titleFor(l10n),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => _submit(provider, l10n), child: Text(l10n.save)),
        ],
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l10n.addPerson)),
              ButtonSegment(value: true, label: Text(l10n.selectPerson)),
            ],
            selected: {_useExisting},
            onSelectionChanged: (selection) => setState(() {
              _useExisting = selection.first;
              _constraintError = null;
            }),
          ),
          const SizedBox(height: 12),
          if (_useExisting)
            AutocompleteField<Person>(
              label: l10n.selectPerson,
              options: selectable,
              displayString: (p) => p.fullName,
              onSelected: (p) => setState(() {
                _selectedPersonId = p.id;
                _constraintError = null;
              }),
              validator: (_) => _selectedPersonId == null ? l10n.fieldRequired : null,
            )
          else
            ResponsiveFieldRow(
              children: [
                TextFormField(
                  controller: _newNameController,
                  decoration: InputDecoration(labelText: l10n.fullName, isDense: true),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
                  autofocus: true,
                ),
                GenderDropdown(
                  value: _newGender,
                  onChanged: (value) =>
                      setState(() => _newGender = value ?? _newGender),
                ),
              ],
            ),
          if (widget.kind != RelationshipModalKind.spouse) ...[
            const SizedBox(height: 12),
            ChildTypeDropdown(
              value: _childType,
              onChanged: (value) => setState(() {
                _childType = value ?? _childType;
                _constraintError = null;
              }),
            ),
          ],
          if (widget.kind == RelationshipModalKind.spouse) ...[
            const SizedBox(height: 12),
            LunarDateField(
              label: l10n.marriageStartDate,
              value: _marriageStart,
              onChanged: (v) => setState(() => _marriageStart = v),
            ),
            const SizedBox(height: 12),
            LunarDateField(
              label: l10n.marriageEndDate,
              value: _marriageEnd,
              onChanged: (v) => setState(() => _marriageEnd = v),
            ),
          ],
          if (_constraintError != null) ...[
            const SizedBox(height: 12),
            Text(
              _constraintError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

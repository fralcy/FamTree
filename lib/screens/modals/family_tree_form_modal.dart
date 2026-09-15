import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/family_tree_list_provider.dart';
import '../../core/widgets/modal_shell.dart';
import '../../models/index.dart';
import '../responsive_screen.dart';

/// Tạo mới (existing == null) hoặc sửa thông tin 1 FamilyTree.
Future<void> showFamilyTreeFormModal(BuildContext context, {FamilyTree? existing}) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));
  final content = _FamilyTreeFormContent(existing: existing);

  if (isDesktop) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(child: content),
    );
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

class _FamilyTreeFormContent extends StatefulWidget {
  const _FamilyTreeFormContent({this.existing});

  final FamilyTree? existing;

  @override
  State<_FamilyTreeFormContent> createState() => _FamilyTreeFormContentState();
}

class _FamilyTreeFormContentState extends State<_FamilyTreeFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.existing?.name);
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.existing?.description);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<FamilyTreeListProvider>();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (widget.existing == null) {
      await provider.createTree(name: name, description: description.isEmpty ? null : description);
    } else {
      await provider.renameTree(
        widget.existing!.id,
        name: name,
        description: description.isEmpty ? null : description,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: ModalShell(
        title: widget.existing == null ? l10n.createTree : l10n.editTree,
        maxWidth: 440,
        onSubmit: _submit,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          FilledButton(onPressed: _submit, child: Text(l10n.save)),
        ],
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.treeName, isDense: true),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: l10n.treeDescription, isDense: true),
          ),
        ],
      ),
    );
  }
}

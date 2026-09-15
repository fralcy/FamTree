import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n/app_localizations.dart';
import '../core/providers/family_tree_list_provider.dart';
import '../core/widgets/confirm_dialog.dart';
import '../core/widgets/sort_menu_button.dart';
import '../models/index.dart';
import 'modals/family_tree_form_modal.dart';
import 'modals/settings_modal.dart';

class MobilePortraitTreeListScreen extends StatelessWidget {
  const MobilePortraitTreeListScreen({super.key, required this.onOpenTree});

  final void Function(String treeId) onOpenTree;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trees = context.watch<FamilyTreeListProvider>().trees;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.treeListTitle),
        actions: [
          const SortMenuButton(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showSettingsModal(context),
          ),
        ],
      ),
      body: trees.isEmpty
          ? Center(child: Text(l10n.treeListEmpty, textAlign: TextAlign.center))
          : ListView.builder(
              itemCount: trees.length,
              itemBuilder: (context, index) {
                final tree = trees[index];
                return _TreeListTile(tree: tree, onOpenTree: onOpenTree);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showFamilyTreeFormModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TreeListTile extends StatelessWidget {
  const _TreeListTile({required this.tree, required this.onOpenTree});

  final FamilyTree tree;
  final void Function(String treeId) onOpenTree;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(tree.name),
      subtitle: tree.description != null ? Text(tree.description!) : null,
      onTap: () => onOpenTree(tree.id),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'edit') {
            await showFamilyTreeFormModal(context, existing: tree);
          } else if (value == 'delete') {
            final confirmed = await showConfirmDialog(
              context,
              title: l10n.deleteTree,
              message: l10n.deleteTreeConfirm(tree.name),
            );
            if (confirmed && context.mounted) {
              await context.read<FamilyTreeListProvider>().deleteTree(tree.id);
            }
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'edit', child: Text(l10n.editTree)),
          PopupMenuItem(value: 'delete', child: Text(l10n.deleteTree)),
        ],
      ),
    );
  }
}

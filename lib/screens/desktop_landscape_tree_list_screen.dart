import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n/app_localizations.dart';
import '../core/providers/family_tree_list_provider.dart';
import '../core/widgets/confirm_dialog.dart';
import '../core/widgets/sort_menu_button.dart';
import '../models/index.dart';
import 'modals/family_tree_form_modal.dart';
import 'modals/settings_modal.dart';

class DesktopLandscapeTreeListScreen extends StatelessWidget {
  const DesktopLandscapeTreeListScreen({super.key, required this.onOpenTree});

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
            icon: const Icon(Icons.add),
            tooltip: l10n.createTree,
            onPressed: () => showFamilyTreeFormModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showSettingsModal(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: trees.isEmpty
              ? Center(child: Text(l10n.treeListEmpty, textAlign: TextAlign.center))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 96,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: trees.length,
                  itemBuilder: (context, index) =>
                      _TreeCard(tree: trees[index], onOpenTree: onOpenTree),
                ),
        ),
      ),
    );
  }
}

class _TreeCard extends StatelessWidget {
  const _TreeCard({required this.tree, required this.onOpenTree});

  final FamilyTree tree;
  final void Function(String treeId) onOpenTree;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        onTap: () => onOpenTree(tree.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tree.name, style: Theme.of(context).textTheme.titleMedium),
                    if (tree.description != null)
                      Text(
                        tree.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
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
            ],
          ),
        ),
      ),
    );
  }
}

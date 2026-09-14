import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n/app_localizations.dart';
import '../core/providers/family_tree_provider.dart';
import '../core/widgets/family_diagram_view.dart';
import '../models/index.dart';
import 'modals/person_detail_modal.dart';
import 'modals/person_form_modal.dart';
import 'modals/settings_modal.dart';

class DesktopLandscapeFamilyTreeScreen extends StatelessWidget {
  const DesktopLandscapeFamilyTreeScreen({
    super.key,
    required this.tree,
    required this.onBack,
  });

  final FamilyTree tree;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<FamilyTreeProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
        title: Text(l10n.familyTreeViewTitle(tree.name)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showSettingsModal(context, tree: tree),
          ),
        ],
      ),
      body: provider.persons.isEmpty
          ? Center(child: Text(l10n.personListEmpty, textAlign: TextAlign.center))
          : FamilyDiagramView(
              persons: provider.persons,
              relationships: provider.relationships,
              generationMap: provider.generationMap,
              onTapPerson: (personId) => showPersonDetailModal(
                context,
                familyTreeId: tree.id,
                personId: personId,
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showPersonFormModal(context, familyTreeId: tree.id),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

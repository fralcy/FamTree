import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n/app_localizations.dart';
import '../core/providers/family_tree_provider.dart';
import '../core/widgets/family_diagram_view.dart';
import '../models/index.dart';
import 'modals/person_detail_modal.dart';
import 'modals/person_form_modal.dart';
import 'modals/settings_modal.dart';

class MobilePortraitFamilyTreeScreen extends StatefulWidget {
  const MobilePortraitFamilyTreeScreen({
    super.key,
    required this.tree,
    required this.onBack,
  });

  final FamilyTree tree;
  final VoidCallback onBack;

  @override
  State<MobilePortraitFamilyTreeScreen> createState() =>
      _MobilePortraitFamilyTreeScreenState();
}

class _MobilePortraitFamilyTreeScreenState extends State<MobilePortraitFamilyTreeScreen> {
  bool _showDiagram = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<FamilyTreeProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: Text(l10n.familyTreeViewTitle(widget.tree.name)),
        actions: [
          IconButton(
            icon: Icon(_showDiagram ? Icons.list : Icons.account_tree),
            tooltip: _showDiagram ? l10n.viewList : l10n.viewDiagram,
            onPressed: () => setState(() => _showDiagram = !_showDiagram),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showSettingsModal(context),
          ),
        ],
      ),
      body: provider.persons.isEmpty
          ? Center(child: Text(l10n.personListEmpty, textAlign: TextAlign.center))
          : _showDiagram
              ? FamilyDiagramView(
                  persons: provider.persons,
                  relationships: provider.relationships,
                  generationMap: provider.generationMap,
                  onTapPerson: (personId) => showPersonDetailModal(
                    context,
                    familyTreeId: widget.tree.id,
                    personId: personId,
                  ),
                )
              : _PersonListByGeneration(tree: widget.tree, provider: provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showPersonFormModal(context, familyTreeId: widget.tree.id),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _PersonListByGeneration extends StatelessWidget {
  const _PersonListByGeneration({required this.tree, required this.provider});

  final FamilyTree tree;
  final FamilyTreeProvider provider;

  @override
  Widget build(BuildContext context) {
    final generationMap = provider.generationMap;
    final byGeneration = <int, List<Person>>{};
    for (final p in provider.persons) {
      byGeneration.putIfAbsent(generationMap[p.id] ?? 0, () => []).add(p);
    }
    final sortedGenerations = byGeneration.keys.toList()..sort();

    return ListView(
      children: [
        for (final gen in sortedGenerations) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              AppLocalizations.of(context)!.generationLabel(gen),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final person in byGeneration[gen]!)
            ListTile(
              title: Text(person.fullName),
              onTap: () => showPersonDetailModal(
                context,
                familyTreeId: tree.id,
                personId: person.id,
              ),
            ),
        ],
      ],
    );
  }
}

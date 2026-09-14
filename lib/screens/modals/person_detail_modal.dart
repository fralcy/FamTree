import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/family_tree_provider.dart';
import '../../core/utils/lunar_date_formatter.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../models/index.dart';
import '../responsive_screen.dart';
import 'person_form_modal.dart';
import 'relationship_form_modal.dart';

Future<void> showPersonDetailModal(
  BuildContext context, {
  required String familyTreeId,
  required String personId,
}) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));
  final provider = context.read<FamilyTreeProvider>();
  final content = ChangeNotifierProvider.value(
    value: provider,
    child: _PersonDetailContent(familyTreeId: familyTreeId, personId: personId),
  );

  if (isDesktop) {
    return showDialog<void>(context: context, builder: (context) => Dialog(child: content));
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => content,
  );
}

class _PersonDetailContent extends StatelessWidget {
  const _PersonDetailContent({required this.familyTreeId, required this.personId});

  final String familyTreeId;
  final String personId;

  String _genderLabel(AppLocalizations l10n, Gender gender) {
    switch (gender) {
      case Gender.male:
        return l10n.genderMale;
      case Gender.female:
        return l10n.genderFemale;
      case Gender.other:
        return l10n.genderOther;
    }
  }

  Future<void> _handleDelete(BuildContext context, Person person) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<FamilyTreeProvider>();
    final atRiskChildren = provider.childrenThatWouldLoseSoleParent(person.id);

    final message = StringBuffer(l10n.deletePersonConfirm(person.fullName));
    for (final child in atRiskChildren) {
      message.write('\n${l10n.deletePersonOrphanWarning(child.fullName)}');
    }

    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deletePerson,
      message: message.toString(),
    );
    if (!confirmed) return;
    await provider.deletePerson(person.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<FamilyTreeProvider>();

    Person? person;
    for (final p in provider.persons) {
      if (p.id == personId) {
        person = p;
        break;
      }
    }
    if (person == null) return const SizedBox.shrink();
    final resolvedPerson = person;

    final spouses = provider.spousesOf(personId);
    final children = provider.childrenOf(personId);
    final parents = provider.parentsOf(personId);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  resolvedPerson.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => showPersonFormModal(
                  context,
                  familyTreeId: familyTreeId,
                  existing: resolvedPerson,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _handleDelete(context, resolvedPerson),
              ),
            ],
          ),
          Text('${l10n.gender}: ${_genderLabel(l10n, resolvedPerson.gender)}'),
          if (resolvedPerson.birthDate != null)
            Text('${l10n.birthDate}: ${LunarDateFormatter.format(l10n, resolvedPerson.birthDate!)}'),
          if (resolvedPerson.placeOfBirth != null)
            Text('${l10n.placeOfBirth}: ${resolvedPerson.placeOfBirth}'),
          if (resolvedPerson.isDeceased) ...[
            if (resolvedPerson.deathDate != null)
              Text('${l10n.deathDate}: ${LunarDateFormatter.format(l10n, resolvedPerson.deathDate!)}'),
            if (resolvedPerson.memorialDate != null)
              Text(
                '${l10n.memorialDate}: ${LunarDateFormatter.format(l10n, resolvedPerson.memorialDate!)}',
              ),
          ],
          if (resolvedPerson.note != null) ...[
            const SizedBox(height: 8),
            Text(resolvedPerson.note!),
          ],
          const Divider(height: 32),
          _RelationSection(
            title: l10n.spouses,
            people: spouses,
            emptyLabel: l10n.noSpouses,
            addLabel: l10n.addSpouse,
            onAdd: () => showRelationshipFormModal(
              context,
              familyTreeId: familyTreeId,
              anchor: resolvedPerson,
              kind: RelationshipModalKind.spouse,
            ),
            onTapPerson: (id) =>
                showPersonDetailModal(context, familyTreeId: familyTreeId, personId: id),
          ),
          const SizedBox(height: 16),
          _RelationSection(
            title: l10n.children,
            people: children,
            emptyLabel: l10n.noChildren,
            addLabel: l10n.addChild,
            onAdd: () => showRelationshipFormModal(
              context,
              familyTreeId: familyTreeId,
              anchor: resolvedPerson,
              kind: RelationshipModalKind.child,
            ),
            onTapPerson: (id) =>
                showPersonDetailModal(context, familyTreeId: familyTreeId, personId: id),
          ),
          const SizedBox(height: 16),
          _RelationSection(
            title: l10n.parents,
            people: parents,
            emptyLabel: l10n.noParents,
            addLabel: l10n.addParent,
            onAdd: () => showRelationshipFormModal(
              context,
              familyTreeId: familyTreeId,
              anchor: resolvedPerson,
              kind: RelationshipModalKind.parent,
            ),
            onTapPerson: (id) =>
                showPersonDetailModal(context, familyTreeId: familyTreeId, personId: id),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _RelationSection extends StatelessWidget {
  const _RelationSection({
    required this.title,
    required this.people,
    required this.emptyLabel,
    required this.addLabel,
    required this.onAdd,
    required this.onTapPerson,
  });

  final String title;
  final List<Person> people;
  final String emptyLabel;
  final String addLabel;
  final VoidCallback onAdd;
  final void Function(String personId) onTapPerson;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.labelLarge)),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(addLabel),
            ),
          ],
        ),
        if (people.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(emptyLabel, style: Theme.of(context).textTheme.bodySmall),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in people)
                ActionChip(label: Text(p.fullName), onPressed: () => onTapPerson(p.id)),
            ],
          ),
      ],
    );
  }
}

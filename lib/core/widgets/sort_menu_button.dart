import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/family_tree_list_provider.dart';

/// Icon sắp xếp dùng chung cho màn hình danh sách gia phả (mobile/desktop)
/// — tách riêng để không lặp lại danh sách lựa chọn ở 2 nơi.
class SortMenuButton extends StatelessWidget {
  const SortMenuButton({super.key});

  String _labelFor(AppLocalizations l10n, TreeSortOption option) {
    switch (option) {
      case TreeSortOption.nameAsc:
        return l10n.sortNameAsc;
      case TreeSortOption.nameDesc:
        return l10n.sortNameDesc;
      case TreeSortOption.newestFirst:
        return l10n.sortNewestFirst;
      case TreeSortOption.oldestFirst:
        return l10n.sortOldestFirst;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<FamilyTreeListProvider>();

    return PopupMenuButton<TreeSortOption>(
      icon: const Icon(Icons.sort),
      tooltip: l10n.sortBy,
      initialValue: provider.sortOption,
      onSelected: (option) => context.read<FamilyTreeListProvider>().setSortOption(option),
      itemBuilder: (context) => [
        for (final option in TreeSortOption.values)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                if (option == provider.sortOption)
                  const Icon(Icons.check, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(_labelFor(l10n, option)),
              ],
            ),
          ),
      ],
    );
  }
}

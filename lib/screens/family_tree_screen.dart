import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n/app_localizations.dart';
import '../core/providers/family_tree_provider.dart';
import '../core/widgets/family_diagram_view.dart';
import '../models/index.dart';
import 'modals/person_detail_modal.dart';
import 'modals/person_form_modal.dart';
import 'modals/settings_modal.dart';
import 'responsive_screen.dart';

/// Xem 1 gia phả cụ thể — HỢP NHẤT bản rộng/hẹp vào 1 StatefulWidget duy
/// nhất (LayoutBuilder đổi bố cục NỘI BỘ) thay vì 2 widget class riêng
/// biệt như trước (MobilePortraitFamilyTreeScreen/DesktopLandscape...).
///
/// Lý do gộp: `ResponsiveScreen` cũ chọn giữa 2 CLASS WIDGET KHÁC NHAU khi
/// resize ngang qua ngưỡng breakpoint (720px) — Flutter không thể đối
/// chiếu (reconcile) 2 loại widget khác nhau ở cùng 1 vị trí trong cây, nên
/// buộc phải unmount/remount TOÀN BỘ, kể cả FamilyDiagramView lồng bên
/// trong → mất luôn vị trí pan/zoom đang xem dở (tự canh giữa lại đột
/// ngột, cảm giác "giật/nhảy hình" khi kéo giãn cửa sổ qua lại ngưỡng đó).
/// Gộp về 1 State + LayoutBuilder giữ FamilyDiagramView là CÙNG 1 instance
/// xuyên suốt khi resize, Flutter chỉ update tại chỗ (didUpdateWidget) nên
/// state bên trong (TransformationController, _centered) được giữ nguyên.
class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key, required this.tree, required this.onBack});

  final FamilyTree tree;
  final VoidCallback onBack;

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  /// Mặc định hiện sơ đồ (trực quan hơn danh sách phẳng) — chỉ có ý nghĩa
  /// ở màn hẹp: màn đủ rộng luôn hiện sơ đồ, không có nút chuyển.
  bool _showDiagram = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<FamilyTreeProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = ResponsiveScreen.isDesktop(constraints);
        final showDiagram = isDesktop || _showDiagram;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
            title: Text(l10n.familyTreeViewTitle(widget.tree.name)),
            actions: [
              if (!isDesktop)
                IconButton(
                  icon: Icon(_showDiagram ? Icons.list : Icons.account_tree),
                  tooltip: _showDiagram ? l10n.viewList : l10n.viewDiagram,
                  onPressed: () => setState(() => _showDiagram = !_showDiagram),
                ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => showSettingsModal(context, tree: widget.tree),
              ),
            ],
          ),
          body: provider.persons.isEmpty
              ? Center(child: Text(l10n.personListEmpty, textAlign: TextAlign.center))
              : showDiagram
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
      },
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/family_tree_list_provider.dart';
import '../core/providers/family_tree_provider.dart';
import '../models/index.dart';
import 'desktop_landscape_tree_list_screen.dart';
import 'family_tree_screen.dart';
import 'mobile_portrait_tree_list_screen.dart';
import 'responsive_screen.dart';

/// Wrapper gốc: quản lý state "cây nào đang mở" — toàn app chỉ có route
/// thật duy nhất, chuyển giữa danh sách cây và xem 1 cây qua state cục bộ
/// thay vì Navigator.push.
class ResponsiveAppScreen extends StatefulWidget {
  const ResponsiveAppScreen({super.key});

  @override
  State<ResponsiveAppScreen> createState() => _ResponsiveAppScreenState();
}

class _ResponsiveAppScreenState extends State<ResponsiveAppScreen> {
  String? _selectedTreeId;

  void _openTree(String treeId) => setState(() => _selectedTreeId = treeId);
  void _closeTree() => setState(() => _selectedTreeId = null);

  @override
  Widget build(BuildContext context) {
    final selectedTreeId = _selectedTreeId;

    if (selectedTreeId == null) {
      return ResponsiveScreen(
        mobileBuilder: (context) => MobilePortraitTreeListScreen(onOpenTree: _openTree),
        desktopBuilder: (context) => DesktopLandscapeTreeListScreen(onOpenTree: _openTree),
      );
    }

    final trees = context.watch<FamilyTreeListProvider>().trees;
    FamilyTree? tree;
    for (final t in trees) {
      if (t.id == selectedTreeId) {
        tree = t;
        break;
      }
    }
    if (tree == null) {
      // Cây vừa bị xoá (ví dụ từ thiết bị khác/luồng khác) — quay về danh sách.
      WidgetsBinding.instance.addPostFrameCallback((_) => _closeTree());
      return const SizedBox.shrink();
    }

    return ChangeNotifierProvider<FamilyTreeProvider>(
      key: ValueKey(selectedTreeId),
      create: (_) => FamilyTreeProvider(familyTreeId: selectedTreeId),
      child: FamilyTreeScreen(tree: tree, onBack: _closeTree),
    );
  }
}

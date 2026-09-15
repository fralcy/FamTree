import 'package:flutter/foundation.dart';

import '../../models/index.dart';
import '../utils/data_manager.dart';

enum TreeSortOption { nameAsc, nameDesc, newestFirst, oldestFirst }

/// Quản lý danh sách FamilyTree (dùng ở màn hình chọn cây). Tạo/sửa/xoá 1
/// cây gọi DataManager rồi notifyListeners() — không đụng Person/Relationship
/// (đó là việc của FamilyTreeProvider khi 1 cây cụ thể được mở).
class FamilyTreeListProvider extends ChangeNotifier {
  FamilyTreeListProvider() : _trees = DataManager().getAllFamilyTrees() {
    _applySort();
  }

  List<FamilyTree> _trees;
  TreeSortOption _sortOption = TreeSortOption.newestFirst;

  List<FamilyTree> get trees => List.unmodifiable(_trees);
  TreeSortOption get sortOption => _sortOption;

  void setSortOption(TreeSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    _applySort();
    notifyListeners();
  }

  void _applySort() {
    switch (_sortOption) {
      case TreeSortOption.nameAsc:
        _trees.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case TreeSortOption.nameDesc:
        _trees.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case TreeSortOption.newestFirst:
        _trees.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TreeSortOption.oldestFirst:
        _trees.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }

  Future<FamilyTree> createTree({required String name, String? description}) async {
    final tree = FamilyTree.create(name: name, description: description);
    await DataManager().saveFamilyTree(tree);
    refresh();
    return tree;
  }

  Future<void> renameTree(String id, {required String name, String? description}) async {
    final existing = DataManager().getFamilyTree(id);
    if (existing == null) return;
    final updated = existing.copyWith(name: name, description: description);
    await DataManager().saveFamilyTree(updated);
    refresh();
  }

  Future<void> deleteTree(String id) async {
    await DataManager().deleteFamilyTree(id);
    refresh();
  }

  void refresh() {
    _trees = DataManager().getAllFamilyTrees();
    _applySort();
    notifyListeners();
  }
}

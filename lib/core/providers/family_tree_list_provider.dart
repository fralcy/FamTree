import 'package:flutter/foundation.dart';

import '../../models/index.dart';
import '../utils/data_manager.dart';

/// Quản lý danh sách FamilyTree (dùng ở màn hình chọn cây). Tạo/sửa/xoá 1
/// cây gọi DataManager rồi notifyListeners() — không đụng Person/Relationship
/// (đó là việc của FamilyTreeProvider khi 1 cây cụ thể được mở).
class FamilyTreeListProvider extends ChangeNotifier {
  FamilyTreeListProvider() : _trees = DataManager().getAllFamilyTrees();

  List<FamilyTree> _trees;

  List<FamilyTree> get trees => List.unmodifiable(_trees);

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
    notifyListeners();
  }
}

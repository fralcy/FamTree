import 'package:flutter/foundation.dart';

import '../../models/index.dart';
import '../models/generation_result.dart';
import '../utils/data_manager.dart';
import '../utils/family_relationship_service.dart';
import '../utils/generation_service.dart';

/// Gộp Person + Relationship của 1 cây đang mở — không tách PersonProvider
/// riêng vì 2 loại dữ liệu này luôn được đọc/sửa cùng nhau. Tạo ĐỘNG khi
/// user mở 1 cây cụ thể, KHÔNG đăng ký cố định ở MultiProvider gốc.
class FamilyTreeProvider extends ChangeNotifier {
  FamilyTreeProvider({required this.familyTreeId})
      : _persons = DataManager().getPersonsByTree(familyTreeId),
        _relationships = DataManager().getRelationshipsByTree(familyTreeId);

  final String familyTreeId;

  List<Person> _persons;
  List<Relationship> _relationships;

  List<Person> get persons => List.unmodifiable(_persons);
  List<Relationship> get relationships => List.unmodifiable(_relationships);

  GenerationResult get generationResult =>
      GenerationService.computeGenerations(_persons, _relationships);

  Map<String, int> get generationMap => generationResult.generationOf;

  List<Person> spousesOf(String personId) =>
      FamilyRelationshipService.spousesOf(personId, _persons, _relationships);

  List<Person> childrenOf(String personId) =>
      FamilyRelationshipService.childrenOf(personId, _persons, _relationships);

  List<Person> parentsOf(String personId) =>
      FamilyRelationshipService.parentsOf(personId, _persons, _relationships);

  List<Relationship> marriagesOf(String personId) =>
      FamilyRelationshipService.marriagesOf(personId, _relationships);

  Future<void> addPerson(Person person) async {
    await DataManager().savePerson(person);
    refresh();
  }

  Future<void> updatePerson(Person person) async {
    await DataManager().savePerson(person);
    refresh();
  }

  /// Con sẽ mất liên kết cha/mẹ nếu xoá [personId] (người đó là cha/mẹ DUY
  /// NHẤT được ghi nhận của con). UI nên hiển thị cảnh báo xác nhận với
  /// danh sách này trước khi gọi [deletePerson] — cây tự phục hồi đúng
  /// logic (generation_service coi con thành root mới ở lần tính lại kế
  /// tiếp), không cần xử lý đặc biệt gì thêm ở tầng dữ liệu.
  List<Person> childrenThatWouldLoseSoleParent(String personId) {
    final children = childrenOf(personId);
    return children.where((child) => parentsOf(child.id).length <= 1).toList();
  }

  Future<void> deletePerson(String personId) async {
    await DataManager().deletePerson(personId);
    refresh();
  }

  Future<void> addRelationship(Relationship relationship) async {
    await DataManager().saveRelationship(relationship);
    refresh();
  }

  Future<void> updateRelationship(Relationship relationship) async {
    await DataManager().saveRelationship(relationship);
    refresh();
  }

  Future<void> deleteRelationship(String relationshipId) async {
    await DataManager().deleteRelationship(relationshipId);
    refresh();
  }

  void refresh() {
    _persons = DataManager().getPersonsByTree(familyTreeId);
    _relationships = DataManager().getRelationshipsByTree(familyTreeId);
    notifyListeners();
  }
}

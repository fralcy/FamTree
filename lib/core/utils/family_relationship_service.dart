import '../../models/index.dart';

/// Hàm thuần, không phụ thuộc DataManager/BuildContext — nhận thẳng danh
/// sách persons/relationships để dễ unit test độc lập.
class FamilyRelationshipService {
  const FamilyRelationshipService._();

  static List<Person> spousesOf(
    String personId,
    List<Person> persons,
    List<Relationship> relationships,
  ) {
    final spouseIds = relationships
        .where((r) => r.type == RelationshipType.marriage)
        .where((r) => r.personAId == personId || r.personBId == personId)
        .map((r) => r.personAId == personId ? r.personBId : r.personAId);
    return _resolve(spouseIds, persons);
  }

  static List<Person> childrenOf(
    String personId,
    List<Person> persons,
    List<Relationship> relationships,
  ) {
    final childIds = relationships
        .where((r) => r.type == RelationshipType.parentChild)
        .where((r) => r.personAId == personId)
        .map((r) => r.personBId);
    return _resolve(childIds, persons);
  }

  static List<Person> parentsOf(
    String personId,
    List<Person> persons,
    List<Relationship> relationships,
  ) {
    final parentIds = relationships
        .where((r) => r.type == RelationshipType.parentChild)
        .where((r) => r.personBId == personId)
        .map((r) => r.personAId);
    return _resolve(parentIds, persons);
  }

  /// Mọi record marriage liên quan tới [personId], sắp theo [Relationship.startDate]
  /// (null xếp cuối) — dùng để hiển thị thứ tự "vợ/chồng thứ mấy".
  static List<Relationship> marriagesOf(
    String personId,
    List<Relationship> relationships,
  ) {
    final marriages = relationships
        .where((r) => r.type == RelationshipType.marriage)
        .where((r) => r.personAId == personId || r.personBId == personId)
        .toList();
    marriages.sort((a, b) {
      if (a.startDate == null && b.startDate == null) return 0;
      if (a.startDate == null) return 1;
      if (b.startDate == null) return -1;
      return a.startDate!.compareTo(b.startDate!);
    });
    return marriages;
  }

  /// Chỉ cha/mẹ RUỘT (childType=biological) — dùng để ràng buộc tối đa 2
  /// cha/mẹ ruột khác giới tính, và để sơ đồ quyết định vẽ đường nối con
  /// vào đường hôn nhân của cha mẹ (nếu có) hay nối riêng từng người.
  static List<Person> biologicalParentsOf(
    String personId,
    List<Person> persons,
    List<Relationship> relationships,
  ) {
    final parentIds = relationships
        .where((r) => r.type == RelationshipType.parentChild)
        .where((r) => r.personBId == personId && r.childType == ChildType.biological)
        .map((r) => r.personAId);
    return _resolve(parentIds, persons);
  }

  /// True nếu có thể thêm [newParentGender] làm cha/mẹ RUỘT của [childId] —
  /// tối đa 2 cha/mẹ ruột, phải khác giới tính nhau. Không áp dụng cho con
  /// nuôi/con riêng (không giới hạn).
  static bool canAddBiologicalParent(
    String childId,
    Gender newParentGender,
    List<Person> persons,
    List<Relationship> relationships,
  ) {
    final existing = biologicalParentsOf(childId, persons, relationships);
    if (existing.length >= 2) return false;
    if (existing.any((p) => p.gender == newParentGender)) return false;
    return true;
  }

  /// Record marriage giữa đúng 2 người [personAId]/[personBId] (không phân
  /// biệt thứ tự), hoặc `null` nếu họ chưa từng kết hôn với nhau.
  static Relationship? marriageBetween(
    String personAId,
    String personBId,
    List<Relationship> relationships,
  ) {
    for (final r in relationships) {
      if (r.type != RelationshipType.marriage) continue;
      final matches = (r.personAId == personAId && r.personBId == personBId) ||
          (r.personAId == personBId && r.personBId == personAId);
      if (matches) return r;
    }
    return null;
  }

  static List<Person> _resolve(Iterable<String> ids, List<Person> persons) {
    final idSet = ids.toSet();
    return persons.where((p) => idSet.contains(p.id)).toList();
  }
}

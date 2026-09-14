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

  static List<Person> _resolve(Iterable<String> ids, List<Person> persons) {
    final idSet = ids.toSet();
    return persons.where((p) => idSet.contains(p.id)).toList();
  }
}

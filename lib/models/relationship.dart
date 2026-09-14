import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'child_type.dart';
import 'relationship_type.dart';

part 'relationship.g.dart';

/// Thiết kế dạng "edge" trong 1 đồ thị quan hệ, KHÔNG phải field cố định
/// (motherId/fatherId/spouseIds) trên [Person]. Nhờ đó 1 Person có thể xuất
/// hiện trong nhiều record marriage (đa thê/đa phu/tái hôn) và mỗi cặp
/// cha/mẹ-con là 1 record độc lập (hỗ trợ con riêng, con nuôi).
///
/// Ý nghĩa [personAId]/[personBId] thay đổi theo [type]:
/// - marriage: A và B là 2 vợ/chồng (không có thứ tự cố định).
/// - parentChild: A là cha/mẹ, B là con.
@HiveType(typeId: 2)
class Relationship {
  Relationship({
    required this.id,
    required this.familyTreeId,
    required this.type,
    required this.personAId,
    required this.personBId,
    this.childType,
    this.startDate,
    this.endDate,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Relationship.createMarriage({
    required String familyTreeId,
    required String personAId,
    required String personBId,
    DateTime? startDate,
    DateTime? endDate,
    String? note,
  }) {
    final now = DateTime.now();
    return Relationship(
      id: const Uuid().v4(),
      familyTreeId: familyTreeId,
      type: RelationshipType.marriage,
      personAId: personAId,
      personBId: personBId,
      startDate: startDate,
      endDate: endDate,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Relationship.createParentChild({
    required String familyTreeId,
    required String parentId,
    required String childId,
    ChildType childType = ChildType.biological,
    String? note,
  }) {
    final now = DateTime.now();
    return Relationship(
      id: const Uuid().v4(),
      familyTreeId: familyTreeId,
      type: RelationshipType.parentChild,
      personAId: parentId,
      personBId: childId,
      childType: childType,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
  }

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String familyTreeId;
  @HiveField(2)
  final RelationshipType type;
  @HiveField(3)
  final String personAId;
  @HiveField(4)
  final String personBId;
  @HiveField(5)
  final ChildType? childType;
  @HiveField(6)
  final DateTime? startDate;
  @HiveField(7)
  final DateTime? endDate;
  @HiveField(8)
  final String? note;
  @HiveField(9)
  final DateTime createdAt;
  @HiveField(10)
  final DateTime updatedAt;

  Relationship copyWith({
    ChildType? childType,
    DateTime? startDate,
    DateTime? endDate,
    String? note,
  }) {
    return Relationship(
      id: id,
      familyTreeId: familyTreeId,
      type: type,
      personAId: personAId,
      personBId: personBId,
      childType: childType ?? this.childType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

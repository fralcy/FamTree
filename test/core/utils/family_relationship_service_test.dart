import 'package:fam_tree/core/utils/family_relationship_service.dart';
import 'package:fam_tree/models/index.dart';
import 'package:flutter_test/flutter_test.dart';

const _treeId = 't1';

Person _person(String id, {Gender gender = Gender.male}) {
  return Person(
    id: id,
    familyTreeId: _treeId,
    fullName: id,
    gender: gender,
    isDeceased: false,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

void main() {
  final a = _person('A');
  final b = _person('B', gender: Gender.female);
  final c = _person('C', gender: Gender.female);
  final d = _person('D');
  final persons = [a, b, c, d];

  final marriage1 = Relationship.createMarriage(
    familyTreeId: _treeId,
    personAId: a.id,
    personBId: b.id,
    startDate: const LunarDate(day: 1, month: 1, year: 1990),
    endDate: const LunarDate(day: 1, month: 1, year: 2000),
  );
  final marriage2 = Relationship.createMarriage(
    familyTreeId: _treeId,
    personAId: a.id,
    personBId: c.id,
    startDate: const LunarDate(day: 1, month: 1, year: 2005),
  );
  final parentChild = Relationship.createParentChild(
    familyTreeId: _treeId,
    parentId: a.id,
    childId: d.id,
  );
  final relationships = [marriage1, marriage2, parentChild];

  test('spousesOf trả về cả 2 vợ (đa thê/tái hôn)', () {
    final spouses = FamilyRelationshipService.spousesOf(a.id, persons, relationships);
    expect(spouses.map((p) => p.id), containsAll(['B', 'C']));
  });

  test('childrenOf trả về đúng con', () {
    final children = FamilyRelationshipService.childrenOf(a.id, persons, relationships);
    expect(children.map((p) => p.id), ['D']);
  });

  test('parentsOf trả về đúng cha/mẹ', () {
    final parents = FamilyRelationshipService.parentsOf(d.id, persons, relationships);
    expect(parents.map((p) => p.id), ['A']);
  });

  test('marriagesOf sắp theo startDate, vợ cũ trước vợ mới', () {
    final marriages = FamilyRelationshipService.marriagesOf(a.id, relationships);
    expect(marriages.map((r) => r.id), [marriage1.id, marriage2.id]);
  });
}

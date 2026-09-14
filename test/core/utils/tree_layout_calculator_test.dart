import 'package:fam_tree/core/utils/generation_service.dart';
import 'package:fam_tree/core/utils/tree_layout_calculator.dart';
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
  test('cặp vợ chồng nằm sát nhau trên cùng hàng (cùng Y, X liền kề)', () {
    final a = _person('A');
    final b = _person('B', gender: Gender.female);
    final persons = [a, b];
    final relationships = [
      Relationship.createMarriage(familyTreeId: _treeId, personAId: 'A', personBId: 'B'),
    ];
    final generationMap =
        GenerationService.computeGenerations(persons, relationships).generationOf;

    final positions =
        TreeLayoutCalculator.computeNodePositions(persons, relationships, generationMap);

    expect(positions['A']!.dy, positions['B']!.dy);
    expect((positions['A']!.dx - positions['B']!.dx).abs(), TreeLayoutCalculator.nodeSpacingX);
  });

  test('con cái căn giữa dưới đoạn nối cha mẹ', () {
    final father = _person('F');
    final mother = _person('M', gender: Gender.female);
    final child = _person('C');
    final persons = [father, mother, child];
    final relationships = [
      Relationship.createMarriage(familyTreeId: _treeId, personAId: 'F', personBId: 'M'),
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'F', childId: 'C'),
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'M', childId: 'C'),
    ];
    final generationMap =
        GenerationService.computeGenerations(persons, relationships).generationOf;

    final positions =
        TreeLayoutCalculator.computeNodePositions(persons, relationships, generationMap);

    final expectedMidpoint = (positions['F']!.dx + positions['M']!.dx) / 2;
    expect(positions['C']!.dx, expectedMidpoint);
    expect(positions['C']!.dy, greaterThan(positions['F']!.dy));
  });

  test('không có node nào trùng toạ độ trong cùng 1 hàng', () {
    final persons = [_person('A'), _person('B'), _person('C')];
    final relationships = [
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'A', childId: 'B'),
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'A', childId: 'C'),
    ];
    final generationMap =
        GenerationService.computeGenerations(persons, relationships).generationOf;

    final positions =
        TreeLayoutCalculator.computeNodePositions(persons, relationships, generationMap);

    expect(positions['B']!.dx, isNot(positions['C']!.dx));
  });
}

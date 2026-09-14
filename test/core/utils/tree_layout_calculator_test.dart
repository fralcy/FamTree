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

  test('cha/mẹ căn giữa theo trung bình vị trí các con (bottom-up)', () {
    // 2 con → cha/mẹ phải nằm đúng ở trung bình X của 2 con, phản ánh toàn
    // bộ nhánh con cháu thay vì chỉ suy từ trên xuống.
    final father = _person('F');
    final mother = _person('M', gender: Gender.female);
    final child1 = _person('C1');
    final child2 = _person('C2');
    final persons = [father, mother, child1, child2];
    final relationships = [
      Relationship.createMarriage(familyTreeId: _treeId, personAId: 'F', personBId: 'M'),
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'F', childId: 'C1'),
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'M', childId: 'C1'),
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'F', childId: 'C2'),
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'M', childId: 'C2'),
    ];
    final generationMap =
        GenerationService.computeGenerations(persons, relationships).generationOf;

    final positions =
        TreeLayoutCalculator.computeNodePositions(persons, relationships, generationMap);

    final childrenAvgX = (positions['C1']!.dx + positions['C2']!.dx) / 2;
    expect(positions['F']!.dx, childrenAvgX);
    expect(positions['C1']!.dy, greaterThan(positions['F']!.dy));
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

  test('2 nhánh cháu gần nhau được đẩy giãn ra thay vì chồng lên nhau', () {
    // A có 2 con B, C (không vợ/chồng, sát nhau). B có 2 con D,E (căn giữa
    // dưới B) — E sẽ lấn sang gần vị trí mong muốn của F (con của C) nếu
    // không có bước quét chống chồng chéo.
    final persons = [
      _person('A'),
      _person('B'),
      _person('C'),
      _person('D'),
      _person('E'),
      _person('F'),
    ];
    final relationships = [
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'A', childId: 'B'),
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'A', childId: 'C'),
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'B', childId: 'D'),
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'B', childId: 'E'),
      Relationship.createParentChild(familyTreeId: _treeId, parentId: 'C', childId: 'F'),
    ];
    final generationMap =
        GenerationService.computeGenerations(persons, relationships).generationOf;

    final positions =
        TreeLayoutCalculator.computeNodePositions(persons, relationships, generationMap);

    // Cùng hàng (đời 2): D, E, F phải cách nhau tối thiểu nodeSpacingX,
    // không ai chồng lên ai.
    final row2 = ['D', 'E', 'F']..sort((a, b) => positions[a]!.dx.compareTo(positions[b]!.dx));
    for (var i = 1; i < row2.length; i++) {
      final gap = positions[row2[i]]!.dx - positions[row2[i - 1]]!.dx;
      expect(gap, greaterThanOrEqualTo(TreeLayoutCalculator.nodeSpacingX));
    }
  });
}

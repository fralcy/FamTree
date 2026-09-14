import 'package:fam_tree/core/utils/generation_service.dart';
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

Relationship _parentChild(
  String parentId,
  String childId, {
  ChildType childType = ChildType.biological,
}) {
  return Relationship.createParentChild(
    familyTreeId: _treeId,
    parentId: parentId,
    childId: childId,
    childType: childType,
  );
}

Relationship _marriage(
  String aId,
  String bId, {
  DateTime? startDate,
  DateTime? endDate,
}) {
  return Relationship.createMarriage(
    familyTreeId: _treeId,
    personAId: aId,
    personBId: bId,
    startDate: startDate,
    endDate: endDate,
  );
}

void main() {
  test('root → con → cháu: generation 0,1,2', () {
    final persons = [_person('A'), _person('B'), _person('C')];
    final relationships = [_parentChild('A', 'B'), _parentChild('B', 'C')];

    final result = GenerationService.computeGenerations(persons, relationships);

    expect(result.generationOf['A'], 0);
    expect(result.generationOf['B'], 1);
    expect(result.generationOf['C'], 2);
    expect(result.rootIds, ['A']);
    expect(result.unlinkedIds, isEmpty);
  });

  test('đa root độc lập: mỗi nhánh có generation 0 riêng', () {
    final persons = [
      _person('A'), _person('B'), // nhánh 1: A -> B
      _person('X'), _person('Y'), // nhánh 2: X -> Y, không liên quan nhánh 1
    ];
    final relationships = [_parentChild('A', 'B'), _parentChild('X', 'Y')];

    final result = GenerationService.computeGenerations(persons, relationships);

    expect(result.generationOf['A'], 0);
    expect(result.generationOf['X'], 0);
    expect(result.generationOf['B'], 1);
    expect(result.generationOf['Y'], 1);
    expect(result.rootIds, containsAll(['A', 'X']));
  });

  test('tái hôn: cả 2 vợ cùng generation với chồng', () {
    final persons = [
      _person('A'), // chồng, root (có con)
      _person('B', gender: Gender.female), // vợ cũ
      _person('C', gender: Gender.female), // vợ hiện tại
      _person('D'), // con của A-B
    ];
    final relationships = [
      _marriage('A', 'B', startDate: DateTime(1990), endDate: DateTime(2000)),
      _marriage('A', 'C', startDate: DateTime(2005)),
      _parentChild('A', 'D'),
    ];

    final result = GenerationService.computeGenerations(persons, relationships);

    expect(result.generationOf['A'], 0);
    expect(result.generationOf['B'], 0);
    expect(result.generationOf['C'], 0);
    expect(result.generationOf['D'], 1);
  });

  test('con nuôi được tính generation như con ruột', () {
    final persons = [_person('A'), _person('B')];
    final relationships = [_parentChild('A', 'B', childType: ChildType.adopted)];

    final result = GenerationService.computeGenerations(persons, relationships);

    expect(result.generationOf['B'], 1);
  });

  test('married-in dây chuyền: vợ của con trai resolve đúng qua BFS lan truyền', () {
    final persons = [
      _person('A'), // root
      _person('D'), // con của A
      _person('F', gender: Gender.female), // vợ ngoại tộc của D
      _person('G'), // con của D-F
    ];
    final relationships = [
      _parentChild('A', 'D'),
      _marriage('D', 'F'),
      _parentChild('D', 'G'),
      _parentChild('F', 'G'),
    ];

    final result = GenerationService.computeGenerations(persons, relationships);

    expect(result.generationOf['A'], 0);
    expect(result.generationOf['D'], 1);
    expect(result.generationOf['F'], 1);
    expect(result.generationOf['G'], 2);
  });

  test('người treo lơ lửng (không root, không hôn phối) → unlinkedIds', () {
    final persons = [_person('A'), _person('B'), _person('Z')];
    final relationships = [_parentChild('A', 'B')];

    final result = GenerationService.computeGenerations(persons, relationships);

    expect(result.unlinkedIds, ['Z']);
    expect(result.generationOf['Z'], 0);
  });

  test('dữ liệu mâu thuẫn (A vừa là cha B vừa marriage với B) không treo app', () {
    final persons = [_person('A'), _person('B')];
    final relationships = [_parentChild('A', 'B'), _marriage('A', 'B')];

    // Chỉ cần thuật toán trả về kết quả (không throw/không hang) là đạt —
    // cạnh xử lý trước thắng, cạnh mâu thuẫn còn lại bị bỏ qua an toàn.
    final result = GenerationService.computeGenerations(persons, relationships);

    expect(result.generationOf['A'], 0);
    expect(result.generationOf.containsKey('B'), isTrue);
  });
}

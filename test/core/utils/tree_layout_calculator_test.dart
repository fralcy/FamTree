import 'package:fam_tree/core/utils/generation_service.dart';
import 'package:fam_tree/core/utils/tree_layout_calculator.dart';
import 'package:fam_tree/models/index.dart';
import 'package:flutter_test/flutter_test.dart';

const _treeId = 't1';

Person _person(String id, {Gender gender = Gender.male, LunarDate? birthDate}) {
  return Person(
    id: id,
    familyTreeId: _treeId,
    fullName: id,
    gender: gender,
    birthDate: birthDate,
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

  test('đa thê: nhiều vợ xếp theo đúng thứ tự ngày cưới, chồng luôn bên trái', () {
    // Cố tình tạo quan hệ hôn nhân KHÔNG theo thứ tự ngày cưới (W2 trước
    // W1 trong danh sách relationships) để chắc chắn code dùng startDate
    // chứ không phải thứ tự khai báo.
    final h = _person('H');
    final w1 = _person('W1', gender: Gender.female);
    final w2 = _person('W2', gender: Gender.female);
    final persons = [h, w1, w2];
    final relationships = [
      Relationship.createMarriage(
        familyTreeId: _treeId,
        personAId: 'H',
        personBId: 'W2',
        startDate: const LunarDate(day: 1, month: 1, year: 2000),
      ),
      Relationship.createMarriage(
        familyTreeId: _treeId,
        personAId: 'H',
        personBId: 'W1',
        startDate: const LunarDate(day: 1, month: 1, year: 1990),
      ),
    ];
    final generationMap =
        GenerationService.computeGenerations(persons, relationships).generationOf;

    final positions =
        TreeLayoutCalculator.computeNodePositions(persons, relationships, generationMap);

    // H cưới W1 (1990) trước W2 (2000) → thứ tự trái sang phải: H, W1, W2.
    expect(positions['H']!.dx, lessThan(positions['W1']!.dx));
    expect(positions['W1']!.dx, lessThan(positions['W2']!.dx));
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

  test('anh chị em cùng hàng xếp theo ngày sinh (nhỏ tuổi hơn/sinh sau nằm bên phải)', () {
    // Cố tình tạo theo thứ tự C, A, B (không theo ngày sinh) để chắc chắn
    // kết quả không phải tình cờ trùng thứ tự tạo.
    final persons = [
      _person('C', birthDate: const LunarDate(day: 1, month: 1, year: 1990)),
      _person('A', birthDate: const LunarDate(day: 1, month: 1, year: 1970)),
      _person('B', birthDate: const LunarDate(day: 1, month: 1, year: 1980)),
    ];
    final generationMap =
        GenerationService.computeGenerations(persons, []).generationOf;

    final positions = TreeLayoutCalculator.computeNodePositions(persons, [], generationMap);

    expect(positions['A']!.dx, lessThan(positions['B']!.dx));
    expect(positions['B']!.dx, lessThan(positions['C']!.dx));
  });

  test('chồng luôn nằm bên trái vợ, kể cả khi vợ được duyệt tới trước', () {
    // Cố tình liệt kê B (nữ) TRƯỚC A (nam) trong danh sách persons — nếu
    // chỉ dựa vào thứ tự duyệt thì B sẽ thành "anchor" và nằm bên trái.
    final b = _person('B', gender: Gender.female);
    final a = _person('A');
    final persons = [b, a];
    final relationships = [
      Relationship.createMarriage(familyTreeId: _treeId, personAId: 'A', personBId: 'B'),
    ];
    final generationMap =
        GenerationService.computeGenerations(persons, relationships).generationOf;

    final positions =
        TreeLayoutCalculator.computeNodePositions(persons, relationships, generationMap);

    expect(positions['A']!.dx, lessThan(positions['B']!.dx));
  });

  test(
    'vợ/chồng married-in lớn tuổi hơn KHÔNG được kéo lệch thứ tự anh chị em ruột',
    () {
      // A (1970), B (1975), C (1980) là 3 anh chị em ruột (con của R).
      // S là vợ/chồng của B nhưng SINH TRƯỚC CẢ A (1950, "married-in" —
      // không có cha/mẹ nào trong cây) — chỉ nên kéo B đi cùng, không được
      // đẩy cả cặp (B, S) lên vị trí đầu tiên do ngày sinh của S nhỏ nhất.
      final r = _person('R');
      final a = _person('A', birthDate: const LunarDate(day: 1, month: 1, year: 1970));
      final b = _person('B', birthDate: const LunarDate(day: 1, month: 1, year: 1975));
      final c = _person('C', birthDate: const LunarDate(day: 1, month: 1, year: 1980));
      final s = _person(
        'S',
        gender: Gender.female,
        birthDate: const LunarDate(day: 1, month: 1, year: 1950),
      );
      final persons = [r, a, b, c, s];
      final relationships = [
        Relationship.createParentChild(familyTreeId: _treeId, parentId: 'R', childId: 'A'),
        Relationship.createParentChild(familyTreeId: _treeId, parentId: 'R', childId: 'B'),
        Relationship.createParentChild(familyTreeId: _treeId, parentId: 'R', childId: 'C'),
        Relationship.createMarriage(familyTreeId: _treeId, personAId: 'B', personBId: 'S'),
      ];
      final generationMap =
          GenerationService.computeGenerations(persons, relationships).generationOf;

      final positions =
          TreeLayoutCalculator.computeNodePositions(persons, relationships, generationMap);

      expect(positions['A']!.dx, lessThan(positions['B']!.dx));
      expect(positions['B']!.dx, lessThan(positions['C']!.dx));
    },
  );

  test('người chưa rõ ngày sinh xếp sau cùng, giữ nguyên thứ tự tạo với nhau', () {
    // D không có ngày sinh, tạo trước E (cũng không có ngày sinh) — cả 2
    // phải nằm SAU A (có ngày sinh), và D vẫn đứng trước E.
    final persons = [
      _person('D'),
      _person('E'),
      _person('A', birthDate: const LunarDate(day: 1, month: 1, year: 1970)),
    ];
    final generationMap =
        GenerationService.computeGenerations(persons, []).generationOf;

    final positions = TreeLayoutCalculator.computeNodePositions(persons, [], generationMap);

    expect(positions['A']!.dx, lessThan(positions['D']!.dx));
    expect(positions['D']!.dx, lessThan(positions['E']!.dx));
  });
}

import 'package:fam_tree/core/utils/backup_service.dart';
import 'package:fam_tree/models/index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('export rồi import khôi phục đúng dữ liệu', () {
    final tree = FamilyTree.create(name: 'Họ Trần', description: 'Chi trưởng');
    final father = Person.create(
      familyTreeId: tree.id,
      fullName: 'Trần Văn A',
      gender: Gender.male,
      birthDate: DateTime(1950, 3, 1),
      isDeceased: true,
      deathDate: DateTime(2020, 1, 1),
      memorialDate: DateTime(2020, 1, 3),
    );
    final child = Person.create(
      familyTreeId: tree.id,
      fullName: 'Trần Văn B',
      gender: Gender.male,
    );
    final relationship = Relationship.createParentChild(
      familyTreeId: tree.id,
      parentId: father.id,
      childId: child.id,
      childType: ChildType.adopted,
    );

    final json = BackupService.export(
      familyTrees: [tree],
      persons: [father, child],
      relationships: [relationship],
    );

    final restored = BackupService.import(json);

    expect(restored.familyTrees, hasLength(1));
    expect(restored.familyTrees.single.name, 'Họ Trần');

    expect(restored.persons, hasLength(2));
    final restoredFather = restored.persons.firstWhere((p) => p.id == father.id);
    expect(restoredFather.fullName, 'Trần Văn A');
    expect(restoredFather.isDeceased, isTrue);
    expect(restoredFather.deathDate, DateTime(2020, 1, 1));
    expect(restoredFather.memorialDate, DateTime(2020, 1, 3));

    expect(restored.relationships, hasLength(1));
    final restoredRel = restored.relationships.single;
    expect(restoredRel.type, RelationshipType.parentChild);
    expect(restoredRel.childType, ChildType.adopted);
  });

  test('import từ chối schemaVersion tương lai chưa biết đọc', () {
    const futureJson = '{"schemaVersion": 999, "familyTrees": [], "persons": [], "relationships": []}';

    expect(() => BackupService.import(futureJson), throwsUnsupportedError);
  });
}

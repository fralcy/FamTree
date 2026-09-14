import 'dart:io';

import 'package:fam_tree/core/utils/data_manager.dart';
import 'package:fam_tree/models/index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('fam_tree_data_manager_test');
    await DataManager().initialize(hivePath: tempDir.path);
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // Windows can keep the Hive mmap file locked past test run — best-effort.
    }
  });

  test('FamilyTree CRUD', () async {
    final tree = FamilyTree.create(name: 'Họ Nguyễn');
    await DataManager().saveFamilyTree(tree);

    expect(DataManager().getFamilyTree(tree.id)?.name, 'Họ Nguyễn');
    expect(DataManager().getAllFamilyTrees().map((t) => t.id), contains(tree.id));

    await DataManager().deleteFamilyTree(tree.id);
    expect(DataManager().getFamilyTree(tree.id), isNull);
  });

  test('Person CRUD', () async {
    final tree = FamilyTree.create(name: 'Cây test person');
    await DataManager().saveFamilyTree(tree);

    final person = Person.create(
      familyTreeId: tree.id,
      fullName: 'Nguyễn Văn A',
      gender: Gender.male,
    );
    await DataManager().savePerson(person);

    expect(DataManager().getPerson(person.id)?.fullName, 'Nguyễn Văn A');
    expect(
      DataManager().getPersonsByTree(tree.id).map((p) => p.id),
      contains(person.id),
    );

    await DataManager().deletePerson(person.id);
    expect(DataManager().getPerson(person.id), isNull);

    await DataManager().deleteFamilyTree(tree.id);
  });

  test('Relationship CRUD', () async {
    final tree = FamilyTree.create(name: 'Cây test relationship');
    await DataManager().saveFamilyTree(tree);

    final husband = Person.create(
      familyTreeId: tree.id,
      fullName: 'Chồng',
      gender: Gender.male,
    );
    final wife = Person.create(
      familyTreeId: tree.id,
      fullName: 'Vợ',
      gender: Gender.female,
    );
    await DataManager().savePerson(husband);
    await DataManager().savePerson(wife);

    final marriage = Relationship.createMarriage(
      familyTreeId: tree.id,
      personAId: husband.id,
      personBId: wife.id,
    );
    await DataManager().saveRelationship(marriage);

    expect(
      DataManager().getRelationshipsByTree(tree.id).map((r) => r.id),
      contains(marriage.id),
    );

    await DataManager().deleteRelationship(marriage.id);
    expect(DataManager().getRelationshipsByTree(tree.id), isEmpty);

    await DataManager().deleteFamilyTree(tree.id);
  });

  test('deleteFamilyTree cascades to Person and Relationship', () async {
    final tree = FamilyTree.create(name: 'Cây cascade');
    await DataManager().saveFamilyTree(tree);

    final parent = Person.create(
      familyTreeId: tree.id,
      fullName: 'Cha',
      gender: Gender.male,
    );
    final child = Person.create(
      familyTreeId: tree.id,
      fullName: 'Con',
      gender: Gender.male,
    );
    await DataManager().savePerson(parent);
    await DataManager().savePerson(child);

    final relationship = Relationship.createParentChild(
      familyTreeId: tree.id,
      parentId: parent.id,
      childId: child.id,
    );
    await DataManager().saveRelationship(relationship);

    await DataManager().deleteFamilyTree(tree.id);

    expect(DataManager().getPersonsByTree(tree.id), isEmpty);
    expect(DataManager().getRelationshipsByTree(tree.id), isEmpty);
    expect(DataManager().getPerson(parent.id), isNull);
    expect(DataManager().getPerson(child.id), isNull);
  });

  test('deletePerson cascades to related Relationship records only', () async {
    final tree = FamilyTree.create(name: 'Cây xoá person');
    await DataManager().saveFamilyTree(tree);

    final husband = Person.create(
      familyTreeId: tree.id,
      fullName: 'Chồng 2',
      gender: Gender.male,
    );
    final wife = Person.create(
      familyTreeId: tree.id,
      fullName: 'Vợ 2',
      gender: Gender.female,
    );
    final child = Person.create(
      familyTreeId: tree.id,
      fullName: 'Con 2',
      gender: Gender.male,
    );
    await DataManager().savePerson(husband);
    await DataManager().savePerson(wife);
    await DataManager().savePerson(child);

    final marriage = Relationship.createMarriage(
      familyTreeId: tree.id,
      personAId: husband.id,
      personBId: wife.id,
    );
    final parentChildWithMother = Relationship.createParentChild(
      familyTreeId: tree.id,
      parentId: wife.id,
      childId: child.id,
    );
    await DataManager().saveRelationship(marriage);
    await DataManager().saveRelationship(parentChildWithMother);

    await DataManager().deletePerson(husband.id);

    final remaining = DataManager().getRelationshipsByTree(tree.id);
    expect(remaining.map((r) => r.id), isNot(contains(marriage.id)));
    // Xoá husband (marriage) không ảnh hưởng parentChild của wife-child.
    expect(remaining.map((r) => r.id), contains(parentChildWithMother.id));

    await DataManager().deleteFamilyTree(tree.id);
  });

  test('Settings CRUD with defaults', () async {
    expect(DataManager().getThemeId(), DataManager.defaultThemeId);
    expect(DataManager().getLanguageCode(), DataManager.defaultLanguageCode);

    await DataManager().saveThemeId('dark');
    await DataManager().saveLanguageCode('en');

    expect(DataManager().getThemeId(), 'dark');
    expect(DataManager().getLanguageCode(), 'en');

    // reset về mặc định để không ảnh hưởng các test khác chạy sau.
    await DataManager().saveThemeId(DataManager.defaultThemeId);
    await DataManager().saveLanguageCode(DataManager.defaultLanguageCode);
  });
}

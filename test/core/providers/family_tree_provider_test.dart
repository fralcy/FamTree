import 'dart:io';

import 'package:fam_tree/core/providers/family_tree_provider.dart';
import 'package:fam_tree/core/utils/data_manager.dart';
import 'package:fam_tree/models/index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('fam_tree_provider_test');
    await DataManager().initialize(hivePath: tempDir.path);
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // best-effort trên Windows.
    }
  });

  test('addPerson/addRelationship cập nhật danh sách và generationMap', () async {
    final tree = FamilyTree.create(name: 'Cây provider test');
    await DataManager().saveFamilyTree(tree);

    final provider = FamilyTreeProvider(familyTreeId: tree.id);
    expect(provider.persons, isEmpty);

    final father = Person.create(
      familyTreeId: tree.id,
      fullName: 'Cha',
      gender: Gender.male,
    );
    final child = Person.create(
      familyTreeId: tree.id,
      fullName: 'Con',
      gender: Gender.male,
    );
    await provider.addPerson(father);
    await provider.addPerson(child);

    expect(provider.persons, hasLength(2));

    await provider.addRelationship(
      Relationship.createParentChild(
        familyTreeId: tree.id,
        parentId: father.id,
        childId: child.id,
      ),
    );

    expect(provider.childrenOf(father.id).map((p) => p.id), [child.id]);
    expect(provider.generationMap[father.id], 0);
    expect(provider.generationMap[child.id], 1);
  });

  test('childrenThatWouldLoseSoleParent phát hiện đúng con mồ côi', () async {
    final tree = FamilyTree.create(name: 'Cây mồ côi test');
    await DataManager().saveFamilyTree(tree);

    final father = Person.create(familyTreeId: tree.id, fullName: 'Cha 2', gender: Gender.male);
    final mother = Person.create(
      familyTreeId: tree.id,
      fullName: 'Mẹ 2',
      gender: Gender.female,
    );
    final childWithBoth = Person.create(
      familyTreeId: tree.id,
      fullName: 'Con đủ cha mẹ',
      gender: Gender.male,
    );
    final childWithFatherOnly = Person.create(
      familyTreeId: tree.id,
      fullName: 'Con chỉ có cha',
      gender: Gender.male,
    );

    final provider = FamilyTreeProvider(familyTreeId: tree.id);
    await provider.addPerson(father);
    await provider.addPerson(mother);
    await provider.addPerson(childWithBoth);
    await provider.addPerson(childWithFatherOnly);

    await provider.addRelationship(Relationship.createParentChild(
      familyTreeId: tree.id,
      parentId: father.id,
      childId: childWithBoth.id,
    ));
    await provider.addRelationship(Relationship.createParentChild(
      familyTreeId: tree.id,
      parentId: mother.id,
      childId: childWithBoth.id,
    ));
    await provider.addRelationship(Relationship.createParentChild(
      familyTreeId: tree.id,
      parentId: father.id,
      childId: childWithFatherOnly.id,
    ));

    final atRisk = provider.childrenThatWouldLoseSoleParent(father.id);
    expect(atRisk.map((p) => p.id), [childWithFatherOnly.id]);
  });
}

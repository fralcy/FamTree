import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'family_tree.g.dart';

/// typeId registry (do not reuse or renumber once shipped):
/// 0 = FamilyTree
/// 1 = Person
/// 2 = Relationship
/// 3 = Gender            (enum)
/// 4 = RelationshipType  (enum)
/// 5 = ChildType         (enum)
@HiveType(typeId: 0)
class FamilyTree {
  FamilyTree({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyTree.create({required String name, String? description}) {
    final now = DateTime.now();
    return FamilyTree(
      id: const Uuid().v4(),
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  final DateTime updatedAt;

  FamilyTree copyWith({String? name, String? description}) {
    return FamilyTree(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

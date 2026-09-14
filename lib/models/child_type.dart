import 'package:hive/hive.dart';

part 'child_type.g.dart';

/// Only meaningful when [Relationship.type] == [RelationshipType.parentChild].
@HiveType(typeId: 5)
enum ChildType {
  @HiveField(0)
  biological,
  @HiveField(1)
  adopted,
  @HiveField(2)
  step,
}

import 'package:hive/hive.dart';

part 'relationship_type.g.dart';

@HiveType(typeId: 4)
enum RelationshipType {
  @HiveField(0)
  marriage,
  @HiveField(1)
  parentChild,
}

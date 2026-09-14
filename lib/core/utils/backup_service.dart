import 'dart:convert';

import '../../models/index.dart';

/// Chỉ lo (de)serialize JSON + schemaVersion — KHÔNG đụng file I/O, nhờ
/// vậy test được 100% mà không cần platform channel/file_picker.
class BackupService {
  const BackupService._();

  static const int schemaVersion = 1;

  static String export({
    required List<FamilyTree> familyTrees,
    required List<Person> persons,
    required List<Relationship> relationships,
  }) {
    final payload = {
      'schemaVersion': schemaVersion,
      'familyTrees': familyTrees.map(_familyTreeToJson).toList(),
      'persons': persons.map(_personToJson).toList(),
      'relationships': relationships.map(_relationshipToJson).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Ném [FormatException] nếu JSON hỏng, [UnsupportedError] nếu
  /// schemaVersion lớn hơn phiên bản app hiện biết đọc.
  static BackupPayload import(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final version = decoded['schemaVersion'] as int? ?? 0;
    if (version > schemaVersion) {
      throw UnsupportedError(
        'File backup tạo bởi phiên bản app mới hơn (schemaVersion=$version), '
        'chưa biết cách đọc (app hiện hỗ trợ tối đa $schemaVersion).',
      );
    }

    final familyTrees = (decoded['familyTrees'] as List<dynamic>? ?? [])
        .map((e) => _familyTreeFromJson(e as Map<String, dynamic>))
        .toList();
    final persons = (decoded['persons'] as List<dynamic>? ?? [])
        .map((e) => _personFromJson(e as Map<String, dynamic>))
        .toList();
    final relationships = (decoded['relationships'] as List<dynamic>? ?? [])
        .map((e) => _relationshipFromJson(e as Map<String, dynamic>))
        .toList();

    return BackupPayload(
      familyTrees: familyTrees,
      persons: persons,
      relationships: relationships,
    );
  }

  static Map<String, dynamic> _familyTreeToJson(FamilyTree t) => {
        'id': t.id,
        'name': t.name,
        'description': t.description,
        'createdAt': t.createdAt.toIso8601String(),
        'updatedAt': t.updatedAt.toIso8601String(),
      };

  static FamilyTree _familyTreeFromJson(Map<String, dynamic> json) => FamilyTree(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  static Map<String, dynamic> _personToJson(Person p) => {
        'id': p.id,
        'familyTreeId': p.familyTreeId,
        'fullName': p.fullName,
        'gender': p.gender.name,
        'birthDate': p.birthDate?.toIso8601String(),
        'isDeceased': p.isDeceased,
        'deathDate': p.deathDate?.toIso8601String(),
        'memorialDate': p.memorialDate?.toIso8601String(),
        'note': p.note,
        'placeOfBirth': p.placeOfBirth,
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
      };

  static Person _personFromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        familyTreeId: json['familyTreeId'] as String,
        fullName: json['fullName'] as String,
        gender: Gender.values.byName(json['gender'] as String),
        birthDate: _parseNullableDate(json['birthDate']),
        isDeceased: json['isDeceased'] as bool,
        deathDate: _parseNullableDate(json['deathDate']),
        memorialDate: _parseNullableDate(json['memorialDate']),
        note: json['note'] as String?,
        placeOfBirth: json['placeOfBirth'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  static Map<String, dynamic> _relationshipToJson(Relationship r) => {
        'id': r.id,
        'familyTreeId': r.familyTreeId,
        'type': r.type.name,
        'personAId': r.personAId,
        'personBId': r.personBId,
        'childType': r.childType?.name,
        'startDate': r.startDate?.toIso8601String(),
        'endDate': r.endDate?.toIso8601String(),
        'note': r.note,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };

  static Relationship _relationshipFromJson(Map<String, dynamic> json) => Relationship(
        id: json['id'] as String,
        familyTreeId: json['familyTreeId'] as String,
        type: RelationshipType.values.byName(json['type'] as String),
        personAId: json['personAId'] as String,
        personBId: json['personBId'] as String,
        childType: json['childType'] != null
            ? ChildType.values.byName(json['childType'] as String)
            : null,
        startDate: _parseNullableDate(json['startDate']),
        endDate: _parseNullableDate(json['endDate']),
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  static DateTime? _parseNullableDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}

class BackupPayload {
  const BackupPayload({
    required this.familyTrees,
    required this.persons,
    required this.relationships,
  });

  final List<FamilyTree> familyTrees;
  final List<Person> persons;
  final List<Relationship> relationships;
}

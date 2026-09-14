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
        'birthDate': _lunarDateToJson(p.birthDate),
        'isDeceased': p.isDeceased,
        'deathDate': _lunarDateToJson(p.deathDate),
        'memorialDate': _lunarDateToJson(p.memorialDate),
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
        birthDate: _lunarDateFromJson(json['birthDate']),
        isDeceased: json['isDeceased'] as bool,
        deathDate: _lunarDateFromJson(json['deathDate']),
        memorialDate: _lunarDateFromJson(json['memorialDate']),
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
        'startDate': _lunarDateToJson(r.startDate),
        'endDate': _lunarDateToJson(r.endDate),
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
        startDate: _lunarDateFromJson(json['startDate']),
        endDate: _lunarDateFromJson(json['endDate']),
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  static Map<String, dynamic>? _lunarDateToJson(LunarDate? d) => d == null
      ? null
      : {'day': d.day, 'month': d.month, 'year': d.year, 'isLeapMonth': d.isLeapMonth};

  static LunarDate? _lunarDateFromJson(Object? value) {
    if (value == null) return null;
    final json = value as Map<String, dynamic>;
    return LunarDate(
      day: json['day'] as int,
      month: json['month'] as int,
      year: json['year'] as int,
      isLeapMonth: json['isLeapMonth'] as bool? ?? false,
    );
  }
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

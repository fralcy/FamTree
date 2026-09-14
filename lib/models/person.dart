import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'gender.dart';
import 'lunar_date.dart';

part 'person.g.dart';

@HiveType(typeId: 1)
class Person {
  Person({
    required this.id,
    required this.familyTreeId,
    required this.fullName,
    required this.gender,
    this.birthDate,
    required this.isDeceased,
    this.deathDate,
    this.memorialDate,
    this.note,
    this.placeOfBirth,
    this.biography,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Person.create({
    required String familyTreeId,
    required String fullName,
    required Gender gender,
    LunarDate? birthDate,
    bool isDeceased = false,
    LunarDate? deathDate,
    LunarDate? memorialDate,
    String? note,
    String? placeOfBirth,
    String? biography,
  }) {
    final now = DateTime.now();
    return Person(
      id: const Uuid().v4(),
      familyTreeId: familyTreeId,
      fullName: fullName,
      gender: gender,
      birthDate: birthDate,
      isDeceased: isDeceased,
      deathDate: deathDate,
      memorialDate: memorialDate,
      note: note,
      placeOfBirth: placeOfBirth,
      biography: biography,
      createdAt: now,
      updatedAt: now,
    );
  }

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String familyTreeId;
  @HiveField(2)
  final String fullName;
  @HiveField(3)
  final Gender gender;
  @HiveField(4)
  final LunarDate? birthDate;
  @HiveField(5)
  final bool isDeceased;
  @HiveField(6)
  final LunarDate? deathDate;

  /// Ngày giỗ được gia đình chọn — có thể khác [deathDate] thực tế (ví dụ mất
  /// khi còn nhỏ hoặc mất tích). Chỉ là dữ liệu lưu trữ/hiển thị, không có
  /// tính năng nhắc nhở đi kèm.
  @HiveField(7)
  final LunarDate? memorialDate;

  @HiveField(8)
  final String? note;
  @HiveField(9)
  final String? placeOfBirth;
  @HiveField(10)
  final DateTime createdAt;
  @HiveField(11)
  final DateTime updatedAt;

  /// Tiểu sử dài — tách khỏi [note] ngắn, hiển thị dạng expandable/tab
  /// riêng trong UI để không chiếm chỗ form chính.
  @HiveField(12)
  final String? biography;

  Person copyWith({
    String? fullName,
    Gender? gender,
    LunarDate? birthDate,
    bool clearBirthDate = false,
    bool? isDeceased,
    LunarDate? deathDate,
    bool clearDeathDate = false,
    LunarDate? memorialDate,
    bool clearMemorialDate = false,
    String? note,
    String? placeOfBirth,
    String? biography,
  }) {
    return Person(
      id: id,
      familyTreeId: familyTreeId,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      isDeceased: isDeceased ?? this.isDeceased,
      deathDate: clearDeathDate ? null : (deathDate ?? this.deathDate),
      memorialDate: clearMemorialDate ? null : (memorialDate ?? this.memorialDate),
      note: note ?? this.note,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      biography: biography ?? this.biography,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

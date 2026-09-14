import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'gender.dart';

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
    this.photoPath,
    this.note,
    this.placeOfBirth,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Person.create({
    required String familyTreeId,
    required String fullName,
    required Gender gender,
    DateTime? birthDate,
    bool isDeceased = false,
    DateTime? deathDate,
    DateTime? memorialDate,
    String? photoPath,
    String? note,
    String? placeOfBirth,
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
      photoPath: photoPath,
      note: note,
      placeOfBirth: placeOfBirth,
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
  final DateTime? birthDate;
  @HiveField(5)
  final bool isDeceased;
  @HiveField(6)
  final DateTime? deathDate;

  /// Ngày giỗ được gia đình chọn — có thể khác [deathDate] thực tế (ví dụ mất
  /// khi còn nhỏ hoặc mất tích). Chỉ là dữ liệu lưu trữ/hiển thị, không có
  /// tính năng nhắc nhở đi kèm.
  @HiveField(7)
  final DateTime? memorialDate;

  /// Đường dẫn file trong thư mục tài liệu của app — không lưu bytes ảnh.
  @HiveField(8)
  final String? photoPath;
  @HiveField(9)
  final String? note;
  @HiveField(10)
  final String? placeOfBirth;
  @HiveField(11)
  final DateTime createdAt;
  @HiveField(12)
  final DateTime updatedAt;

  Person copyWith({
    String? fullName,
    Gender? gender,
    DateTime? birthDate,
    bool? isDeceased,
    DateTime? deathDate,
    DateTime? memorialDate,
    String? photoPath,
    String? note,
    String? placeOfBirth,
  }) {
    return Person(
      id: id,
      familyTreeId: familyTreeId,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      isDeceased: isDeceased ?? this.isDeceased,
      deathDate: deathDate ?? this.deathDate,
      memorialDate: memorialDate ?? this.memorialDate,
      photoPath: photoPath ?? this.photoPath,
      note: note ?? this.note,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

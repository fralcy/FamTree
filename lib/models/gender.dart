import 'package:hive/hive.dart';

part 'gender.g.dart';

@HiveType(typeId: 3)
enum Gender {
  @HiveField(0)
  male,
  @HiveField(1)
  female,
  // HiveField(2) = other, đã bỏ khỏi phạm vi — không tái dùng số 2.
}

extension GenderX on Gender {
  /// Dùng để tự chọn giới tính mặc định khi thêm vợ/chồng.
  Gender get opposite => this == Gender.male ? Gender.female : Gender.male;
}

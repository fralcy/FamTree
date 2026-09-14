import 'package:hive/hive.dart';

part 'lunar_date.g.dart';

/// Ngày tháng âm lịch tách 3 phần, ghi nhận đúng như gia đình nhớ/lưu
/// truyền — KHÔNG quy đổi sang dương lịch (không cần thuật toán thiên văn
/// new-moon/leap-month; năm chỉ dùng để tính Can Chi hiển thị và sắp xếp
/// tương đối).
@HiveType(typeId: 6)
class LunarDate {
  const LunarDate({
    required this.day,
    required this.month,
    required this.year,
    this.isLeapMonth = false,
  });

  @HiveField(0)
  final int day; // 1-30
  @HiveField(1)
  final int month; // 1-12
  @HiveField(2)
  final int year;
  @HiveField(3)
  final bool isLeapMonth;

  /// So sánh tương đối (không phải lịch dương chính xác) — đủ dùng để sắp
  /// xếp hiển thị, không dùng cho tính toán generation (generation không
  /// phụ thuộc ngày tháng).
  int compareTo(LunarDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LunarDate &&
          day == other.day &&
          month == other.month &&
          year == other.year &&
          isLeapMonth == other.isLeapMonth;

  @override
  int get hashCode => Object.hash(day, month, year, isLeapMonth);
}

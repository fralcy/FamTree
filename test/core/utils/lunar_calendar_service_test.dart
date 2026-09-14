import 'package:fam_tree/core/utils/lunar_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('solarToLunar — các mốc Tết đã biết', () {
    test('Tết Quý Mão 2023 = 22/01/2023 dương lịch', () {
      final r = LunarCalendarService.solarToLunar(22, 1, 2023);
      expect(r.day, 1);
      expect(r.month, 1);
      expect(r.year, 2023);
      expect(r.isLeapMonth, isFalse);
    });

    test('Tết Giáp Thìn 2024 = 10/02/2024 dương lịch', () {
      final r = LunarCalendarService.solarToLunar(10, 2, 2024);
      expect(r.day, 1);
      expect(r.month, 1);
      expect(r.year, 2024);
    });

    test('Tết Ất Tỵ 2025 = 29/01/2025 dương lịch', () {
      final r = LunarCalendarService.solarToLunar(29, 1, 2025);
      expect(r.day, 1);
      expect(r.month, 1);
      expect(r.year, 2025);
    });

    test('Tết Nhâm Dần 2022 = 01/02/2022 dương lịch', () {
      final r = LunarCalendarService.solarToLunar(1, 2, 2022);
      expect(r.day, 1);
      expect(r.month, 1);
      expect(r.year, 2022);
    });

    test('2020 có tháng nhuận 4 (nhuận sau tháng 4)', () {
      // Tết Canh Tý 2020 = 25/01/2020; tháng nhuận 4 âm lịch 2020 rơi vào
      // khoảng 23/05/2020 - 20/06/2020 dương lịch.
      final r = LunarCalendarService.solarToLunar(1, 6, 2020);
      expect(r.month, 4);
      expect(r.isLeapMonth, isTrue);
      expect(r.year, 2020);
    });
  });

  group('lunarToSolar là nghịch đảo của solarToLunar', () {
    test('quy đổi khứ hồi giữ nguyên ngày dương', () {
      final lunar = LunarCalendarService.solarToLunar(10, 2, 2024);
      final solar = LunarCalendarService.lunarToSolar(lunar.day, lunar.month, lunar.year,
          isLeapMonth: lunar.isLeapMonth);
      expect(solar, isNotNull);
      expect(solar!.day, 10);
      expect(solar.month, 2);
      expect(solar.year, 2024);
    });

    test('quy đổi khứ hồi cho ngày có tháng nhuận', () {
      final lunar = LunarCalendarService.solarToLunar(1, 6, 2020);
      final solar = LunarCalendarService.lunarToSolar(lunar.day, lunar.month, lunar.year,
          isLeapMonth: lunar.isLeapMonth);
      expect(solar, isNotNull);
      expect(solar!.day, 1);
      expect(solar.month, 6);
      expect(solar.year, 2020);
    });
  });

  group('Validate ngày không hợp lệ — trả về null, không âm thầm sai', () {
    test('ngày 30 của 1 tháng thiếu (chỉ 29 ngày) trả về null', () {
      // Tháng 1 âm lịch 2024 (bắt đầu 10/02/2024) là tháng thiếu (29 ngày):
      // mùng 1 tháng 2 âm 2024 rơi vào 10/03/2024, cách mùng 1 tháng 1 đúng
      // 29 ngày.
      final solar = LunarCalendarService.lunarToSolar(30, 1, 2024);
      expect(solar, isNull);
    });

    test('ngày 29 hợp lệ cho tháng thiếu', () {
      final solar = LunarCalendarService.lunarToSolar(29, 1, 2024);
      expect(solar, isNotNull);
    });

    test('ngày 0 hoặc âm không hợp lệ', () {
      expect(LunarCalendarService.lunarToSolar(0, 1, 2024), isNull);
    });
  });

  group('Cạnh biên: sinh cuối năm âm lịch có thể lọt sang năm dương kế tiếp', () {
    test('tháng 12 âm lịch năm Kỷ Hợi (2019) có ngày rơi vào tháng 1/2020', () {
      // Tết Canh Tý 2020 rơi vào 25/01/2020 -> ngày 29/30 tháng Chạp năm Kỷ
      // Hợi (lunarYear=2019, month=12) là 23-24/01/2020, vẫn thuộc dương
      // lịch 2020 dù năm âm lịch ghi nhận là 2019.
      final solar = LunarCalendarService.lunarToSolar(29, 12, 2019);
      expect(solar, isNotNull);
      expect(solar!.year, 2020);
      expect(solar.month, 1);
    });
  });
}

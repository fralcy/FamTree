/// Tính tên Can Chi cho 1 năm âm lịch bằng công thức số học thuần —
/// KHÔNG cần bảng tra thiên văn (Can Chi chạy theo chu kỳ cố định 10/12
/// năm, không phụ thuộc lịch âm/dương chuyển đổi).
class CanChiService {
  const CanChiService._();

  static const List<String> _can = [
    'Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý',
  ];
  static const List<String> _chi = [
    'Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi',
  ];

  /// Tên tiếng Anh của Can = Ngũ hành + Âm/Dương (vd Giáp = "Yang Wood").
  static const List<String> _canEn = [
    'Yang Wood', 'Yin Wood',
    'Yang Fire', 'Yin Fire',
    'Yang Earth', 'Yin Earth',
    'Yang Metal', 'Yin Metal',
    'Yang Water', 'Yin Water',
  ];

  /// Tên tiếng Anh của Chi = con vật (vd Tý = "Rat").
  static const List<String> _chiEn = [
    'Rat', 'Ox', 'Tiger', 'Cat', 'Dragon', 'Snake',
    'Horse', 'Goat', 'Monkey', 'Rooster', 'Dog', 'Pig',
  ];

  static int _canIndex(int year) => ((year - 4) % 10 + 10) % 10;
  static int _chiIndex(int year) => ((year - 4) % 12 + 12) % 12;

  /// Ví dụ: canChiForYear(1984) == 'Giáp Tý', canChiForYear(2024) == 'Giáp Thìn'.
  static String canChiForYear(int year) => '${_can[_canIndex(year)]} ${_chi[_chiIndex(year)]}';

  /// Tên tiếng Anh: canChiForYearEn(1984) == 'Yang Wood Rat'.
  static String canChiForYearEn(int year) =>
      '${_canEn[_canIndex(year)]} ${_chiEn[_chiIndex(year)]}';

  /// Nhãn hiển thị đầy đủ dùng trong dropdown chọn năm — tự chọn tiếng
  /// Việt/Anh theo [languageCode] ('vi' mặc định): "Giáp Tý (1984)" hoặc
  /// "Yang Wood Rat (1984)".
  static String yearLabel(int year, {String languageCode = 'vi'}) {
    final name = languageCode == 'en' ? canChiForYearEn(year) : canChiForYear(year);
    return '$name ($year)';
  }
}

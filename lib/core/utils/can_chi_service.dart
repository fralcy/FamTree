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

  /// Ví dụ: canChiForYear(1984) == 'Giáp Tý', canChiForYear(2024) == 'Giáp Thìn'.
  static String canChiForYear(int year) {
    final canIndex = ((year - 4) % 10 + 10) % 10;
    final chiIndex = ((year - 4) % 12 + 12) % 12;
    return '${_can[canIndex]} ${_chi[chiIndex]}';
  }

  /// Nhãn hiển thị đầy đủ dùng trong dropdown chọn năm: "Giáp Tý (1984)".
  static String yearLabel(int year) => '${canChiForYear(year)} ($year)';
}

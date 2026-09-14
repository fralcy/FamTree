import 'package:fam_tree/core/utils/can_chi_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tính đúng Can Chi cho các năm mốc đã biết', () {
    expect(CanChiService.canChiForYear(1984), 'Giáp Tý');
    expect(CanChiService.canChiForYear(2024), 'Giáp Thìn');
    expect(CanChiService.canChiForYear(2025), 'Ất Tỵ');
    expect(CanChiService.canChiForYear(1990), 'Canh Ngọ');
  });

  test('chu kỳ 60 năm lặp lại đúng', () {
    expect(CanChiService.canChiForYear(1924), CanChiService.canChiForYear(1984));
    expect(CanChiService.canChiForYear(1984), CanChiService.canChiForYear(2044));
  });

  test('yearLabel gồm cả tên Can Chi và số năm', () {
    expect(CanChiService.yearLabel(1984), 'Giáp Tý (1984)');
  });
}

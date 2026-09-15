import 'package:flutter/material.dart';

import '../../models/lunar_date.dart';
import '../l10n/app_localizations.dart';
import '../utils/can_chi_service.dart';
import '../utils/lunar_calendar_service.dart';
import 'autocomplete_field.dart';

/// Chọn ngày âm lịch tách 3 phần (KHÔNG dùng showDatePicker dương lịch):
/// Ngày (1-30), Tháng (1-12, kèm cờ nhuận), Năm hiển thị bằng tên Can Chi
/// tự tính từ số năm — cả 3 đều dùng [AutocompleteField] (gõ để lọc) thay
/// vì dropdown dài phải cuộn.
///
/// Sau khi đủ 3 phần, hiển thị thêm chú thích ngày dương lịch quy đổi
/// CHÍNH XÁC (không phải suy đoán cùng số năm) bằng [LunarCalendarService],
/// để xử lý đúng trường hợp sinh cuối năm âm lịch nhưng đã lọt sang đầu
/// năm dương lịch kế tiếp.
///
/// StatefulWidget: PHẢI giữ 3 phần đã chọn ở state cục bộ (không chỉ dựa
/// vào [value] từ cha) — vì [onChanged] chỉ được gọi lên cha khi đủ cả 3
/// phần, nên lựa chọn dở dang (mới chọn Ngày, chưa chọn Tháng/Năm) sẽ mất
/// ngay nếu widget này stateless và rebuild theo `value` (vẫn null) mỗi
/// lần cha setState.
class LunarDateField extends StatefulWidget {
  const LunarDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minYear = 1900,
  });

  final String label;
  final LunarDate? value;
  final ValueChanged<LunarDate?> onChanged;
  final int minYear;

  @override
  State<LunarDateField> createState() => _LunarDateFieldState();
}

class _LunarDateFieldState extends State<LunarDateField> {
  int? _day;
  int? _month;
  int? _year;
  bool _isLeapMonth = false;

  /// Đổi mỗi khi [_clear] được gọi — dùng làm key ép AutocompleteField tạo
  /// lại instance mới, vì bản thân Autocomplete chỉ đọc initialValue ở lần
  /// build đầu (không tự đồng bộ lại khi cha rebuild với giá trị mới), nên
  /// cần key đổi để "reset" hiển thị về rỗng.
  int _resetGeneration = 0;

  static final List<int> _days = List.generate(30, (i) => i + 1);
  static final List<int> _months = List.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    _syncFromValue(widget.value);
  }

  @override
  void didUpdateWidget(LunarDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _syncFromValue(widget.value);
    }
  }

  void _syncFromValue(LunarDate? value) {
    _day = value?.day;
    _month = value?.month;
    _year = value?.year;
    _isLeapMonth = value?.isLeapMonth ?? false;
  }

  List<int> _years() {
    final maxYear = DateTime.now().year + 1;
    return [for (var y = maxYear; y >= widget.minYear; y--) y];
  }

  void _update({int? day, int? month, int? year, bool? isLeapMonth}) {
    setState(() {
      if (day != null) _day = day;
      if (month != null) _month = month;
      if (year != null) _year = year;
      if (isLeapMonth != null) _isLeapMonth = isLeapMonth;
    });
    final d = _day;
    final m = _month;
    final y = _year;
    if (d != null && m != null && y != null) {
      widget.onChanged(LunarDate(day: d, month: m, year: y, isLeapMonth: _isLeapMonth));
    }
  }

  void _clear() {
    setState(() {
      _day = null;
      _month = null;
      _year = null;
      _isLeapMonth = false;
      _resetGeneration++;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final hasAny = _day != null || _month != null || _year != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.label, style: Theme.of(context).textTheme.labelLarge)),
            if (hasAny)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: l10n.clearDate,
                onPressed: _clear,
              ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              _buildDayField(l10n),
              _buildMonthField(l10n),
              _buildYearField(l10n, languageCode),
            ];
            if (constraints.maxWidth < 360) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final f in fields)
                    Padding(padding: const EdgeInsets.only(bottom: 8), child: f),
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 2, child: fields[0]),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: fields[1]),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: fields[2]),
              ],
            );
          },
        ),
        if (widget.value != null) _buildSolarAnnotation(context, l10n, widget.value!),
      ],
    );
  }

  Widget _buildSolarAnnotation(BuildContext context, AppLocalizations l10n, LunarDate date) {
    final solar = LunarCalendarService.lunarToSolar(
      date.day,
      date.month,
      date.year,
      isLeapMonth: date.isLeapMonth,
    );
    final text = solar == null
        ? l10n.invalidLunarDate
        : l10n.solarDateAnnotation(
            solar.day.toString().padLeft(2, '0'),
            solar.month.toString().padLeft(2, '0'),
            solar.year,
          );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: solar == null ? Theme.of(context).colorScheme.error : null,
            ),
      ),
    );
  }

  Widget _buildDayField(AppLocalizations l10n) {
    return AutocompleteField<int>(
      key: ValueKey('day-$_resetGeneration'),
      label: l10n.lunarDay,
      options: _days,
      displayString: (d) => '$d',
      initialValue: _day,
      onSelected: (d) => _update(day: d),
      // Gõ số rồi bấm thẳng nút Lưu (không bấm Enter/rời ô, không bấm chọn
      // gợi ý) trước đây không đăng ký giá trị gì cả — field hiện đúng số
      // vừa gõ nhưng _day vẫn null nên không bao giờ đủ 3 phần để lưu được
      // ngày sinh. Chốt luôn theo TỪNG PHÍM GÕ (không đợi Enter/rời ô) nên
      // luôn có giá trị mới nhất bất kể người dùng thao tác tiếp thế nào.
      onChangedFreeText: (text) {
        final typedDay = int.tryParse(text.trim());
        if (typedDay != null && typedDay >= 1 && typedDay <= 30) {
          _update(day: typedDay);
        }
      },
    );
  }

  Widget _buildMonthField(AppLocalizations l10n) {
    return AutocompleteField<int>(
      key: ValueKey('month-$_resetGeneration'),
      label: l10n.lunarMonth,
      options: _months,
      displayString: (m) => _isLeapMonth ? '$m (${l10n.leapMonth})' : '$m',
      initialValue: _month,
      onSelected: (m) => _update(month: m),
      onChangedFreeText: (text) {
        final typedMonth = int.tryParse(text.trim());
        if (typedMonth != null && typedMonth >= 1 && typedMonth <= 12) {
          _update(month: typedMonth);
        }
      },
      suffixIcon: _month != null
          ? IconButton(
              icon: Icon(
                _isLeapMonth ? Icons.brightness_2 : Icons.brightness_2_outlined,
                size: 18,
              ),
              tooltip: l10n.leapMonth,
              onPressed: () => _update(isLeapMonth: !_isLeapMonth),
            )
          : null,
    );
  }

  /// Gõ số năm hoặc tên Can Chi để lọc nhanh, thay vì cuộn danh sách ~125
  /// mục — vẫn ưu tiên chọn từ danh sách gợi ý, nhưng gõ trực tiếp 1 năm
  /// xa hơn (tổ tiên nhiều đời trước) rồi Enter cũng được chấp nhận.
  Widget _buildYearField(AppLocalizations l10n, String languageCode) {
    final years = _years();
    return AutocompleteField<int>(
      key: ValueKey('year-$_resetGeneration-$languageCode'),
      label: l10n.lunarYear,
      options: years,
      displayString: (y) => CanChiService.yearLabel(y, languageCode: languageCode),
      initialValue: _year,
      onSelected: (y) => _update(year: y),
      onSubmittedFreeText: _commitTypedYear,
      onChangedFreeText: _commitTypedYear,
    );
  }

  void _commitTypedYear(String text) {
    final typedYear = int.tryParse(text.trim());
    if (typedYear != null && typedYear >= 1000 && typedYear <= 2200) {
      _update(year: typedYear);
    }
  }
}

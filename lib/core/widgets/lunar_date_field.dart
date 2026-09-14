import 'package:flutter/material.dart';

import '../../models/lunar_date.dart';
import '../l10n/app_localizations.dart';
import '../utils/can_chi_service.dart';
import '../utils/lunar_calendar_service.dart';

/// Chọn ngày âm lịch tách 3 phần (KHÔNG dùng showDatePicker dương lịch):
/// Ngày (1-30), Tháng (1-12, kèm cờ nhuận), Năm hiển thị bằng tên Can Chi
/// tự tính từ số năm — người dùng chọn trong danh sách, không gõ tay.
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

  /// Đổi mỗi khi [_clear] được gọi — dùng làm key ép DropdownButtonFormField/
  /// Autocomplete tạo lại instance mới, vì bản thân các widget đó chỉ đọc
  /// initialValue ở lần build đầu (không tự đồng bộ lại khi cha rebuild với
  /// giá trị mới), nên cần key đổi để "reset" hiển thị về rỗng.
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
              _buildDayDropdown(l10n),
              _buildMonthDropdown(l10n),
              _buildYearField(l10n),
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

  Widget _buildDayDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<int>(
      key: ValueKey('day-$_resetGeneration'),
      initialValue: _day,
      decoration: InputDecoration(labelText: l10n.lunarDay, isDense: true),
      items: [for (final d in _days) DropdownMenuItem(value: d, child: Text('$d'))],
      onChanged: (d) => _update(day: d),
    );
  }

  Widget _buildMonthDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<int>(
      key: ValueKey('month-$_resetGeneration'),
      initialValue: _month,
      decoration: InputDecoration(
        labelText: l10n.lunarMonth,
        isDense: true,
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
      ),
      items: [for (final m in _months) DropdownMenuItem(value: m, child: Text('$m'))],
      onChanged: (m) => _update(month: m),
    );
  }

  /// Gõ số năm hoặc tên Can Chi để lọc nhanh, thay vì cuộn dropdown ~125
  /// mục — vẫn ưu tiên chọn từ danh sách gợi ý, nhưng gõ trực tiếp 1 năm
  /// xa hơn (tổ tiên nhiều đời trước) rồi Enter cũng được chấp nhận.
  Widget _buildYearField(AppLocalizations l10n) {
    final years = _years();
    return Autocomplete<int>(
      key: ValueKey('year-$_resetGeneration'),
      initialValue: TextEditingValue(
        text: _year != null ? CanChiService.yearLabel(_year!) : '',
      ),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return years;
        return years.where((y) {
          return y.toString().contains(query) ||
              CanChiService.yearLabel(y).toLowerCase().contains(query);
        });
      },
      displayStringForOption: CanChiService.yearLabel,
      onSelected: (y) => _update(year: y),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: l10n.lunarYear, isDense: true),
          onFieldSubmitted: (text) {
            final typedYear = int.tryParse(text.trim());
            if (typedYear != null && typedYear >= 1000 && typedYear <= 2200) {
              _update(year: typedYear);
              controller.text = CanChiService.yearLabel(typedYear);
            }
            onFieldSubmitted();
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final optionList = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionList.length,
                itemBuilder: (context, index) {
                  final option = optionList[index];
                  return ListTile(
                    dense: true,
                    title: Text(CanChiService.yearLabel(option)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

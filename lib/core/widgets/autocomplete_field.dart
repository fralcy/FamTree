import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Ô nhập có gợi ý (search + chọn) dùng chung — thay cho DropdownButtonFormField
/// dài ngoằn phải cuộn (chọn người, ngày/tháng/năm âm lịch...). Gõ để lọc
/// theo [displayString], chọn từ danh sách gợi ý hiện ngay dưới ô nhập.
class AutocompleteField<T extends Object> extends StatelessWidget {
  const AutocompleteField({
    super.key,
    required this.label,
    required this.options,
    required this.displayString,
    required this.onSelected,
    this.initialValue,
    this.validator,
    this.suffixIcon,
    this.onSubmittedFreeText,
    this.onChangedFreeText,
    this.initialVisibleCount,
    this.loadMoreStep = 3,
  });

  final String label;
  final List<T> options;
  final String Function(T) displayString;
  final ValueChanged<T> onSelected;
  final T? initialValue;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  /// Gọi khi người dùng gõ Enter mà chưa chọn từ danh sách gợi ý — dùng
  /// cho trường hợp cần chấp nhận giá trị ngoài [options] (vd năm xa hơn
  /// danh sách hiển thị mặc định). Bỏ qua nếu không cần khả năng này.
  final void Function(String text)? onSubmittedFreeText;

  /// Gọi mỗi khi text thay đổi (từng phím gõ) — dùng để "chốt" giá trị
  /// ngay khi gõ đủ, KHÔNG phụ thuộc vào việc người dùng có bấm Enter hay
  /// rời khỏi ô hay không (bấm thẳng nút Lưu ngay sau khi gõ mà chưa rời ô
  /// trước đó không tự kích hoạt [onSubmittedFreeText]/[onSelected], dẫn
  /// tới giá trị vừa gõ bị mất — xem lunar_date_field.dart).
  final void Function(String text)? onChangedFreeText;

  /// Khi ô TRỐNG (chưa gõ tìm gì) và [options] dài (vd ~125 năm), chỉ hiện
  /// [initialVisibleCount] mục đầu tiên + 1 dòng "Tải thêm" thay vì đổ hết
  /// cả danh sách 1 lần — bấm "Tải thêm" hiện thêm [loadMoreStep] mục mỗi
  /// lần. Gõ tìm (query không rỗng) luôn hiện ĐẦY ĐỦ kết quả khớp, không
  /// phân trang. null (mặc định) = không phân trang, hiện hết như cũ.
  final int? initialVisibleCount;
  final int loadMoreStep;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>(
      initialValue: TextEditingValue(
        text: initialValue != null ? displayString(initialValue as T) : '',
      ),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return options;
        return options.where((o) => displayString(o).toLowerCase().contains(query));
      },
      displayStringForOption: displayString,
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: label, isDense: true, suffixIcon: suffixIcon),
          validator: validator,
          onChanged: onChangedFreeText,
          onFieldSubmitted: onSubmittedFreeText == null
              ? null
              : (text) {
                  onSubmittedFreeText!(text);
                  onFieldSubmitted();
                },
        );
      },
      optionsViewBuilder: (context, onSelected, resultOptions) {
        final optionList = resultOptions.toList();
        // Chỉ phân trang khi kết quả trả về ĐÚNG BẰNG toàn bộ options gốc
        // (nghĩa là query đang rỗng) — có gõ tìm thì luôn hiện đủ kết quả
        // khớp, dù ít hay nhiều.
        final shouldPaginate = initialVisibleCount != null &&
            optionList.length == options.length &&
            optionList.length > initialVisibleCount!;

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 300),
              child: shouldPaginate
                  ? _PaginatedOptionsList<T>(
                      allOptions: optionList,
                      initialCount: initialVisibleCount!,
                      step: loadMoreStep,
                      displayString: displayString,
                      onSelected: onSelected,
                    )
                  : _OptionsList<T>(
                      options: optionList,
                      displayString: displayString,
                      onSelected: onSelected,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _OptionsList<T extends Object> extends StatelessWidget {
  const _OptionsList({
    required this.options,
    required this.displayString,
    required this.onSelected,
  });

  final List<T> options;
  final String Function(T) displayString;
  final AutocompleteOnSelected<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return ListTile(
          dense: true,
          title: Text(displayString(option)),
          onTap: () => onSelected(option),
        );
      },
    );
  }
}

/// Quản lý "đã hiện bao nhiêu mục" CỤC BỘ bên trong overlay gợi ý đang mở —
/// KHÔNG đụng tới TextEditingController/RawAutocomplete của field cha, nhờ
/// vậy bấm "Tải thêm" chỉ rebuild đúng danh sách này tại chỗ, không đóng
/// rồi mở lại cả dropdown (RawAutocomplete chỉ tự chạy lại optionsBuilder
/// khi TEXT thay đổi, không có cách nào "yêu cầu" nó làm mới theo ý muốn).
class _PaginatedOptionsList<T extends Object> extends StatefulWidget {
  const _PaginatedOptionsList({
    required this.allOptions,
    required this.initialCount,
    required this.step,
    required this.displayString,
    required this.onSelected,
  });

  final List<T> allOptions;
  final int initialCount;
  final int step;
  final String Function(T) displayString;
  final AutocompleteOnSelected<T> onSelected;

  @override
  State<_PaginatedOptionsList<T>> createState() => _PaginatedOptionsListState<T>();
}

class _PaginatedOptionsListState<T extends Object> extends State<_PaginatedOptionsList<T>> {
  late int _visibleCount = widget.initialCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visible = widget.allOptions.take(_visibleCount).toList();
    final hasMore = _visibleCount < widget.allOptions.length;

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: visible.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visible.length) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.expand_more, size: 18),
            title: Text(l10n.loadMore),
            onTap: () => setState(() => _visibleCount += widget.step),
          );
        }
        final option = visible[index];
        return ListTile(
          dense: true,
          title: Text(widget.displayString(option)),
          onTap: () => widget.onSelected(option),
        );
      },
    );
  }
}

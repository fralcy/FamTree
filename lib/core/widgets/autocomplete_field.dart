import 'package:flutter/material.dart';

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
      optionsViewBuilder: (context, onSelected, options) {
        final optionList = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionList.length,
                itemBuilder: (context, index) {
                  final option = optionList[index];
                  return ListTile(
                    dense: true,
                    title: Text(displayString(option)),
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

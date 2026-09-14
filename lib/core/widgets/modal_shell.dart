import 'package:flutter/material.dart';

/// Khung modal dùng chung cho mọi showXModal — giới hạn chiều rộng tối đa
/// (tránh dialog bị kéo dài/quá khổ trên desktop) và cung cấp cấu trúc
/// nhất quán: tiêu đề → nội dung cuộn được → hàng nút hành động.
///
/// KHÔNG tự thêm padding/scroll cho [children] — ModalShell lo phần đó,
/// modal gọi chỉ cần truyền danh sách field.
class ModalShell extends StatelessWidget {
  const ModalShell({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.maxWidth = 520,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...children,
            if (actions != null) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var i = 0; i < actions!.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    actions![i],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Xếp 2 field cạnh nhau (Row, mỗi field chia đều không gian) khi đủ rộng
/// (>= [breakpoint]), ngược lại xếp dọc (Column) — dùng để giảm chiều cao
/// form trên màn hình rộng thay vì luôn stack dọc như mobile.
class ResponsiveFieldRow extends StatelessWidget {
  const ResponsiveFieldRow({super.key, required this.children, this.breakpoint = 420});

  final List<Widget> children;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint || children.length < 2) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final c in children) Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: children[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

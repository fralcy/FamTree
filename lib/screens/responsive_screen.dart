import 'package:flutter/widgets.dart';

/// Bộ chọn layout theo LayoutBuilder, dùng chung toàn app — KHÔNG bao giờ
/// dựa vào Platform.isX, nhờ vậy desktop resize nhỏ vẫn fallback mobile,
/// điện thoại xoay ngang vẫn lên desktop layout nếu đủ rộng.
class ResponsiveScreen extends StatelessWidget {
  const ResponsiveScreen({
    super.key,
    required this.mobileBuilder,
    required this.desktopBuilder,
  });

  final WidgetBuilder mobileBuilder;
  final WidgetBuilder desktopBuilder;

  static bool isDesktopSize(Size size) =>
      size.width >= 720 && size.width > size.height && size.height >= 600;

  static bool isDesktop(BoxConstraints c) =>
      isDesktopSize(Size(c.maxWidth, c.maxHeight));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return isDesktop(constraints) ? desktopBuilder(context) : mobileBuilder(context);
      },
    );
  }
}

import 'package:flutter/material.dart';

/// 1 class config bất biến + 1 const List preset + themeById(id) — theo
/// đúng pattern DualCal (mục 6 ARCHITECTURE.md), rút gọn cho phạm vi MVP:
/// chỉ chọn seed color, không cần palette neumorphic riêng.
class AppThemeConfig {
  const AppThemeConfig({
    required this.id,
    required this.label,
    required this.seedColor,
    required this.brightness,
  });

  final String id;
  final String label;
  final Color seedColor;
  final Brightness brightness;
}

const List<AppThemeConfig> appThemes = [
  AppThemeConfig(
    id: 'default',
    label: 'Xanh lá',
    seedColor: Colors.green,
    brightness: Brightness.light,
  ),
  AppThemeConfig(
    id: 'blue',
    label: 'Xanh dương',
    seedColor: Colors.indigo,
    brightness: Brightness.light,
  ),
  AppThemeConfig(
    id: 'brown',
    label: 'Nâu trầm',
    seedColor: Colors.brown,
    brightness: Brightness.light,
  ),
  AppThemeConfig(
    id: 'dark',
    label: 'Tối',
    seedColor: Colors.teal,
    brightness: Brightness.dark,
  ),
];

AppThemeConfig themeById(String id) {
  return appThemes.firstWhere(
    (t) => t.id == id,
    orElse: () => appThemes.first,
  );
}

import 'package:flutter/foundation.dart';

import '../constants/theme_config.dart';
import '../utils/data_manager.dart';

/// ChangeNotifier bọc quanh DataManager cho theme + ngôn ngữ. Đọc
/// DataManager() trong constructor, mọi method thay đổi state gọi
/// DataManager().saveXxx() rồi notifyListeners().
class SettingsProvider extends ChangeNotifier {
  SettingsProvider()
      : _themeId = DataManager().getThemeId(),
        _languageCode = DataManager().getLanguageCode();

  String _themeId;
  String _languageCode;

  String get themeId => _themeId;
  String get languageCode => _languageCode;

  /// Field derive đơn giản từ themeId — không cần tách Provider riêng.
  AppThemeConfig get themeConfig => themeById(_themeId);

  Future<void> setThemeId(String id) async {
    if (id == _themeId) return;
    _themeId = id;
    await DataManager().saveThemeId(id);
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    if (code == _languageCode) return;
    _languageCode = code;
    await DataManager().saveLanguageCode(code);
    notifyListeners();
  }

  void refresh() {
    _themeId = DataManager().getThemeId();
    _languageCode = DataManager().getLanguageCode();
    notifyListeners();
  }
}

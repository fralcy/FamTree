import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/l10n/app_localizations.dart';
import 'core/providers/family_tree_list_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/utils/data_manager.dart';
import 'screens/responsive_app_screen.dart';

/// Cỡ chữ mặc định của Material 3 (bodySmall=12, labelSmall=11...) quá nhỏ
/// để đọc thoải mái, đặc biệt với người lớn tuổi (đối tượng chính dùng app
/// gia phả). Đặt sàn 16px cho MỌI kiểu chữ — chỉ ghi đè fontSize/fontWeight,
/// màu sắc vẫn kế thừa từ ColorScheme của theme đang chọn (ThemeData merge
/// theo từng field, không thay cả TextStyle).
const _appTextTheme = TextTheme(
  displayLarge: TextStyle(fontSize: 40),
  displayMedium: TextStyle(fontSize: 34),
  displaySmall: TextStyle(fontSize: 28),
  headlineLarge: TextStyle(fontSize: 26),
  headlineMedium: TextStyle(fontSize: 24),
  headlineSmall: TextStyle(fontSize: 22),
  titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
  titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  bodyLarge: TextStyle(fontSize: 18),
  bodyMedium: TextStyle(fontSize: 16),
  bodySmall: TextStyle(fontSize: 16),
  labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  labelMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  labelSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await DataManager().initialize();
  } catch (e, st) {
    debugPrint('DataManager init failed: $e\n$st');
  }
  runApp(const FamTreeApp());
}

class FamTreeApp extends StatelessWidget {
  const FamTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => FamilyTreeListProvider()),
      ],
      child: const _ThemedApp(),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeConfig = settings.themeConfig;
    return MaterialApp(
      title: 'Fam Tree',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeConfig.seedColor,
          brightness: themeConfig.brightness,
        ),
        textTheme: _appTextTheme,
        useMaterial3: true,
      ),
      locale: Locale(settings.languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const ResponsiveAppScreen(),
    );
  }
}

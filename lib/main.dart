import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/l10n/app_localizations.dart';
import 'core/providers/family_tree_list_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/utils/data_manager.dart';
import 'screens/responsive_app_screen.dart';

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

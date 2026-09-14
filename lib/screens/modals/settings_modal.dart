import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/theme_config.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/widgets/modal_shell.dart';
import '../responsive_screen.dart';
import 'backup_restore_modal.dart';

Future<void> showSettingsModal(BuildContext context) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));
  const content = _SettingsContent();

  if (isDesktop) {
    return showDialog<void>(
      context: context,
      builder: (context) => const Dialog(child: content),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => content,
  );
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();

    return ModalShell(
      title: l10n.settingsTitle,
      maxWidth: 440,
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)),
      ],
      children: [
        Text(l10n.settingsTheme, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final theme in appThemes)
              ChoiceChip(
                label: Text(theme.label),
                selected: settings.themeId == theme.id,
                onSelected: (_) => settings.setThemeId(theme.id),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(l10n.settingsLanguage, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.languageVietnamese),
              selected: settings.languageCode == 'vi',
              onSelected: (_) => settings.setLanguageCode('vi'),
            ),
            ChoiceChip(
              label: Text(l10n.languageEnglish),
              selected: settings.languageCode == 'en',
              onSelected: (_) => settings.setLanguageCode('en'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.import_export),
          title: Text(l10n.backupTitle),
          onTap: () {
            Navigator.of(context).pop();
            showBackupRestoreModal(context);
          },
        ),
      ],
    );
  }
}

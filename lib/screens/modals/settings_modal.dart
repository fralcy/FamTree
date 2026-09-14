import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/theme_config.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/family_tree_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/widgets/modal_shell.dart';
import '../../models/index.dart';
import '../responsive_screen.dart';
import 'backup_restore_modal.dart';

/// [tree] chỉ có khi mở Settings từ màn hình 1 gia phả đang xem — dùng để
/// bật mục Xuất/Nhập (theo đúng gia phả đó). Mở từ màn hình danh sách gia
/// phả (chưa mở cây nào) thì để null, ẩn mục này vì không có gì để xuất.
///
/// Đọc [FamilyTreeProvider] TRƯỚC khi mở dialog/bottom sheet này rồi bọc
/// lại bằng ChangeNotifierProvider.value — nội dung dialog nằm trong
/// Overlay của Navigator (KHÔNG phải hậu duệ của widget tree màn hình gia
/// phả), nên context bên trong không tự thấy được provider gốc; mục
/// Xuất/Nhập bên trong lại mở tiếp 1 dialog khác cũng cần provider này.
Future<void> showSettingsModal(BuildContext context, {FamilyTree? tree}) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));
  final settingsContent = _SettingsContent(tree: tree);
  final content = tree == null
      ? settingsContent
      : ChangeNotifierProvider.value(
          value: context.read<FamilyTreeProvider>(),
          child: settingsContent,
        );

  if (isDesktop) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(child: content),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => content,
  );
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({this.tree});

  final FamilyTree? tree;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();

    return ModalShell(
      title: l10n.settingsTitle,
      maxWidth: 440,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
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
        Text(
          l10n.settingsLanguage,
          style: Theme.of(context).textTheme.labelLarge,
        ),
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
        if (tree != null) ...[
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.import_export),
            title: Text(l10n.backupTitle),
            onTap: () {
              Navigator.of(context).pop();
              showBackupRestoreModal(context, tree: tree!);
            },
          ),
        ],
      ],
    );
  }
}

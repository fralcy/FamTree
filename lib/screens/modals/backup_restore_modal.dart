import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/family_tree_list_provider.dart';
import '../../core/utils/backup_service.dart';
import '../../core/utils/data_manager.dart';
import '../responsive_screen.dart';

Future<void> showBackupRestoreModal(BuildContext context) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));
  const content = _BackupRestoreContent();

  if (isDesktop) {
    return showDialog<void>(context: context, builder: (context) => Dialog(child: content));
  }
  return showModalBottomSheet<void>(context: context, builder: (context) => content);
}

class _BackupRestoreContent extends StatelessWidget {
  const _BackupRestoreContent();

  Future<void> _export(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final json = BackupService.export(
      familyTrees: DataManager().getAllFamilyTrees(),
      persons: [
        for (final tree in DataManager().getAllFamilyTrees())
          ...DataManager().getPersonsByTree(tree.id),
      ],
      relationships: [
        for (final tree in DataManager().getAllFamilyTrees())
          ...DataManager().getRelationshipsByTree(tree.id),
      ],
    );

    final savePath = await FilePicker.platform.saveFile(
      fileName: 'fam_tree_backup.json',
      bytes: utf8.encode(json),
    );

    if (savePath == null) return;
    // Trên native, saveFile có thể chỉ trả path mà không tự ghi file — ghi
    // thủ công để chắc chắn, best-effort (một số nền tảng đã ghi sẵn).
    try {
      await File(savePath).writeAsString(json);
    } catch (_) {
      // Không phải lỗi nghiêm trọng — nhiều nền tảng (vd. mobile) đã ghi
      // xong file qua bytes ở trên.
    }

    messenger.showSnackBar(SnackBar(content: Text(l10n.backupExportSuccess)));
  }

  Future<void> _import(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final treeListProvider = context.read<FamilyTreeListProvider>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    try {
      final bytes = result.files.single.bytes;
      final jsonString = bytes != null
          ? utf8.decode(bytes)
          : await File(result.files.single.path!).readAsString();

      final payload = BackupService.import(jsonString);
      for (final tree in payload.familyTrees) {
        await DataManager().saveFamilyTree(tree);
      }
      for (final person in payload.persons) {
        await DataManager().savePerson(person);
      }
      for (final relationship in payload.relationships) {
        await DataManager().saveRelationship(relationship);
      }
      treeListProvider.refresh();

      messenger.showSnackBar(SnackBar(content: Text(l10n.backupImportSuccess)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupImportError(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.backupTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _export(context),
            icon: const Icon(Icons.upload_file),
            label: Text(l10n.backupExport),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _import(context),
            icon: const Icon(Icons.download),
            label: Text(l10n.backupImport),
          ),
        ],
      ),
    );
  }
}

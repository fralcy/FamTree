import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/family_tree_list_provider.dart';
import '../../core/providers/family_tree_provider.dart';
import '../../core/utils/backup_service.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/web_file_saver.dart';
import '../../core/widgets/modal_shell.dart';
import '../../models/index.dart';
import '../responsive_screen.dart';

/// Xuất/Nhập chỉ trong phạm vi [tree] đang mở — KHÔNG đụng tới các gia phả
/// khác trong máy, khác với bản backup toàn bộ ứng dụng.
Future<void> showBackupRestoreModal(BuildContext context, {required FamilyTree tree}) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));
  final provider = context.read<FamilyTreeProvider>();
  final content = ChangeNotifierProvider.value(
    value: provider,
    child: _BackupRestoreContent(tree: tree),
  );

  if (isDesktop) {
    return showDialog<void>(context: context, builder: (context) => Dialog(child: content));
  }
  return showModalBottomSheet<void>(context: context, builder: (context) => content);
}

/// Chưa mở cây nào (đang ở màn hình danh sách gia phả) mà muốn nhập —
/// khác với [showBackupRestoreModal] (nhập ĐÈ vào 1 cây đang mở), hàm này
/// luôn TẠO 1 GIA PHẢ MỚI từ file, không đụng tới bất kỳ cây có sẵn nào.
Future<void> showImportNewTreeModal(BuildContext context) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));
  const content = _ImportNewTreeContent();

  if (isDesktop) {
    return showDialog<void>(context: context, builder: (context) => const Dialog(child: content));
  }
  return showModalBottomSheet<void>(context: context, builder: (context) => content);
}

class _ImportNewTreeContent extends StatelessWidget {
  const _ImportNewTreeContent();

  /// Luôn cấp ID MỚI cho gia phả + toàn bộ người/quan hệ trong file (không
  /// tái dùng ID cũ) — đây là bản sao độc lập, không phải ghi đè lên cây có
  /// sẵn nào, nên không có lý do để trùng ID với bất cứ thứ gì trong máy.
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
      final sourceName =
          payload.familyTrees.isNotEmpty ? payload.familyTrees.first.name : l10n.backupTitle;
      final newTree = FamilyTree.create(name: sourceName);
      await DataManager().saveFamilyTree(newTree);

      final personIdMap = <String, String>{};
      for (final person in payload.persons) {
        final newId = const Uuid().v4();
        personIdMap[person.id] = newId;
        await DataManager().savePerson(
          Person(
            id: newId,
            familyTreeId: newTree.id,
            fullName: person.fullName,
            gender: person.gender,
            birthDate: person.birthDate,
            isDeceased: person.isDeceased,
            deathDate: person.deathDate,
            memorialDate: person.memorialDate,
            note: person.note,
            placeOfBirth: person.placeOfBirth,
            biography: person.biography,
            createdAt: person.createdAt,
            updatedAt: person.updatedAt,
          ),
        );
      }
      for (final relationship in payload.relationships) {
        final newPersonAId = personIdMap[relationship.personAId];
        final newPersonBId = personIdMap[relationship.personBId];
        if (newPersonAId == null || newPersonBId == null) continue;
        await DataManager().saveRelationship(
          Relationship(
            id: const Uuid().v4(),
            familyTreeId: newTree.id,
            type: relationship.type,
            personAId: newPersonAId,
            personBId: newPersonBId,
            childType: relationship.childType,
            startDate: relationship.startDate,
            endDate: relationship.endDate,
            note: relationship.note,
            createdAt: relationship.createdAt,
            updatedAt: relationship.updatedAt,
          ),
        );
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
    return ModalShell(
      title: l10n.importNewTreeTitle,
      maxWidth: 440,
      children: [
        Text(l10n.importNewTreeHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _import(context),
          icon: const Icon(Icons.download),
          label: Text(l10n.importNewTreeButton),
        ),
      ],
    );
  }
}

/// Tên file không được chứa các ký tự này trên Windows/macOS/Linux.
final _unsafeFileNameChars = RegExp(r'[\\/:*?"<>|]');

class _BackupRestoreContent extends StatelessWidget {
  const _BackupRestoreContent({required this.tree});

  final FamilyTree tree;

  Future<void> _export(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final json = BackupService.export(
      familyTrees: [tree],
      persons: DataManager().getPersonsByTree(tree.id),
      relationships: DataManager().getRelationshipsByTree(tree.id),
    );

    final safeName = tree.name.replaceAll(_unsafeFileNameChars, '_').trim();
    final fileName = '${safeName.isEmpty ? 'gia_pha' : safeName}.json';

    if (kIsWeb) {
      // file_picker 8.x KHÔNG triển khai saveFile() trên web (luôn ném
      // UnimplementedError) — tự tải file qua thẻ <a download> thay vì
      // FilePicker cho riêng nhánh web.
      saveFileWeb(fileName, json);
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupExportSuccess)));
      return;
    }

    final savePath = await FilePicker.platform.saveFile(
      fileName: fileName,
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

  /// Nhập luôn ghi vào [tree] ĐANG MỞ (không tạo gia phả mới): mỗi người/quan
  /// hệ trong file được gắn lại familyTreeId về [tree.id] rồi upsert theo id
  /// — id đã tồn tại trong cây (vd nhập lại đúng file đã xuất trước đó) thì
  /// bị GHI ĐÈ, id chưa có thì được thêm mới. Bỏ qua familyTrees trong file
  /// (tên/mô tả của cây đang mở giữ nguyên, không bị file ghi đè).
  Future<void> _import(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final treeProvider = context.read<FamilyTreeProvider>();

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
      for (final person in payload.persons) {
        await DataManager().savePerson(
          Person(
            id: person.id,
            familyTreeId: tree.id,
            fullName: person.fullName,
            gender: person.gender,
            birthDate: person.birthDate,
            isDeceased: person.isDeceased,
            deathDate: person.deathDate,
            memorialDate: person.memorialDate,
            note: person.note,
            placeOfBirth: person.placeOfBirth,
            biography: person.biography,
            createdAt: person.createdAt,
            updatedAt: person.updatedAt,
          ),
        );
      }
      for (final relationship in payload.relationships) {
        await DataManager().saveRelationship(
          Relationship(
            id: relationship.id,
            familyTreeId: tree.id,
            type: relationship.type,
            personAId: relationship.personAId,
            personBId: relationship.personBId,
            childType: relationship.childType,
            startDate: relationship.startDate,
            endDate: relationship.endDate,
            note: relationship.note,
            createdAt: relationship.createdAt,
            updatedAt: relationship.updatedAt,
          ),
        );
      }
      treeProvider.refresh();

      messenger.showSnackBar(SnackBar(content: Text(l10n.backupImportSuccess)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupImportError(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ModalShell(
      title: l10n.backupTitle,
      maxWidth: 440,
      children: [
        Text(
          l10n.backupScopeHint(tree.name),
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
    );
  }
}

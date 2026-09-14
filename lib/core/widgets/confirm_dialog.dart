import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Dialog xác nhận dùng chung cho mọi thao tác xoá — trả về true nếu người
/// dùng bấm xác nhận.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

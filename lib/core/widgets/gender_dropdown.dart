import 'package:flutter/material.dart';

import '../../models/gender.dart';
import '../l10n/app_localizations.dart';

/// Dropdown chọn giới tính dùng chung — tránh lặp lại danh sách item ở
/// person_form_modal và relationship_form_modal.
class GenderDropdown extends StatelessWidget {
  const GenderDropdown({super.key, required this.value, required this.onChanged});

  final Gender value;
  final ValueChanged<Gender?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<Gender>(
      initialValue: value,
      decoration: InputDecoration(labelText: l10n.gender, isDense: true),
      items: [
        DropdownMenuItem(value: Gender.male, child: Text(l10n.genderMale)),
        DropdownMenuItem(value: Gender.female, child: Text(l10n.genderFemale)),
        DropdownMenuItem(value: Gender.other, child: Text(l10n.genderOther)),
      ],
      onChanged: onChanged,
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/child_type.dart';
import '../l10n/app_localizations.dart';

/// Dropdown chọn loại con (ruột/nuôi/riêng) — dùng trong
/// relationship_form_modal khi type=parentChild.
class ChildTypeDropdown extends StatelessWidget {
  const ChildTypeDropdown({super.key, required this.value, required this.onChanged});

  final ChildType value;
  final ValueChanged<ChildType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<ChildType>(
      initialValue: value,
      decoration: InputDecoration(labelText: l10n.relationshipTypeParentChild, isDense: true),
      items: [
        DropdownMenuItem(value: ChildType.biological, child: Text(l10n.childTypeBiological)),
        DropdownMenuItem(value: ChildType.adopted, child: Text(l10n.childTypeAdopted)),
        DropdownMenuItem(value: ChildType.step, child: Text(l10n.childTypeStep)),
      ],
      onChanged: onChanged,
    );
  }
}

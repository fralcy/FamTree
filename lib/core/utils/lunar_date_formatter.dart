import '../l10n/app_localizations.dart';
import '../../models/lunar_date.dart';
import 'can_chi_service.dart';

/// Định dạng hiển thị 1 [LunarDate]: "12/3 (nhuận) năm Giáp Tý (1984)".
class LunarDateFormatter {
  const LunarDateFormatter._();

  static String format(AppLocalizations l10n, LunarDate date, {String languageCode = 'vi'}) {
    final leapSuffix = date.isLeapMonth ? ' (${l10n.leapMonth})' : '';
    final yearLabel = CanChiService.yearLabel(date.year, languageCode: languageCode);
    return '${date.day}/${date.month}$leapSuffix - $yearLabel';
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/am_strings.dart';

/// In-app language layer (English ⇄ Amharic).
///
/// The preference is saved on-device; MaterialApp listens to this service so
/// the whole tree rebuilds in the new language instantly. [t] is a plain
/// static lookup so it works everywhere — widgets, models, enum label
/// getters, services — without threading a BuildContext around.
class L10n extends ChangeNotifier {
  L10n._();

  static final L10n instance = L10n._();

  static const _kLocale = 'app_locale';

  static const supportedLocales = <Locale>[Locale('en'), Locale('am')];

  String _code = 'en';

  /// Current language code: 'en' or 'am'.
  String get code => _code;
  bool get isAmharic => _code == 'am';
  Locale get locale => Locale(_code);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocale);
    _code = (saved == 'am') ? 'am' : 'en';
  }

  Future<void> setLocale(String code) async {
    if (code != 'am') code = 'en';
    if (_code == code) return;
    _code = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, code);
  }

  /// Translates [en] to Amharic when the app is in Amharic; otherwise returns
  /// the English source untouched. Unmapped strings fall back to English.
  static String t(String en) =>
      L10n.instance.isAmharic ? (amStrings[en] ?? en) : en;

  /// Locale-aware date formatting: Amharic month/day names in Amharic mode,
  /// the current locale otherwise.
  static String date(DateTime d, String pattern) =>
      DateFormat(pattern, L10n.instance.isAmharic ? 'am' : null).format(d);

  /// Locale-aware full date-time formatting.
  static String dateTime(DateTime d) => DateFormat(
          'MMM d, yyyy h:mm a', L10n.instance.isAmharic ? 'am' : null)
      .format(d);
}

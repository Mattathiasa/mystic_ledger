import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_theme.dart';

/// Dark-mode preference, saved on-device.
///
/// The palette lives in [MysticColors] as swappable static state (every screen
/// reads it directly), so toggling here re-colours the whole app on the next
/// build. MaterialApp reads [isDark] for the brightness too.
class ThemeService extends ChangeNotifier {
  ThemeService._();

  static final ThemeService instance = ThemeService._();

  static const _kDark = 'theme_dark';

  bool _dark = false;

  bool get isDark => _dark;
  ThemeMode get mode => _dark ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _dark = prefs.getBool(_kDark) ?? false;
    _apply();
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    if (_dark == value) return;
    _dark = value;
    _apply();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, value);
  }

  void _apply() {
    if (_dark) {
      MysticColors.useDark();
    } else {
      MysticColors.useLight();
    }
  }
}

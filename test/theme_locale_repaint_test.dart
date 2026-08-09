import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mystic_ledger/services/l10n.dart';
import 'package:mystic_ledger/services/theme_service.dart';
import 'package:mystic_ledger/widgets/app_theme.dart';

/// Mirrors how every real screen reads state: the palette ([MysticColors]) and
/// strings ([L10n.t]) are mutable statics read straight in build(), and the
/// Theme + Localizations dependencies are what force const widget instances to
/// re-run build() when dark mode or the language flips.
///
/// This guards the regression where toggling dark mode / Amharic repainted
/// nothing because the screens were const-identical and never rebuilt.
class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    // The two dependency registrations that make this widget repaint.
    Theme.of(context);
    Localizations.localeOf(context);
    return Scaffold(
      backgroundColor: MysticColors.background,
      body: Center(child: Text(L10n.t('Journal'))),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ListenableBuilder(
        // Same wiring as main.dart: rebuild MaterialApp when either service
        // notifies, which swaps the Theme and Localizations inherited widgets.
        listenable: Listenable.merge([ThemeService.instance, L10n.instance]),
        builder: (context, _) => MaterialApp(
          locale: L10n.instance.locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          theme: buildMysticTheme(),
          darkTheme: buildMysticDarkTheme(),
          themeMode: ThemeService.instance.mode,
          home: const _Probe(),
        ),
      ),
    );
  }

  Color? background(WidgetTester tester) =>
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor;

  String label(WidgetTester tester) =>
      tester.widget<Text>(find.byType(Text)).data!;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.instance.init();
    await L10n.instance.init();
    MysticColors.useLight();
  });

  testWidgets('dark mode flips the palette on a const screen', (tester) async {
    await pump(tester);
    expect(background(tester), const Color(0xFFFBFBE2));

    await ThemeService.instance.setDark(true);
    await tester.pumpAndSettle();
    expect(background(tester), const Color(0xFF191812));

    await ThemeService.instance.setDark(false);
    await tester.pumpAndSettle();
    expect(background(tester), const Color(0xFFFBFBE2));
  });

  testWidgets('language toggle translates a const screen both ways',
      (tester) async {
    await pump(tester);
    expect(label(tester), 'Journal');

    await L10n.instance.setLocale('am');
    await tester.pumpAndSettle();
    expect(label(tester), 'መጽሔት');

    await L10n.instance.setLocale('en');
    await tester.pumpAndSettle();
    expect(label(tester), 'Journal');
  });
}

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Syncs the Android home-screen widget with the ledger.
///
/// The widget is native (XML `RemoteViews`) — this service is the bridge that
/// saves the balance to the shared widget store and triggers a redraw. All
/// methods are no-ops off Android (the widget simply doesn't exist there), so
/// callers never need platform guards of their own.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  /// Must match the provider class registered in the manifest and the Kotlin
  /// receiver that [HomeWidget.updateWidget] resolves by name.
  static const String _providerName = 'BalanceWidgetProvider';
  static const String _qualifiedName =
      'com.mattathiasa.mysticledger.$_providerName';

  /// The URI used by the widget's "Add Entry" button.
  static const String addEntryUri = 'mysticledger://addEntry';

  static const _kBalance = 'balance';
  static const _kLabel = 'label';

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Pushes fresh values to the widget and asks it to redraw.
  ///
  /// [balanceText] is pre-formatted (including masking, when the user has
  /// hidden their balance) — formatting lives in the app so the native layer
  /// stays a dumb renderer.
  Future<void> update({
    required String balanceText,
    required String label,
  }) async {
    if (!supported) return;
    await HomeWidget.saveWidgetData<String>(_kBalance, balanceText);
    await HomeWidget.saveWidgetData<String>(_kLabel, label);
    await HomeWidget.updateWidget(
      name: _providerName,
      qualifiedAndroidName: _qualifiedName,
    );
  }

  /// Stream of taps on the widget — URIs like `mysticledger://addEntry`.
  Stream<Uri?> get onWidgetClicked => HomeWidget.widgetClicked;

  /// The URI the app was opened *from* a widget tap, if any. Check once at
  /// startup.
  Future<Uri?> initiallyLaunchedFromWidget() =>
      HomeWidget.initiallyLaunchedFromHomeWidget();
}

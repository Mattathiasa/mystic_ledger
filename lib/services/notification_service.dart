import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local alerts for the ledger — nothing leaves the device.
///
/// Four kinds are scheduled, each re-armed whenever the app is foregrounded:
///  - budget alerts at 80% and 100% of the period limit,
///  - a debt due-date reminder the day before it is due,
///  - a tithe reminder on the last day of the month,
///  - recurring-schedule prompts on their due day.
///
/// Scheduling is idempotent: each alert carries a stable id, so re-running
/// simply replaces the earlier schedule rather than piling up.
class NotificationService extends ChangeNotifier {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _enabled = false;

  bool get supported => !kIsWeb;

  /// Called once at startup. Safe no-op on the web and unsupported platforms.
  Future<void> init() async {
    if (!supported || _initialized) return;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));
    } catch (_) {
      // Fall back to UTC if the timezone db is missing an entry.
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const settings =
        InitializationSettings(android: android, iOS: darwin, linux: linux);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Ask for the Android 13+ notification permission. Returns the grant state
  /// where the platform reports it, else null.
  Future<bool?> requestPermission() async {
    if (!_initialized || !supported) return null;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission();
      if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value && supported;
    if (_enabled) await requestPermission();
    notifyListeners();
  }

  bool get isEnabled => _enabled;

  // ── Scheduling ────────────────────────────────────────────────────────────

  Future<void> _showAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_enabled || !_initialized) return;
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ledger_alerts',
            'Ledger alerts',
            channelDescription:
                'Budget, debt, tithe and recurring reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Exact alarms can be unavailable on some Android builds; an inexact
      // schedule is still a notification. Ignore rather than crash the flow.
    }
  }

  /// Cancels one alert by its stable id.
  Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  // ── Specific alerts ───────────────────────────────────────────────────────

  /// Alerts for a budget at 80% and 100% of its limit, scheduled for the
  /// *end* of the current period — the moment the answer is known. Re-arming
  /// on each resume keeps the ids stable and the schedule current.
  Future<void> scheduleBudgetAlerts({
    required String budgetId,
    required double spent,
    required double limit,
    required DateTime periodEnd,
  }) async {
    if (!_enabled) return;
    final pct = limit <= 0 ? 1.0 : spent / limit;

    final id80 = 'budget80_$budgetId'.hashCode;
    final id100 = 'budget100_$budgetId'.hashCode;

    if (pct >= 0.8 && pct < 1.0) {
      await _showAt(
        id: id80,
        title: 'Budget nearly spent',
        body: 'You have used ${(pct * 100).toStringAsFixed(0)}% of the '
            '${limit.toStringAsFixed(2)} limit.',
        when: periodEnd,
      );
    } else {
      await cancel(id80);
    }

    if (pct >= 1.0) {
      await _showAt(
        id: id100,
        title: 'Budget limit reached',
        body: 'Spending has met the ${limit.toStringAsFixed(2)} limit for '
            'this period.',
        when: periodEnd,
      );
    } else {
      await cancel(id100);
    }
  }

  /// One reminder the day before a debt comes due, and another on the day.
  Future<void> scheduleDebtReminder({
    required String debtId,
    required String name,
    required DateTime dueDate,
  }) async {
    if (!_enabled) return;
    final dayBefore = dueDate.subtract(const Duration(days: 1));
    await _showAt(
      id: 'debt_before_$debtId'.hashCode,
      title: 'Debt due tomorrow',
      body: '$name comes due tomorrow.',
      when: DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 9),
    );
    await _showAt(
      id: 'debt_on_$debtId'.hashCode,
      title: 'Debt due today',
      body: '$name is due today.',
      when: DateTime(dueDate.year, dueDate.month, dueDate.day, 9),
    );
  }

  Future<void> cancelDebtReminder(String debtId) async {
    await cancel('debt_before_$debtId'.hashCode);
    await cancel('debt_on_$debtId'.hashCode);
  }

  /// Tithe reminder on the last day of [month].
  Future<void> scheduleTitheReminder(DateTime month) async {
    if (!_enabled) return;
    final lastDay = DateTime(month.year, month.month + 1, 0);
    await _showAt(
      id: 'tithe_${month.year}_${month.month}'.hashCode,
      title: 'Tithe check-in',
      body: 'The month ends today — record what you have set aside.',
      when: DateTime(lastDay.year, lastDay.month, lastDay.day, 18),
    );
  }

  /// A nudge on the day a recurring schedule comes due.
  Future<void> scheduleRecurringPrompt({
    required String recurringId,
    required String title,
    required DateTime nextDue,
  }) async {
    if (!_enabled) return;
    await _showAt(
      id: 'recurring_$recurringId'.hashCode,
      title: title,
      body: 'This recurring entry is due — record it in the ledger.',
      when: DateTime(nextDue.year, nextDue.month, nextDue.day, 9),
    );
  }

  Future<void> cancelRecurringPrompt(String recurringId) async {
    await cancel('recurring_$recurringId'.hashCode);
  }
}

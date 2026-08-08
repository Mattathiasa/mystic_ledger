import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/finance_service.dart';
import '../services/sms_capture_service.dart';
import '../services/lock_service.dart';
import '../services/home_widget_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'journal_screen.dart';
import 'ledger_screen.dart';
import 'giving_screen.dart';
import 'insights_screen.dart';
import 'finance_hub_screen.dart';
import 'new_entry_screen.dart';

/// Gives the tabs a handle on the shell that contains them.
///
/// The tabs each build their own `Scaffold`, so neither `Scaffold.of` nor a
/// direct reference reaches the shell's drawer or its tab index. An
/// `InheritedWidget` does, and — unlike threading callbacks through the
/// constructors — it leaves [MainScaffold._screens] `const`, since a const
/// widget still resolves inherited ancestors from its `BuildContext` at build
/// time.
class MainShell extends InheritedWidget {
  final void Function(int index) goToTab;
  final VoidCallback openDrawer;

  const MainShell({
    super.key,
    required this.goToTab,
    required this.openDrawer,
    required super.child,
  });

  static MainShell? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainShell>();

  // Both callbacks are stable for the shell's lifetime, so dependents never
  // need rebuilding on account of this widget.
  @override
  bool updateShouldNotify(MainShell oldWidget) => false;
}

/// Root shell that holds the 5 main tabs.
/// Uses IndexedStack so each screen preserves its scroll position.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  static const int tabJournal  = 0;
  static const int tabLedger   = 1;
  static const int tabGiving   = 2;
  static const int tabInsights = 3;
  static const int tabFinance  = 4;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Home-screen widget bridge: the service is watched so the balance card on
  // the launcher stays in step with the ledger, and widget taps that carry a
  // deep link ("Add Entry") are routed to the entry form.
  FinanceService? _svc;
  StreamSubscription<Uri?>? _widgetTapSub;
  Timer? _widgetSyncDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForWidgetTaps();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Attach the widget-sync listener once the service is reachable. read() is
    // legal here because the provider wraps the whole MaterialApp.
    if (_svc == null) {
      _svc = context.read<FinanceService>();
      _svc!.addListener(_onServiceChanged);
      // First sync after the first frame, once streams have settled.
      WidgetsBinding.instance.addPostFrameCallback((_) => _onServiceChanged());
    }
  }

  Future<void> _listenForWidgetTaps() async {
    // The home-screen widget exists only on Android, and the plugin has no
    // web implementation — calling its channels elsewhere throws
    // MissingPluginException, so the whole bridge is gated on `supported`.
    if (!HomeWidgetService.instance.supported) return;
    // Cold start: the app may have been launched by tapping the widget.
    final uri = await HomeWidgetService.instance.initiallyLaunchedFromWidget();
    _routeWidgetTap(uri);
    _widgetTapSub = HomeWidgetService.instance.onWidgetClicked.listen(_routeWidgetTap);
  }

  void _routeWidgetTap(Uri? uri) {
    if (uri == null) return;
    if (uri.toString() == HomeWidgetService.addEntryUri && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NewEntryScreen()),
      );
    }
  }

  /// Pushes the current balance to the home-screen widget. Debounced so a
  /// burst of Firestore snapshots at startup becomes one redraw.
  void _onServiceChanged() {
    _widgetSyncDebounce?.cancel();
    _widgetSyncDebounce = Timer(const Duration(milliseconds: 400), () {
      final svc = _svc;
      if (svc == null || svc.isLoading) return;
      final fmt = NumberFormat('#,##0.00');
      final hidden = svc.totalHidden;
      HomeWidgetService.instance.update(
        balanceText: hidden
            ? '••••••'
            : '${svc.baseCurrency} ${fmt.format(svc.totalBalance)}',
        label: hidden ? 'BALANCE HIDDEN' : 'TOTAL BALANCE',
      );
    });
  }

  @override
  void dispose() {
    _svc?.removeListener(_onServiceChanged);
    _widgetTapSub?.cancel();
    _widgetSyncDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock before anything is visible again: the moment the app is no longer
    // foregrounded the gate seals, so a returning phone starts at LockScreen.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      LockService.instance.lock();
    }
    // The telephony plugin's background isolate may have queued drafts while
    // the app was paused — reload so the banner and review count are current.
    // Also propose any recurring schedules that came due while away.
    if (state == AppLifecycleState.resumed) {
      SmsCaptureService.instance.refresh();
      if (mounted && context.read<FinanceService>().isLoading == false) {
        final svc = context.read<FinanceService>();
        // Propose schedules that came due while away, then re-arm local
        // alerts so they stay in step with the current data.
        svc.proposeDueRecurring();
        svc.rearmNotifications();
      }
    }
  }

  static const _screens = [
    JournalScreen(),
    LedgerScreen(),
    GivingScreen(),
    InsightsScreen(),
    FinanceHubScreen(),
  ];

  // Methods rather than closures built in build(): a tear-off of an instance
  // method is stable across rebuilds, so the callbacks handed to MainShell keep
  // their identity. That matters because _screens is const — IndexedStack's
  // children are the same instances every frame and Flutter skips rebuilding
  // them.
  void _goToTab(int i) => setState(() => _currentIndex = i);

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    return MainShell(
      goToTab: _goToTab,
      openDrawer: _openDrawer,
      // Wraps the Scaffold, not just the body: MysticAppBar sits inside each
      // tab's own Scaffold and still has to find this.
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: MysticColors.background,
        drawer: const AppDrawer(),
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _MysticBottomNav(
          currentIndex: _currentIndex,
          onTap: _goToTab,
        ),
      ),
    );
  }
}

// ── Custom bottom navigation bar ─────────────────────────────────────────────

class _MysticBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _MysticBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4E8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border(
          top: BorderSide(
            color: MysticColors.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: MysticColors.onSurface.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.auto_stories_outlined,  activeIcon: Icons.auto_stories,            label: 'Journal',  index: 0, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.list_alt_outlined,      activeIcon: Icons.list_alt,                label: 'Ledger',   index: 1, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.volunteer_activism,     activeIcon: Icons.volunteer_activism,      label: 'Giving',   index: 2, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.bar_chart_outlined,     activeIcon: Icons.bar_chart,               label: 'Insights', index: 3, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Finance',  index: 4, currentIndex: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        transform: active
            ? (Matrix4.identity()..rotateZ(-0.017))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? MysticColors.primaryContainer.withOpacity(0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? MysticColors.primary : const Color(0xFF9E9B8A),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 1.0,
                color: active ? MysticColors.primary : const Color(0xFF9E9B8A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

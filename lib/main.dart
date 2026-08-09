import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/finance_service.dart';
import 'services/sms_capture_service.dart';
import 'services/lock_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/onboarding_service.dart';
import 'services/l10n.dart';
import 'services/security_service.dart';
import 'services/cloud_sync_service.dart';
import 'widgets/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/onboarding_screen.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Mobile apps inherit their config from the native files (google-services.json
  // / GoogleService-Info.plist). Web has no native config, so it needs the
  // explicit options from firebase_options.dart to boot at all.
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.web : null,
  );

  // SMS auto-capture: restores the enabled flag and queued drafts, then (on
  // Android) registers the incoming-SMS listener. Safe no-ops elsewhere.
  await SmsCaptureService.instance.init();
  await SmsCaptureService.instance.startListening();

  // App lock: restores the enabled flag; a locked phone starts sealed and the
  // lock screen replaces the UI until the user authenticates.
  await LockService.instance.init();

  // Privacy hardening: shield + Android FLAG_SECURE + inactivity auto-lock.
  await SecurityService.instance.init();

  // Local alerts: prepare the notification plugin (no-op on web).
  await NotificationService.instance.init();

  // Dark mode: restore the preference and paint the palette accordingly.
  await ThemeService.instance.init();

  // Language: restore the English/Amharic preference.
  await L10n.instance.init();

  // Enable offline persistence — app works without internet and syncs when back
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes:     Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MysticLedgerApp());
}

/// How the app learns about the signed-in user. Injectable so widget tests can
/// render the tree without a live Firebase connection.
abstract class AuthSource {
  Stream<User?> get authStateChanges;
  User? get currentUser;
}

/// Production source backed by the real Firebase Auth SDK.
class FirebaseAuthSource implements AuthSource {
  const FirebaseAuthSource();

  @override
  Stream<User?> get authStateChanges => FirebaseAuth.instance.authStateChanges();

  @override
  User? get currentUser => FirebaseAuth.instance.currentUser;
}

/// App root — shows SplashScreen first, then routes to auth gate.
class MysticLedgerApp extends StatelessWidget {
  const MysticLedgerApp({super.key, this.auth = const FirebaseAuthSource()});

  /// Where sign-in state comes from; swap in a fake in tests.
  final AuthSource auth;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // Language changes rebuild the whole tree so every string re-translates.
      listenable: L10n.instance,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: ThemeService.instance,
          builder: (context, _) {
            return StreamProvider<User?>.value(
              value: auth.authStateChanges,
              initialData: auth.currentUser,
              child: MaterialApp(
                title: 'Mystic Ledger',
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
                debugShowCheckedModeBanner: false,
                builder: (context, child) {
                  final user = context.watch<User?>();
                  // Cloud sync indicator: rebind the metadata watcher to the
                  // signed-in user (no-op while already bound).
                  CloudSyncService.instance.ensure(user?.uid);

                  // The root shell wraps everything — including the auth
                  // screen, onboarding and pushed routes — so the privacy
                  // shield sits above every surface when the OS is about to
                  // snapshot the app, and idleness is tracked everywhere.
                  Widget content;
                  if (user == null) {
                    content = child!;
                  } else {
                    content = ListenableBuilder(
                      listenable: LockService.instance,
                      builder: (context, _) {
                        // The lock replaces the whole tree so no screen (nor a
                        // peeking navigator transition) is ever visible while
                        // sealed.
                        if (LockService.instance.isLocked) {
                          return const LockScreen();
                        }
                        return ChangeNotifierProvider<FinanceService>(
                          // Only rebuilds when the user auth state literally
                          // changes.
                          create: (_) => FinanceService(user.uid),
                          child: child!,
                        );
                      },
                    );
                  }
                  return _SecurityShell(child: content);
                },
                home: const SplashScreen(),
              ),
            );
          },
        );
      },
    );
  }
}

/// Auth gate — shown after splash. Listens to Firebase auth state:
/// - Not signed in → AuthScreen
/// - Signed in, first run → OnboardingScreen (once per user)
/// - Signed in → MainScaffold
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Cached per uid so checking the flag does not re-read SharedPreferences on
  // every rebuild of the tree above us.
  String? _checkedUid;

  /// Null while the flag is being read, so the gate can hold on a quiet
  /// loading frame rather than flash the wrong screen for one frame.
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    // Rebuild when the wizard finishes (markComplete notifies).
    OnboardingService.instance.addListener(_onServiceChanged);
  }

  void _onServiceChanged() {
    if (mounted) setState(() => _onboardingComplete = true);
  }

  @override
  void dispose() {
    OnboardingService.instance.removeListener(_onServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when dark mode or the language flips (see MysticColors/L10n).
    Theme.of(context);
    Localizations.localeOf(context);

    final user = context.watch<User?>();

    if (user == null) {
      return const AuthScreen();
    }

    final uid = user.uid;
    if (_checkedUid != uid) {
      _checkedUid = uid;
      _onboardingComplete = null;
      OnboardingService.instance.isComplete(uid).then((done) {
        if (mounted) setState(() => _onboardingComplete = done);
      });
    }

    // One quiet frame while the flag resolves.
    if (_onboardingComplete == null) {
      return Scaffold(
        backgroundColor: MysticColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_onboardingComplete!) {
      return OnboardingScreen(userId: uid);
    }

    return const MainScaffold();
  }
}

// ── Privacy shield ───────────────────────────────────────────────────────────

/// Root shell that guards every screen: it watches the app lifecycle so the
/// branded shield covers the tree the moment the OS may snapshot it (app
/// switcher, home button), and it feeds every interaction to
/// [SecurityService.touch] to power the inactivity auto-lock.
class _SecurityShell extends StatefulWidget {
  final Widget child;
  const _SecurityShell({required this.child});

  @override
  State<_SecurityShell> createState() => _SecurityShellState();
}

class _SecurityShellState extends State<_SecurityShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android: only `paused`/`hidden` really snapshot the screen — `inactive`
    // also fires for benign overlays (notification shade, permission dialogs)
    // that shouldn't flash the shield. iOS: the app-switcher peek reaches
    // `inactive`/`hidden` without ever touching `paused`, so cover there too.
    final shouldCover = defaultTargetPlatform == TargetPlatform.iOS
        ? (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused)
        : (state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden);
    if (shouldCover) {
      SecurityService.instance.cover();
    } else if (state == AppLifecycleState.resumed) {
      SecurityService.instance.uncover();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => SecurityService.instance.touch(),
      child: ListenableBuilder(
        listenable: SecurityService.instance,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (SecurityService.instance.covered) const _PrivacyShield(),
          ],
        ),
      ),
    );
  }
}

/// Opaque, branded full-screen cover shown while the app is away from the
/// foreground — the same mystic surface as the lock screen, with nothing
/// financial visible behind it.
class _PrivacyShield extends StatelessWidget {
  const _PrivacyShield();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF292520),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_outlined,
                size: 56, color: Color(0xFFE3BE5C)),
            const SizedBox(height: 16),
            const Text(
              'Mystic Ledger',
              style: TextStyle(
                fontFamily: 'Epilogue',
                fontSize: 24,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: Color(0xFFF2E9CE),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              L10n.t('The pages are sealed.'),
              style: labelStyle(11,
                  letterSpacing: 1.5, color: const Color(0xFF8F8771)),
            ),
          ],
        ),
      ),
    );
  }
}

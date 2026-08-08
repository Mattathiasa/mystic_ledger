import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/finance_service.dart';
import 'services/sms_capture_service.dart';
import 'services/lock_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/onboarding_service.dart';
import 'widgets/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/onboarding_screen.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // SMS auto-capture: restores the enabled flag and queued drafts, then (on
  // Android) registers the incoming-SMS listener. Safe no-ops elsewhere.
  await SmsCaptureService.instance.init();
  await SmsCaptureService.instance.startListening();

  // App lock: restores the enabled flag; a locked phone starts sealed and the
  // lock screen replaces the UI until the user authenticates.
  await LockService.instance.init();

  // Local alerts: prepare the notification plugin (no-op on web).
  await NotificationService.instance.init();

  // Dark mode: restore the preference and paint the palette accordingly.
  await ThemeService.instance.init();

  // Enable offline persistence — app works without internet and syncs when back
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes:     Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MysticLedgerApp());
}

/// App root — shows SplashScreen first, then routes to auth gate.
class MysticLedgerApp extends StatelessWidget {
  const MysticLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
          child: MaterialApp(
            title: 'Mystic Ledger',
            theme: buildMysticTheme(),
            darkTheme: buildMysticDarkTheme(),
            themeMode: ThemeService.instance.mode,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
          final user = context.watch<User?>();
          if (user == null) return child!;

          return ListenableBuilder(
            listenable: LockService.instance,
            builder: (context, _) {
              // The lock replaces the whole tree so no screen (nor a peeking
              // navigator transition) is ever visible while sealed.
              if (LockService.instance.isLocked) {
                return const LockScreen();
              }
              return ChangeNotifierProvider<FinanceService>(
                // Only rebuilds when the user auth state literally changes
                create: (_) => FinanceService(user.uid),
                child: child!,
              );
            },
          );
        },
            home: const SplashScreen(),
          ),
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
      return const Scaffold(
        backgroundColor: Color(0xFFFDFCF0),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_onboardingComplete!) {
      return OnboardingScreen(userId: uid);
    }

    return const MainScaffold();
  }
}

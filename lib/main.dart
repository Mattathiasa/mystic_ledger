import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/finance_service.dart';
import 'widgets/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
    return StreamProvider<User?>.value(
      value: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      child: MaterialApp(
        title: 'Mystic Ledger',
        theme: buildMysticTheme(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final user = context.watch<User?>();
          if (user == null) return child!;

          return ChangeNotifierProvider<FinanceService>(
            // Only rebuilds when the user auth state literally changes
            create: (_) => FinanceService(user.uid),
            child: child!,
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}

/// Auth gate — shown after splash. Listens to Firebase auth state:
/// - Not signed in → AuthScreen
/// - Signed in → MainScaffold
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    if (user == null) {
      return const AuthScreen();
    }

    return const MainScaffold();
  }
}

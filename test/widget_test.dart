import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/main.dart';
import 'package:mystic_ledger/screens/splash_screen.dart';

/// Auth source that never touches Firebase — lets the widget tree render in
/// the test environment where the SDKs are not connected.
class _FakeAuthSource implements AuthSource {
  const _FakeAuthSource();

  @override
  Stream<User?> get authStateChanges => const Stream<User?>.empty();

  @override
  User? get currentUser => null;
}

void main() {
  testWidgets('App smoke test — renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MysticLedgerApp(auth: _FakeAuthSource()),
    );
    await tester.pump();

    expect(find.byType(MysticLedgerApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}

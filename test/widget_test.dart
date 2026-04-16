import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/main.dart';

void main() {
  testWidgets('App smoke test — renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const MysticLedgerApp());
    expect(find.byType(MysticLedgerApp), findsOneWidget);
  });
}

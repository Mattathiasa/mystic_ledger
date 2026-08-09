import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mystic_ledger/services/sms_capture_store.dart';
import 'package:mystic_ledger/services/sms_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('captureIncoming is a no-op while disabled', () async {
    final draft = await SmsCaptureStore.captureIncoming(
      sender: 'Telebirr',
      body: 'You have received ETB 100.00 from Abebe.',
    );
    expect(draft, isNull);
    expect(await SmsCaptureStore.loadDrafts(), isEmpty);
  });

  test('captureIncoming ignores messages from unknown banks', () async {
    await SmsCaptureStore.setEnabled(true);
    final draft = await SmsCaptureStore.captureIncoming(
      sender: 'ZEMEN BANK',
      body: 'Your account was credited with ETB 900.',
    );
    expect(draft, isNull);
  });

  test('queues real CBE alerts from the CBE sender', () async {
    await SmsCaptureStore.setEnabled(true);
    const body = 'Dear Mr Mattathias your Account 1****0486 has been '
        'credited by SALARY SUSPENSE AGOZA GEBEYA BRANCH with ETB 13000.00. '
        'Your Current Balance is ETB 21878.45. Thank you for Banking with CBE!';
    final draft = await SmsCaptureStore.captureIncoming(
        sender: 'CBE', body: body);
    expect(draft, isNotNull);
    expect(draft!.bank, CapturedBank.cbe);
    expect(draft.amount, 13000.0);
    expect(draft.direction, CapturedDirection.income);
    expect(draft.counterparty, 'SALARY SUSPENSE AGOZA GEBEYA BRANCH');
    expect(draft.confidence, SmsConfidence.high);
  });

  test('skips noise with no amount and no direction (OTPs, promos)', () async {
    await SmsCaptureStore.setEnabled(true);
    final draft = await SmsCaptureStore.captureIncoming(
      sender: '127',
      body: 'Your telebirr OTP is 482913. Valid for 5 minutes. Ethio telecom',
    );
    expect(draft, isNull);
    expect(await SmsCaptureStore.loadDrafts(), isEmpty);
  });

  test('pruneUnparsed drops junk drafts but keeps recordable ones', () async {
    await SmsCaptureStore.setEnabled(true);
    await SmsCaptureStore.captureIncoming(
      sender: 'CBE',
      body: 'credited by SALARY with ETB 13000.00',
    );
    // A junk draft queued before the skip rule existed.
    await SmsCaptureStore.addDraft(CapturedSms(
      id: 'sig:junk1',
      bank: CapturedBank.telebirr,
      sender: '127',
      body: 'OTP 1234',
      amount: null,
      direction: CapturedDirection.unknown,
      counterparty: null,
      fee: null,
      reference: null,
      date: null,
      capturedAt: DateTime.now(),
      confidence: SmsConfidence.low,
    ));

    final removed = await SmsCaptureStore.pruneUnparsed();
    expect(removed, 1);

    final remaining = await SmsCaptureStore.loadDrafts();
    expect(remaining.length, 1);
    expect(remaining.first.amount, 13000.0);
  });

  test('captures, dedups, and queues exactly one draft per message', () async {
    await SmsCaptureStore.setEnabled(true);
    const body = 'You have received ETB 250.00 from Abebe Kebede.';

    final first = await SmsCaptureStore.captureIncoming(
        sender: 'Telebirr', body: body);
    expect(first, isNotNull);
    expect(first!.amount, 250.0);

    // Re-arrival (live listener + later backfill) must not duplicate.
    final second =
        await SmsCaptureStore.captureIncoming(sender: 'Telebirr', body: body);
    expect(second, isNull);

    final drafts = await SmsCaptureStore.loadDrafts();
    expect(drafts.length, 1);

    await SmsCaptureStore.removeDraft(first.id);
    expect(await SmsCaptureStore.loadDrafts(), isEmpty);
  });

  test('drafts persist across reloads', () async {
    await SmsCaptureStore.setEnabled(true);
    await SmsCaptureStore.captureIncoming(
      sender: 'Telebirr',
      body: 'You have sent ETB 50.00 to 0912345678. Service fee ETB 1.00.',
    );
    final reloaded = await SmsCaptureStore.loadDrafts();
    expect(reloaded.length, 1);
    expect(reloaded.first.amount, 50.0);
    expect(reloaded.first.fee, 1.0);
  });

  test('disabling the feature keeps previously queued drafts intact', () async {
    await SmsCaptureStore.setEnabled(true);
    await SmsCaptureStore.captureIncoming(
      sender: 'Telebirr',
      body: 'You have received ETB 75.00 from X.',
    );
    await SmsCaptureStore.setEnabled(false);
    expect(await SmsCaptureStore.loadDrafts(), hasLength(1));

    // And new messages are ignored while disabled.
    final draft = await SmsCaptureStore.captureIncoming(
      sender: 'Telebirr',
      body: 'You have received ETB 99.00 from Y.',
    );
    expect(draft, isNull);
  });
}

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:share_plus/share_plus.dart';
import '../models/account_model.dart';
import '../models/app_settings.dart';
import '../models/budget_model.dart';
import '../models/debt_model.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../models/transfer_model.dart';
import 'finance_service.dart';

/// Encrypted, shareable archive of every record — the `.mlbackup` format.
///
/// The payload is a plain-JSON envelope describing all collections plus the
/// currency settings. It is encrypted with AES-256-GCM under a key derived
/// from the user's chosen password with PBKDF2-HMAC-SHA256 (150 000 rounds,
/// random 128-bit salt). The envelope carries the salt, nonce and MAC, so the
/// password alone — with the exact bytes — can decrypt it.
///
/// This is deliberately separate from the CSV export: CSV is for spreadsheets
/// and migration; the backup is the exact-restore path.
class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  static const int _kdfIterations = 150000;
  static const String _kVersion = '1';

  /// Keys that hold dates in model maps — only these are converted to ISO
  /// strings when serialising and back to Timestamps when restoring, so a
  /// note or title that merely looks like a date is never touched.
  static const _dateKeys = {'date', 'dueDate', 'nextDue', 'exportedAt'};

  // ── Build payload ─────────────────────────────────────────────────────────

  /// All records as one plain-JSON map (dates as ISO strings).
  static Map<String, dynamic> buildPayload(FinanceService svc) {
    Map<String, dynamic> plain(Map<String, dynamic> m) => {
          for (final e in m.entries)
            e.key: (_dateKeys.contains(e.key) && e.value is Timestamp)
                ? (e.value as Timestamp).toDate().toIso8601String()
                : e.value,
        };

    return {
      'version': _kVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': svc.allAccounts.map((a) => a.toMap()).toList(),
      'transactions':
          svc.transactions.map((t) => plain(t.toMap())).toList(),
      'transfers': svc.transfers.map((t) => plain(t.toMap())).toList(),
      'debts': svc.debts.map((d) => plain(d.toMap())).toList(),
      'budgets': svc.budgets.map((b) => b.toMap()).toList(),
      'recurring': svc.recurring.map((r) => plain(r.toMap())).toList(),
      'settings': svc.settings.toMap(),
    };
  }

  // ── Encryption ────────────────────────────────────────────────────────────

  /// Encrypts [plaintext] under [password], returning the `.mlbackup` bytes.
  static Future<Uint8List> encryptToFileBytes(
      String plaintext, String password) async {
    final random = Random.secure();
    final salt =
        Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
    final nonce =
        Uint8List.fromList(List.generate(12, (_) => random.nextInt(256)));

    final kdf = crypto.Pbkdf2(
      macAlgorithm: crypto.Hmac.sha256(),
      iterations: _kdfIterations,
      bits: 256,
    );
    final key =
        await kdf.deriveKeyFromPassword(password: password, nonce: salt);

    final secretBox = await crypto.AesGcm.with256bits().encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    final envelope = jsonEncode({
      'version': _kVersion,
      'kdf': 'pbkdf2-sha256',
      'iterations': _kdfIterations,
      'salt': base64Encode(salt),
      'alg': 'aes-256-gcm',
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    });
    return Uint8List.fromList(utf8.encode(envelope));
  }

  /// Decrypts `.mlbackup` bytes. Throws on a wrong password or tampered file.
  static Future<String> decryptFileBytes(
      Uint8List bytes, String password) async {
    final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final kdf = crypto.Pbkdf2(
      macAlgorithm: crypto.Hmac.sha256(),
      iterations: envelope['iterations'] as int? ?? _kdfIterations,
      bits: 256,
    );
    final key = await kdf.deriveKeyFromPassword(
      password: password,
      nonce: base64Decode(envelope['salt'] as String),
    );
    final secretBox = crypto.SecretBox(
      base64Decode(envelope['ciphertext'] as String),
      nonce: base64Decode(envelope['nonce'] as String),
      mac: crypto.Mac(base64Decode(envelope['mac'] as String)),
    );
    final clear =
        await crypto.AesGcm.with256bits().decrypt(secretBox, secretKey: key);
    return utf8.decode(clear);
  }

  // ── Share ─────────────────────────────────────────────────────────────────

  /// Builds, encrypts and shares the archive. Returns false when the user
  /// dismissed the share sheet.
  static Future<bool> shareBackup(FinanceService svc, String password) async {
    final payload = buildPayload(svc);
    final bytes = await encryptToFileBytes(jsonEncode(payload), password);
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;

    final file = XFile.fromData(
      bytes,
      mimeType: 'application/octet-stream',
      name: 'mystic_ledger_$stamp.mlbackup',
    );
    final result = await Share.shareXFiles([file],
        subject: 'Mystic Ledger backup');
    return result.status != ShareResultStatus.dismissed;
  }

  // ── Restore parsing ───────────────────────────────────────────────────────

  /// Parses a decrypted payload into model lists ready to write back.
  ///
  /// Throws [FormatException] when the archive version is unsupported — a
  /// restore wipes first, so an unknown format must fail loudly rather than
  /// silently mis-parse into a mostly-empty ledger.
  static BackupData parsePayload(Map<String, dynamic> payload) {
    final version = payload['version'];
    if (version != _kVersion) {
      throw FormatException('Unsupported backup version: $version');
    }

    Map<String, dynamic> restoreMap(Map<String, dynamic> m) => {
          for (final e in m.entries)
            e.key: (_dateKeys.contains(e.key) && e.value is String)
                ? Timestamp.fromDate(DateTime.parse(e.value as String))
                : e.value,
        };

    List<T> parseList<T>(
        String key, T Function(Map<String, dynamic>) fromMap) {
      return (payload[key] as List? ?? const [])
          .map((e) => fromMap((e as Map).cast<String, dynamic>()))
          .toList();
    }

    final accounts = parseList<Account>('accounts', Account.fromMap);
    final transactions = parseList<Transaction>(
        'transactions', (m) => Transaction.fromMap(restoreMap(m)));
    final transfers = parseList<Transfer>(
        'transfers', (m) => Transfer.fromMap(restoreMap(m)));
    final debts =
        parseList<Debt>('debts', (m) => Debt.fromMap(restoreMap(m)));
    final budgets = parseList<Budget>('budgets', Budget.fromMap);
    final recurring = parseList<RecurringTransaction>(
        'recurring', (m) => RecurringTransaction.fromMap(restoreMap(m)));
    final settings = payload['settings'] == null
        ? null
        : AppSettings.fromMap(
            (payload['settings'] as Map).cast<String, dynamic>());

    return BackupData(
      accounts: accounts,
      transactions: transactions,
      transfers: transfers,
      debts: debts,
      budgets: budgets,
      recurring: recurring,
      settings: settings,
      exportedAt: payload['exportedAt'] is String
          ? DateTime.tryParse(payload['exportedAt'] as String)
          : null,
    );
  }
}

/// Everything a restore needs, parsed from a decrypted payload.
class BackupData {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Transfer> transfers;
  final List<Debt> debts;
  final List<Budget> budgets;
  final List<RecurringTransaction> recurring;
  final AppSettings? settings;
  final DateTime? exportedAt;

  const BackupData({
    required this.accounts,
    required this.transactions,
    required this.transfers,
    required this.debts,
    required this.budgets,
    required this.recurring,
    required this.settings,
    this.exportedAt,
  });

  /// Every record that will be written back.
  int get count =>
      accounts.length +
      transactions.length +
      transfers.length +
      debts.length +
      budgets.length +
      recurring.length;
}

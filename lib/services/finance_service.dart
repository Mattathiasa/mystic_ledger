import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_model.dart';
import '../models/transaction.dart';
import '../models/transfer_model.dart';
import '../models/debt_model.dart';
import '../models/budget_model.dart';
import '../models/app_settings.dart';

/// Time windows shared by the Giving and Insights screens.
enum LedgerPeriod { week, month, sixMonths, year, all }

extension LedgerPeriodDisplay on LedgerPeriod {
  String get label {
    switch (this) {
      case LedgerPeriod.week:      return 'This Week';
      case LedgerPeriod.month:     return 'This Month';
      case LedgerPeriod.sixMonths: return 'Last 6 Months';
      case LedgerPeriod.year:      return 'This Year';
      case LedgerPeriod.all:       return 'All Time';
    }
  }

  /// Inclusive lower bound, or null for [LedgerPeriod.all].
  DateTime? startFrom(DateTime now) {
    switch (this) {
      case LedgerPeriod.week:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      case LedgerPeriod.month:
        return DateTime(now.year, now.month, 1);
      case LedgerPeriod.sixMonths:
        return DateTime(now.year, now.month - 5, 1);
      case LedgerPeriod.year:
        return DateTime(now.year, 1, 1);
      case LedgerPeriod.all:
        return null;
    }
  }
}

/// Central store for all financial data.
/// Subscribes to Firestore real-time streams for the authenticated user.
/// Exposes the same API as before — all existing screens work unchanged.
class FinanceService extends ChangeNotifier {
  // There are deliberately no well-known account IDs. Nothing is created for
  // the user at sign-up, so no particular account is guaranteed to exist;
  // savings is identified by [AccountType.savings], not by a fixed id.

  // ── Firestore references ──────────────────────────────────────────────────
  final String userId;
  final _db = FirebaseFirestore.instance;

  CollectionReference get _accounts     => _db.collection('users/$userId/accounts');
  CollectionReference get _transactions => _db.collection('users/$userId/transactions');
  CollectionReference get _transfers    => _db.collection('users/$userId/transfers');
  CollectionReference get _debts        => _db.collection('users/$userId/debts');
  CollectionReference get _budgets      => _db.collection('users/$userId/budgets');
  DocumentReference    get _settingsDoc => _db.doc('users/$userId/settings/prefs');

  // ── Local caches (updated by Firestore stream listeners) ──────────────────
  List<Account>     _accountList     = [];
  List<Transaction> _transactionList = [];
  List<Transfer>    _transferList    = [];
  List<Debt>        _debtList        = [];
  List<Budget>      _budgetList      = [];
  AppSettings       _settings        = const AppSettings();
  bool _isLoading = true;

  // Privacy is device-local (SharedPreferences), not synced: it is about who
  // can see this phone's screen, not about the account.
  bool _totalHidden = false;
  Set<String> _hiddenAccountIds = {};

  bool get isLoading   => _isLoading;
  AppSettings get settings => _settings;
  String get baseCurrency  => _settings.baseCurrency;
  double get titheRate     => _settings.titheRate;

  final List<StreamSubscription> _subs = [];

  // ── Constructor ───────────────────────────────────────────────────────────

  FinanceService(this.userId) {
    _loadPrefs();
    _subscribe();
  }

  // ── Privacy (device-local) ────────────────────────────────────────────────

  static const _kTotalHidden    = 'balance_hidden';   // legacy key, reused
  static const _kHiddenAccounts = 'hidden_accounts';

  bool get totalHidden => _totalHidden;

  /// True when [accountId]'s balance should be masked.
  bool isAccountHidden(String accountId) =>
      _hiddenAccountIds.contains(accountId);

  /// True when every account and the total are masked.
  bool get allHidden =>
      _totalHidden && _accountList.every((a) => isAccountHidden(a.id));

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _totalHidden = prefs.getBool(_kTotalHidden) ?? false;
    _hiddenAccountIds =
        (prefs.getStringList(_kHiddenAccounts) ?? const <String>[]).toSet();
    notifyListeners();
  }

  Future<void> _persistPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTotalHidden, _totalHidden);
    await prefs.setStringList(_kHiddenAccounts, _hiddenAccountIds.toList());
  }

  Future<void> toggleTotalVisibility() async {
    _totalHidden = !_totalHidden;
    notifyListeners();
    await _persistPrivacy();
  }

  Future<void> toggleAccountVisibility(String accountId) async {
    if (!_hiddenAccountIds.add(accountId)) {
      _hiddenAccountIds.remove(accountId);
    }
    notifyListeners();
    await _persistPrivacy();
  }

  Future<void> hideAll() async {
    _totalHidden = true;
    _hiddenAccountIds = _accountList.map((a) => a.id).toSet();
    notifyListeners();
    await _persistPrivacy();
  }

  Future<void> showAll() async {
    _totalHidden = false;
    _hiddenAccountIds = {};
    notifyListeners();
    await _persistPrivacy();
  }

  void _subscribe() {
    // Accounts
    _subs.add(_accounts.snapshots().listen((snap) {
      _accountList = snap.docs
          .map((d) => Account.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      _checkLoaded();
    }));

    // Transactions — newest first
    _subs.add(_transactions
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      _transactionList = snap.docs
          .map((d) => Transaction.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      _checkLoaded();
    }));

    // Transfers — newest first
    _subs.add(_transfers
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      _transferList = snap.docs
          .map((d) => Transfer.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      _checkLoaded();
    }));

    // Debts — newest first
    _subs.add(_debts
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      _debtList = snap.docs
          .map((d) => Debt.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      _checkLoaded();
    }));

    // Budgets
    _subs.add(_budgets.snapshots().listen((snap) {
      _budgetList = snap.docs
          .map((d) => Budget.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      _checkLoaded();
    }));

    // Settings (base currency, tithe rate, exchange rates).
    // A user who has never opened settings has no doc — defaults apply.
    _subs.add(_settingsDoc.snapshots().listen((snap) {
      _settings = snap.exists
          ? AppSettings.fromMap(snap.data() as Map<String, dynamic>)
          : const AppSettings();
      _checkLoaded();
    }));
  }

  /// Number of streams opened in [_subscribe]; loading ends once each has
  /// delivered at least one snapshot.
  static const int _streamCount = 6;

  int _loadedCount = 0;
  void _checkLoaded() {
    _loadedCount++;
    if (_loadedCount >= _streamCount) _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  // ── READ: Accounts ────────────────────────────────────────────────────────

  /// Active accounts only (shown in home, pickers, etc.)
  List<Account> get accounts =>
      List.unmodifiable(_accountList.where((a) => a.isActive));

  /// All accounts including inactive (for management screens)
  List<Account> get allAccounts => List.unmodifiable(_accountList);

  /// Active non-savings accounts for spending/transfer pickers
  List<Account> get spendableAccounts =>
      _accountList.where((a) => a.isActive && a.type != AccountType.savings).toList();

  // ── READ: Savings ─────────────────────────────────────────────────────────
  //
  // Savings is a *kind* of account, not one particular account. There may be
  // none, one, or several, and each holds its own currency.

  List<Account> get savingsAccounts => _accountList
      .where((a) => a.isActive && a.type == AccountType.savings)
      .toList();

  bool get hasSavingsAccount => savingsAccounts.isNotEmpty;

  bool isSavingsAccount(String id) =>
      findAccount(id)?.type == AccountType.savings;

  /// Every transfer touching any vault, in one pass so a vault-to-vault
  /// movement is listed once rather than twice.
  List<Transfer> get savingsTransfers {
    final ids = savingsAccounts.map((a) => a.id).toSet();
    if (ids.isEmpty) return const [];
    return _transferList
        .where((t) =>
            ids.contains(t.fromAccountId) || ids.contains(t.toAccountId))
        .toList();
  }

  /// True only when every vault is masked — with no vaults there is nothing
  /// being hidden, so this is false rather than vacuously true.
  bool get savingsHidden =>
      savingsAccounts.isNotEmpty &&
      savingsAccounts.every((a) => isAccountHidden(a.id));

  SavingsSummary get savingsSummary => computeSavingsSummary(
        savingsAccounts,
        accountBalance,
        _settings.rateFor,
        baseCurrency,
      );

  Account? findAccount(String id) {
    try { return _accountList.firstWhere((a) => a.id == id); }
    catch (_) { return null; }
  }

  // ── READ: Transactions ────────────────────────────────────────────────────

  List<Transaction> get transactions => List.unmodifiable(_transactionList);

  List<Transaction> get recentTransactions =>
      _transactionList.take(5).toList();

  List<Transaction> filteredBy(TransactionType? type) {
    if (type == null) return _transactionList;
    return _transactionList.where((t) => t.type == type).toList();
  }

  /// The full record behind a ledger row.
  ///
  /// [LedgerEntry] is lossy — it drops `category` and `rateToBase` — so editing
  /// an entry has to start from the original transaction, not the row.
  Transaction? findTransaction(String id) {
    try { return _transactionList.firstWhere((t) => t.id == id); }
    catch (_) { return null; }
  }

  // ── READ: Unified ledger (transactions + transfers, newest first) ─────────

  List<LedgerEntry> get allLedgerEntries {
    final entries = <LedgerEntry>[
      ..._transactionList.map(LedgerEntry.fromTransaction),
      ..._transferList.map(LedgerEntry.fromTransfer),
    ];
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  List<LedgerEntry> get recentLedgerEntries =>
      allLedgerEntries.take(5).toList();

  // ── READ: Transfers ───────────────────────────────────────────────────────

  List<Transfer> get transfers => List.unmodifiable(_transferList);

  List<Transfer> transfersForAccount(String accountId) => _transferList
      .where((t) =>
          t.fromAccountId == accountId || t.toAccountId == accountId)
      .toList();

  // ── READ: Debts ───────────────────────────────────────────────────────────

  List<Debt> get debts      => List.unmodifiable(_debtList);
  List<Debt> get iOwe       => _debtList.where((d) => d.type == DebtType.owe  && !d.isPaid).toList();
  List<Debt> get owedToMe   => _debtList.where((d) => d.type == DebtType.owed && !d.isPaid).toList();

  // ── CURRENCY ──────────────────────────────────────────────────────────────

  /// Currency held by [accountId], or the base currency if unknown.
  String currencyOf(String accountId) =>
      findAccount(accountId)?.currency ?? baseCurrency;

  /// Converts [amount] from [currency] into the base currency using the
  /// *current* rate table. Use only for live balances — historical figures
  /// must use the rate snapshotted on the record (`amountInBase`).
  double toBase(double amount, String currency) =>
      amount * _settings.rateFor(currency);

  /// How many units of [to] one unit of [from] buys, derived from the rate
  /// table. Used as a default when the user hasn't entered a rate explicitly.
  double conversionRate(String from, String to) {
    if (from == to) return 1.0;
    final toRate = _settings.rateFor(to);
    if (toRate == 0) return 1.0;
    return _settings.rateFor(from) / toRate;
  }

  /// Live balance of every account, keyed by currency code.
  Map<String, double> get balanceByCurrency {
    final map = <String, double>{};
    for (final a in _accountList.where((a) => a.isActive)) {
      map[a.currency] = (map[a.currency] ?? 0) + accountBalance(a.id);
    }
    return map;
  }

  // ── AGGREGATES ────────────────────────────────────────────────────────────
  //
  // Balances are held in each account's own currency. Totals and reports
  // convert to the base currency: live balances via the current rate table,
  // historical income/expense via each record's stored rate snapshot.

  double get totalBalance => _accountList
      .where((a) => a.isActive && a.type != AccountType.savings)
      .fold(0.0, (s, a) => s + toBase(accountBalance(a.id), a.currency));

  double get totalIncome   => incomeInRange();
  double get totalExpenses => expensesInRange();
  double get totalFees     => feesInRange();

  /// Income earned in the current calendar week (Mon–Sun), in base currency.
  double get weeklyIncome =>
      incomeInRange(from: LedgerPeriod.week.startFrom(DateTime.now()));

  /// Income earned in the current calendar month, in base currency.
  double get monthlyIncome =>
      incomeInRange(from: LedgerPeriod.month.startFrom(DateTime.now()));

  double get balance => totalIncome - totalExpenses;

  bool _inRange(DateTime d, DateTime? from, DateTime? to) =>
      (from == null || !d.isBefore(from)) && (to == null || d.isBefore(to));

  /// Income in base currency between [from] (inclusive) and [to] (exclusive).
  /// Null bounds mean unbounded.
  double incomeInRange({DateTime? from, DateTime? to}) => _transactionList
      .where((t) => t.type == TransactionType.income)
      .where((t) => _inRange(t.date, from, to))
      .fold(0.0, (s, t) => s + t.amountInBase);

  /// Expenses in base currency. Excludes fees — see [feesInRange].
  double expensesInRange({DateTime? from, DateTime? to}) => _transactionList
      .where((t) => t.type == TransactionType.expense)
      .where((t) => _inRange(t.date, from, to))
      .fold(0.0, (s, t) => s + t.amountInBase);

  /// Everything lost to bank and service charges — transfer fees plus fees
  /// attached to expense entries — in base currency.
  double feesInRange({DateTime? from, DateTime? to}) {
    final txFees = _transactionList
        .where((t) => _inRange(t.date, from, to))
        .fold(0.0, (s, t) => s + t.feeInBase);
    final transferFees = _transferList
        .where((t) => _inRange(t.date, from, to))
        .fold(0.0, (s, t) => s + t.feeInBase);
    return txFees + transferFees;
  }

  double incomeIn(LedgerPeriod p) =>
      incomeInRange(from: p.startFrom(DateTime.now()));
  double expensesIn(LedgerPeriod p) =>
      expensesInRange(from: p.startFrom(DateTime.now()));
  double feesIn(LedgerPeriod p) =>
      feesInRange(from: p.startFrom(DateTime.now()));

  /// Balance of one account, in *that account's own currency*.
  double accountBalance(String accountId) =>
      computeAccountBalance(accountId, _transactionList, _transferList);

  /// Returns income and expense totals for each of the last [months] calendar months,
  /// ordered oldest → newest. Values are in base currency.
  List<MonthlySnapshot> lastNMonths(int months) {
    final now = DateTime.now();
    final result = <MonthlySnapshot>[];
    for (int i = months - 1; i >= 0; i--) {
      final target = DateTime(now.year, now.month - i, 1);
      final start = DateTime(target.year, target.month, 1);
      final end   = DateTime(target.year, target.month + 1, 1);
      result.add(MonthlySnapshot(
        month:    start,
        income:   incomeInRange(from: start, to: end),
        expenses: expensesInRange(from: start, to: end),
        fees:     feesInRange(from: start, to: end),
      ));
    }
    return result;
  }

  /// Income/expense buckets sized to [period] — days for a week, weeks for a
  /// month, months for longer spans — so the trend chart always shows a
  /// meaningful number of bars.
  List<TrendBucket> trendFor(LedgerPeriod period) {
    final now = DateTime.now();
    final buckets = <TrendBucket>[];

    void add(String label, DateTime start, DateTime end) {
      buckets.add(TrendBucket(
        label:    label,
        start:    start,
        income:   incomeInRange(from: start, to: end),
        expenses: expensesInRange(from: start, to: end),
        fees:     feesInRange(from: start, to: end),
      ));
    }

    switch (period) {
      case LedgerPeriod.week:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final start  = DateTime(monday.year, monday.month, monday.day);
        const names  = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        for (var i = 0; i < 7; i++) {
          final d = start.add(Duration(days: i));
          add(names[i], d, d.add(const Duration(days: 1)));
        }
      case LedgerPeriod.month:
        final start = DateTime(now.year, now.month, 1);
        final next  = DateTime(now.year, now.month + 1, 1);
        var weekStart = start;
        var w = 1;
        while (weekStart.isBefore(next)) {
          var weekEnd = weekStart.add(const Duration(days: 7));
          if (weekEnd.isAfter(next)) weekEnd = next;
          add('W$w', weekStart, weekEnd);
          weekStart = weekEnd;
          w++;
        }
      case LedgerPeriod.sixMonths:
      case LedgerPeriod.year:
      case LedgerPeriod.all:
        final count = period == LedgerPeriod.sixMonths ? 6 : 12;
        for (var i = count - 1; i >= 0; i--) {
          final target = DateTime(now.year, now.month - i, 1);
          final start  = DateTime(target.year, target.month, 1);
          final end    = DateTime(target.year, target.month + 1, 1);
          add(_monthAbbr(start.month), start, end);
        }
    }
    return buckets;
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static String _monthAbbr(int m) => _months[(m - 1) % 12];

  Map<TransactionCategory, double> get expensesByCategory =>
      expensesByCategoryInRange();

  Map<TransactionCategory, double> expensesByCategoryInRange({
    DateTime? from,
    DateTime? to,
  }) {
    final map = <TransactionCategory, double>{};
    for (final t in _transactionList
        .where((t) => t.type == TransactionType.expense)
        .where((t) => _inRange(t.date, from, to))) {
      map[t.category] = (map[t.category] ?? 0) + t.amountInBase;
    }
    return map;
  }

  /// Running net position over time (income − expenses − fees, cumulative),
  /// oldest → newest, for the balance line chart.
  List<BalancePoint> balanceSeries({DateTime? from, DateTime? to}) {
    final entries = _transactionList
        .where((t) => _inRange(t.date, from, to))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    var running = 0.0;
    return entries.map((t) {
      running += t.type == TransactionType.income
          ? t.amountInBase
          : -(t.amountInBase + t.feeInBase);
      return BalancePoint(date: t.date, value: running);
    }).toList();
  }

  /// Live balance per account in base currency, largest first — for the
  /// account-distribution chart.
  List<AccountShare> get accountDistribution {
    final shares = _accountList
        .where((a) => a.isActive)
        .map((a) => AccountShare(
              account: a,
              native:  accountBalance(a.id),
              inBase:  toBase(accountBalance(a.id), a.currency),
            ))
        .where((s) => s.inBase != 0)
        .toList()
      ..sort((a, b) => b.inBase.compareTo(a.inBase));
    return shares;
  }

  // ── TITHE ─────────────────────────────────────────────────────────────────
  //
  // Obligation is a share of income earned in the period; what has already
  // been given in that same period is subtracted to give what is still owed.

  /// Income × the configured rate, for [period].
  double titheObligation(LedgerPeriod period) =>
      incomeIn(period) * titheRate;

  /// Tithe actually recorded (expense entries categorised as tithe) in [period].
  double titheGiven(LedgerPeriod period) {
    final from = period.startFrom(DateTime.now());
    return computeTitheGiven(_transactionList, from: from);
  }

  TitheStatus titheStatus(LedgerPeriod period) => TitheStatus.of(
        income: incomeIn(period),
        given: titheGiven(period),
        rate: titheRate,
      );

  /// Still owed for [period].
  double titheRemaining(LedgerPeriod period) => titheStatus(period).remaining;

  /// Fraction of the obligation fulfilled, clamped to 0–1.
  double titheProgress(LedgerPeriod period) => titheStatus(period).progress;

  // ── WRITE: Transactions ───────────────────────────────────────────────────

  /// Upsert — re-saving with an existing id edits that entry in place.
  Future<void> addTransaction(Transaction t) =>
      _transactions.doc(t.id).set(t.toMap());

  // ── WRITE: Transfers ──────────────────────────────────────────────────────

  Future<void> addTransfer(Transfer t) =>
      _transfers.doc(t.id).set(t.toMap());

  // There is deliberately no `deleteTransfer`. A transfer is corrected by
  // [reverseTransfer], which records the opposing movement and keeps both
  // halves in the archive. Deleting one would lose that history and, worse,
  // orphan any reversal already pointing at it via `reversalOfId`.

  /// True when some other transfer exists that reverses [id].
  bool isReversed(String id) =>
      _transferList.any((t) => t.reversalOfId == id);

  Transfer? findTransfer(String id) {
    try { return _transferList.firstWhere((t) => t.id == id); }
    catch (_) { return null; }
  }

  /// True when [id] can still be undone.
  bool canReverse(String id) {
    final t = findTransfer(id);
    if (t == null) return false;
    if (t.isReversal) return false;   // don't reverse a reversal
    return !isReversed(id);           // don't reverse twice
  }

  /// Undoes a transfer by recording a *new* transfer in the opposite
  /// direction, so the archive keeps both the original and the correction
  /// rather than silently losing history.
  ///
  /// The fee is normally not returned (the bank keeps it); pass
  /// [refundFee] to give it back too.
  Future<void> reverseTransfer(String id, {bool refundFee = false}) async {
    final original = findTransfer(id);
    if (original == null) {
      throw StateError('Transfer $id no longer exists.');
    }
    if (original.isReversal) {
      throw StateError('A reversal cannot itself be reversed.');
    }
    if (isReversed(id)) {
      throw StateError('This transfer has already been reversed.');
    }

    final reversal = Transfer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      // Swap direction: what arrived goes back out.
      fromAccountId: original.toAccountId,
      toAccountId:   original.fromAccountId,
      amount:        original.toAmount,
      toAmount:      refundFee
          ? original.amount + original.fee
          : original.amount,
      fee:           0.0,
      currency:      original.toCurrency,
      toCurrency:    original.currency,
      rate:          original.rate == 0 ? 1.0 : 1 / original.rate,
      rateToBase:    _settings.rateFor(original.toCurrency),
      category:      original.category,
      date:          DateTime.now(),
      note:          'Reversal of transfer from ${_fmtDate(original.date)}',
      reversalOfId:  original.id,
    );
    await addTransfer(reversal);
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── WRITE: Settings ───────────────────────────────────────────────────────

  Future<void> saveSettings(AppSettings s) =>
      _settingsDoc.set(s.toMap(), SetOptions(merge: true));

  Future<void> setTitheRate(double rate) =>
      saveSettings(_settings.copyWith(titheRate: rate));

  Future<void> setBaseCurrency(String code) =>
      saveSettings(_settings.copyWith(baseCurrency: code));

  /// Records what 1 unit of [code] is worth in the base currency.
  Future<void> setRate(String code, double rateToBase) {
    final next = Map<String, double>.from(_settings.rates)..[code] = rateToBase;
    return saveSettings(_settings.copyWith(rates: next));
  }

  // ── WRITE: Debts ──────────────────────────────────────────────────────────

  /// Upsert — re-saving with an existing id edits that debt in place.
  Future<void> addDebt(Debt d) => _debts.doc(d.id).set(d.toMap());

  Future<void> toggleDebtPaid(String debtId) async {
    final debt = _debtList.firstWhere((d) => d.id == debtId);
    await _debts.doc(debtId).update({'isPaid': !debt.isPaid});
  }

  Future<void> deleteDebt(String id) => _debts.doc(id).delete();

  // ── WRITE: Accounts ───────────────────────────────────────────────────────

  Future<void> addAccount(Account a) =>
      _accounts.doc(a.id).set(a.toMap());

  /// Soft-delete: hides account from home/pickers but preserves its transactions.
  Future<void> deactivateAccount(String id) =>
      _accounts.doc(id).update({'isActive': false});

  /// Restore a previously hidden account.
  Future<void> reactivateAccount(String id) =>
      _accounts.doc(id).update({'isActive': true});

  Future<void> renameAccount(String id, String name) =>
      _accounts.doc(id).update({'name': name});

  /// True once anything has been recorded against [id].
  ///
  /// Amounts are stored in the account's own currency, so changing the
  /// currency after entries exist would silently reinterpret every one of
  /// them — [changeAccountCurrency] refuses in that case.
  bool accountHasActivity(String id) =>
      _transactionList.any((t) => t.accountId == id) ||
      _transferList.any((t) => t.fromAccountId == id || t.toAccountId == id);

  Future<void> changeAccountCurrency(String id, String code) async {
    if (accountHasActivity(id)) {
      throw StateError(
          'This account already has entries recorded in its current currency. '
          'Create a new account instead.');
    }
    await _accounts.doc(id).update({'currency': code});
  }

  // ── READ: Budgets ─────────────────────────────────────────────────────────

  List<Budget> get budgets => List.unmodifiable(_budgetList);

  /// How much has been spent so far in the budget's current period.
  double spentInPeriod(Budget budget) {
    final now = DateTime.now();
    late DateTime periodStart;
    switch (budget.period) {
      case BudgetPeriod.weekly:
        // Start of current week (Monday)
        final daysFromMonday = now.weekday - 1;
        final monday = now.subtract(Duration(days: daysFromMonday));
        periodStart = DateTime(monday.year, monday.month, monday.day);
      case BudgetPeriod.monthly:
        periodStart = DateTime(now.year, now.month, 1);
      case BudgetPeriod.yearly:
        periodStart = DateTime(now.year, 1, 1);
    }
    // Budgets are denominated in the base currency, so normalise each entry.
    return _transactionList
        .where((t) => t.type == TransactionType.expense)
        .where((t) => !t.date.isBefore(periodStart))
        .where((t) => budget.category == null || t.category == budget.category)
        .fold(0.0, (s, t) => s + t.amountInBase + t.feeInBase);
  }

  // ── WRITE: Budgets ────────────────────────────────────────────────────────

  /// Upsert — re-saving with an existing id edits that budget in place.
  Future<void> setBudget(Budget b) => _budgets.doc(b.id).set(b.toMap());

  Future<void> deleteBudget(String id) => _budgets.doc(id).delete();

  // ── WRITE: Delete transaction ─────────────────────────────────────────────

  Future<void> deleteTransaction(String id) => _transactions.doc(id).delete();

  // ── WRITE: Delete all user data (for account deletion) ───────────────────

  Future<void> deleteAllUserData() async {
    final collections = [_accounts, _transactions, _transfers, _debts, _budgets];
    for (final col in collections) {
      final snap = await col.get();
      if (snap.docs.isEmpty) continue;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _db.collection('users').doc(userId).delete();
  }
}

// ── Tithe arithmetic ──────────────────────────────────────────────────────────

/// Sum of tithe already recorded, in base currency.
///
/// Only expense entries categorised as tithe count — recording the giving is
/// what makes it count against the obligation.
double computeTitheGiven(
  Iterable<Transaction> transactions, {
  DateTime? from,
  DateTime? to,
}) =>
    transactions
        .where((t) => t.type == TransactionType.expense)
        .where((t) => t.category == TransactionCategory.tithe)
        .where((t) =>
            (from == null || !t.date.isBefore(from)) &&
            (to == null || t.date.isBefore(to)))
        .fold(0.0, (s, t) => s + t.amountInBase);

/// What is owed, what has been given, and how far along that leaves you.
class TitheStatus {
  final double obligation;
  final double given;
  final double remaining;
  final double progress; // 0.0 – 1.0

  const TitheStatus._({
    required this.obligation,
    required this.given,
    required this.remaining,
    required this.progress,
  });

  factory TitheStatus.of({
    required double income,
    required double given,
    required double rate,
  }) {
    // Negative income (net of nothing) or a nonsense rate must not produce a
    // negative obligation.
    final obligation = income > 0 ? income * rate : 0.0;
    final rawRemaining = obligation - given;
    return TitheStatus._(
      obligation: obligation,
      given: given,
      // Giving extra does not bank a credit against future obligations.
      remaining: rawRemaining > 0 ? rawRemaining : 0.0,
      // Nothing owed counts as fulfilled, not as 0% done.
      progress:
          obligation <= 0 ? 1.0 : (given / obligation).clamp(0.0, 1.0),
    );
  }
}

// ── Balance arithmetic ────────────────────────────────────────────────────────

/// Balance of [accountId] in that account's own currency.
///
/// Kept as a pure function, separate from Firestore, so the arithmetic that
/// decides how much money a user has can be tested directly.
///
/// Sign conventions:
///  - income adds its amount
///  - an expense subtracts its amount *and* its fee
///  - an incoming transfer adds [Transfer.toAmount] (destination currency)
///  - an outgoing transfer subtracts amount *and* fee (source currency)
double computeAccountBalance(
  String accountId,
  Iterable<Transaction> transactions,
  Iterable<Transfer> transfers,
) {
  final fromTx = transactions.where((t) => t.accountId == accountId).fold<double>(
      0.0,
      (s, t) => s +
          (t.type == TransactionType.income
              ? t.amount
              : -(t.amount + t.fee)));

  final transfersIn = transfers
      .where((t) => t.toAccountId == accountId)
      .fold<double>(0.0, (s, t) => s + t.toAmount);

  final transfersOut = transfers
      .where((t) => t.fromAccountId == accountId)
      .fold<double>(0.0, (s, t) => s + t.amount + t.fee);

  return fromTx + transfersIn - transfersOut;
}

// ── Savings aggregate ─────────────────────────────────────────────────────────

/// What the vaults hold, in a form the UI can present honestly.
///
/// When every vault holds the same currency the figure is exact and stays in
/// that currency. Across currencies it has to be converted, and [converted]
/// says so — the screens render it with a `≈` and name the estimate rather
/// than passing a converted sum off as a precise one.
class SavingsSummary {
  /// The vaults behind the figure, in account order.
  final List<Account> accounts;
  final double amount;
  final String currency;

  /// True when [amount] is a cross-currency conversion rather than a plain sum.
  final bool converted;

  const SavingsSummary({
    required this.accounts,
    required this.amount,
    required this.currency,
    required this.converted,
  });

  bool get isEmpty => accounts.isEmpty;
}

/// Totals the vaults.
///
/// Deliberately uses the *current* rate table via [rateToBase], not each
/// record's stored snapshot: this is a live balance, and it has to reconcile
/// against [computeAccountBalance] and `totalBalance`, which work the same way.
/// Rate snapshots are for historical flows (income, expenses, fees), where
/// re-converting at today's rate would rewrite last month's reports.
///
/// Kept pure and separate from Firestore so it can be tested directly.
SavingsSummary computeSavingsSummary(
  List<Account> savings,
  double Function(String accountId) balanceOf,
  double Function(String code) rateToBase,
  String baseCurrency,
) {
  if (savings.isEmpty) {
    return SavingsSummary(
      accounts: const [],
      amount: 0.0,
      currency: baseCurrency,
      converted: false,
    );
  }

  final currencies = savings.map((a) => a.currency).toSet();
  if (currencies.length == 1) {
    return SavingsSummary(
      accounts: savings,
      amount: savings.fold(0.0, (s, a) => s + balanceOf(a.id)),
      currency: currencies.first,
      converted: false,
    );
  }

  return SavingsSummary(
    accounts: savings,
    amount: savings.fold(
        0.0, (s, a) => s + balanceOf(a.id) * rateToBase(a.currency)),
    currency: baseCurrency,
    converted: true,
  );
}

// ── Unified ledger entry (transaction OR transfer) ────────────────────────────

enum LedgerEntryKind { income, expense, transfer }

class LedgerEntry {
  final String id;
  final String title;
  final double amount;
  final double fee;
  final LedgerEntryKind kind;
  final DateTime date;
  final String? accountId;       // for transactions
  final String? fromAccountId;   // for transfers
  final String? toAccountId;     // for transfers
  final String? note;

  /// Currency the amount is denominated in.
  final String currency;

  /// Amount arriving at the destination (transfers only); differs from
  /// [amount] on cross-currency transfers.
  final double toAmount;
  final String toCurrency;

  /// Set when this entry undoes another transfer.
  final String? reversalOfId;

  /// Transfer purpose, null for transactions.
  final TransferCategory? transferCategory;

  const LedgerEntry._({
    required this.id,
    required this.title,
    required this.amount,
    required this.fee,
    required this.kind,
    required this.date,
    required this.currency,
    double? toAmount,
    String? toCurrency,
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    this.note,
    this.reversalOfId,
    this.transferCategory,
  })  : toAmount   = toAmount   ?? amount,
        toCurrency = toCurrency ?? currency;

  bool get isReversal => reversalOfId != null;
  bool get isCrossCurrency => currency != toCurrency;

  factory LedgerEntry.fromTransaction(Transaction t) => LedgerEntry._(
        id:        t.id,
        title:     t.title,
        amount:    t.amount,
        fee:       t.fee,
        kind:      t.type == TransactionType.income
            ? LedgerEntryKind.income
            : LedgerEntryKind.expense,
        date:      t.date,
        currency:  t.currency,
        accountId: t.accountId,
        note:      t.note,
      );

  factory LedgerEntry.fromTransfer(Transfer t) => LedgerEntry._(
        id:            t.id,
        title:         t.isReversal ? 'Reversal' : 'Transfer',
        amount:        t.amount,
        fee:           t.fee,
        kind:          LedgerEntryKind.transfer,
        date:          t.date,
        currency:      t.currency,
        toAmount:      t.toAmount,
        toCurrency:    t.toCurrency,
        fromAccountId: t.fromAccountId,
        toAccountId:   t.toAccountId,
        note:          t.note,
        reversalOfId:  t.reversalOfId,
        transferCategory: t.category,
      );
}

/// Simple data class for monthly income/expense breakdown, in base currency.
class MonthlySnapshot {
  final DateTime month;
  final double income;
  final double expenses;
  final double fees;
  const MonthlySnapshot({
    required this.month,
    required this.income,
    required this.expenses,
    this.fees = 0.0,
  });

  double get net => income - expenses - fees;
}

/// One bar on the income/expense trend chart, in base currency.
class TrendBucket {
  final String label;
  final DateTime start;
  final double income;
  final double expenses;
  final double fees;
  const TrendBucket({
    required this.label,
    required this.start,
    required this.income,
    required this.expenses,
    required this.fees,
  });
}

/// One point on the cumulative balance line, in base currency.
class BalancePoint {
  final DateTime date;
  final double value;
  const BalancePoint({required this.date, required this.value});
}

/// An account's share of total holdings, for the distribution chart.
class AccountShare {
  final Account account;
  /// Balance in the account's own currency.
  final double native;
  /// The same balance converted to the base currency.
  final double inBase;
  const AccountShare({
    required this.account,
    required this.native,
    required this.inBase,
  });
}

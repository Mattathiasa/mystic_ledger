import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_model.dart';
import '../models/transaction.dart';
import '../models/transfer_model.dart';
import '../models/debt_model.dart';
import '../models/budget_model.dart';

/// Central store for all financial data.
/// Subscribes to Firestore real-time streams for the authenticated user.
/// Exposes the same API as before — all existing screens work unchanged.
class FinanceService extends ChangeNotifier {
  // ── Well-known account IDs ────────────────────────────────────────────────
  static const String idTelebirr = 'telebirr';
  static const String idCash     = 'cash';
  static const String idCBE      = 'cbe';
  static const String idSavings  = 'savings';

  // ── Firestore references ──────────────────────────────────────────────────
  final String userId;
  final _db = FirebaseFirestore.instance;

  CollectionReference get _accounts     => _db.collection('users/$userId/accounts');
  CollectionReference get _transactions => _db.collection('users/$userId/transactions');
  CollectionReference get _transfers    => _db.collection('users/$userId/transfers');
  CollectionReference get _debts        => _db.collection('users/$userId/debts');
  CollectionReference get _budgets      => _db.collection('users/$userId/budgets');

  // ── Local caches (updated by Firestore stream listeners) ──────────────────
  List<Account>     _accountList     = [];
  List<Transaction> _transactionList = [];
  List<Transfer>    _transferList    = [];
  List<Debt>        _debtList        = [];
  List<Budget>      _budgetList      = [];
  bool _isLoading = true;
  bool _balanceHidden = false;

  bool get isLoading => _isLoading;
  bool get balanceHidden => _balanceHidden;

  final List<StreamSubscription> _subs = [];

  // ── Constructor ───────────────────────────────────────────────────────────

  FinanceService(this.userId) {
    _loadPrefs();
    _subscribe();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _balanceHidden = prefs.getBool('balance_hidden') ?? false;
    notifyListeners();
  }

  Future<void> toggleBalanceVisibility() async {
    _balanceHidden = !_balanceHidden;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('balance_hidden', _balanceHidden);
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
  }

  int _loadedCount = 0;
  void _checkLoaded() {
    _loadedCount++;
    if (_loadedCount >= 5) _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
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

  // ── AGGREGATES ────────────────────────────────────────────────────────────

  double get totalBalance => _accountList
      .where((a) => a.type != AccountType.savings)
      .fold(0.0, (sum, a) => sum + accountBalance(a.id));

  double get totalIncome => _transactionList
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpenses => _transactionList
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  /// Income earned in the current calendar week (Mon–Sun).
  double get weeklyIncome {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    return _transactionList
        .where((t) => t.type == TransactionType.income)
        .where((t) => !t.date.isBefore(weekStart))
        .fold(0.0, (s, t) => s + t.amount);
  }

  /// Income earned in the current calendar month.
  double get monthlyIncome {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _transactionList
        .where((t) => t.type == TransactionType.income)
        .where((t) => !t.date.isBefore(monthStart))
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get balance   => totalIncome - totalExpenses;
  double get tithe     => totalIncome * 0.1;
  double get totalSavings => accountBalance(idSavings);

  double accountBalance(String accountId) {
    final fromTx = _transactionList
        .where((t) => t.accountId == accountId)
        .fold<double>(0.0,
            (s, t) => s + (t.type == TransactionType.income ? t.amount : -t.amount));

    final transfersIn  = _transferList
        .where((t) => t.toAccountId   == accountId)
        .fold<double>(0.0, (s, t) => s + t.amount);

    final transfersOut = _transferList
        .where((t) => t.fromAccountId == accountId)
        .fold<double>(0.0, (s, t) => s + t.amount + t.fee);

    return fromTx + transfersIn - transfersOut;
  }

  /// Returns income and expense totals for each of the last [months] calendar months,
  /// ordered oldest → newest.
  List<MonthlySnapshot> lastNMonths(int months) {
    final now = DateTime.now();
    final result = <MonthlySnapshot>[];
    for (int i = months - 1; i >= 0; i--) {
      final target = DateTime(now.year, now.month - i, 1);
      final start = DateTime(target.year, target.month, 1);
      final end   = DateTime(target.year, target.month + 1, 1);
      final inRange = _transactionList.where(
        (t) => !t.date.isBefore(start) && t.date.isBefore(end));
      final income   = inRange.where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final expenses = inRange.where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      result.add(MonthlySnapshot(month: start, income: income, expenses: expenses));
    }
    return result;
  }

  Map<TransactionCategory, double> get expensesByCategory {
    final map = <TransactionCategory, double>{};
    for (final t in _transactionList.where((t) => t.type == TransactionType.expense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  // ── WRITE: Transactions ───────────────────────────────────────────────────

  Future<void> addTransaction(Transaction t) =>
      _transactions.doc(t.id).set(t.toMap());

  // ── WRITE: Transfers ──────────────────────────────────────────────────────

  Future<void> addTransfer(Transfer t) =>
      _transfers.doc(t.id).set(t.toMap());

  // ── WRITE: Debts ──────────────────────────────────────────────────────────

  Future<void> addDebt(Debt d) => _debts.doc(d.id).set(d.toMap());

  Future<void> toggleDebtPaid(String debtId) async {
    final debt = _debtList.firstWhere((d) => d.id == debtId);
    await _debts.doc(debtId).update({'isPaid': !debt.isPaid});
  }

  // ── WRITE: Accounts ───────────────────────────────────────────────────────

  Future<void> addAccount(Account a) =>
      _accounts.doc(a.id).set(a.toMap());

  /// Soft-delete: hides account from home/pickers but preserves its transactions.
  Future<void> deactivateAccount(String id) =>
      _accounts.doc(id).update({'isActive': false});

  /// Restore a previously hidden account.
  Future<void> reactivateAccount(String id) =>
      _accounts.doc(id).update({'isActive': true});

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
    return _transactionList
        .where((t) => t.type == TransactionType.expense)
        .where((t) => !t.date.isBefore(periodStart))
        .where((t) => budget.category == null || t.category == budget.category)
        .fold(0.0, (s, t) => s + t.amount);
  }

  // ── WRITE: Budgets ────────────────────────────────────────────────────────

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

  const LedgerEntry._({
    required this.id,
    required this.title,
    required this.amount,
    required this.fee,
    required this.kind,
    required this.date,
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    this.note,
  });

  factory LedgerEntry.fromTransaction(Transaction t) => LedgerEntry._(
        id:        t.id,
        title:     t.title,
        amount:    t.amount,
        fee:       0,
        kind:      t.type == TransactionType.income
            ? LedgerEntryKind.income
            : LedgerEntryKind.expense,
        date:      t.date,
        accountId: t.accountId,
        note:      t.note,
      );

  factory LedgerEntry.fromTransfer(Transfer t) => LedgerEntry._(
        id:            t.id,
        title:         'Transfer',
        amount:        t.amount,
        fee:           t.fee,
        kind:          LedgerEntryKind.transfer,
        date:          t.date,
        fromAccountId: t.fromAccountId,
        toAccountId:   t.toAccountId,
        note:          t.note,
      );
}

/// Simple data class for monthly income/expense breakdown.
class MonthlySnapshot {
  final DateTime month;
  final double income;
  final double expenses;
  const MonthlySnapshot({
    required this.month,
    required this.income,
    required this.expenses,
  });
}

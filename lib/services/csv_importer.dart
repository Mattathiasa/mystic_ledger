import 'dart:convert';
import 'package:csv/csv.dart';

import '../models/budget_model.dart';
import '../models/currency_model.dart';
import '../models/debt_model.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../models/transfer_model.dart';

/// What a parsed CSV produced, ready to be written into the ledger.
class CsvImportResult {
  final List<Transaction> transactions;
  final List<Transfer> transfers;
  final List<Debt> debts;
  final List<Budget> budgets;
  final List<RecurringTransaction> recurring;

  /// Rows that could not be mapped (unknown account, unparsable value).
  final List<String> skipped;

  int get total => transactions.length +
      transfers.length +
      debts.length +
      budgets.length +
      recurring.length;

  const CsvImportResult({
    required this.transactions,
    required this.transfers,
    required this.debts,
    required this.budgets,
    required this.recurring,
    required this.skipped,
  });
}

/// Parses the CSV produced by [DataExporter] (and tolerates bare transaction
/// tables from other apps).
///
/// Imported records always get fresh ids, so importing is a *merge* — the
/// archive never silently overwrites existing entries. Account columns are
/// matched by name against the user's accounts; rows referencing unknown
/// accounts are reported as skipped.
class CsvImporter {
  CsvImporter._();

  static CsvImportResult parse(
      String csv, Map<String, String> accountNameToId) {
    // Normalise line endings so files written on any platform parse the same.
    csv = csv.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final transactions = <Transaction>[];
    final transfers = <Transfer>[];
    final debts = <Debt>[];
    final budgets = <Budget>[];
    final recurring = <RecurringTransaction>[];
    final skipped = <String>[];

    // The exporter writes sections separated by a blank line, each starting
    // with a "TRANSACTIONS"-style marker.
    final parts = csv
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    for (final part in parts) {
      final lines = const LineSplitter().convert(part);
      final marker = lines.first.trim().toUpperCase();
      final isMarker = const {
        'TRANSACTIONS',
        'TRANSFERS',
        'DEBTS',
        'BUDGETS',
        'RECURRING',
      }.contains(marker);

      final body = isMarker ? lines.skip(1).join('\n') : part;
      if (body.trim().isEmpty) continue;

      // eol must be explicit: csv 6.x defaults to \r\n, which would collapse
      // a whole section into one row.
      final rows = const CsvToListConverter(eol: '\n').convert(body);
      if (rows.isEmpty) continue;

      // Skip a blank trailer row if the file ends with one.
      if (rows.length == 1 && (rows.first).join('').trim().isEmpty) continue;

      final header = rows.first.map((c) => c.toString().trim()).toList();
      int idx(String name) => header.indexOf(name);

      try {
        final data = rows.skip(1);
        if (!isMarker || marker == 'TRANSACTIONS') {
          _parseTransactions(
              data, idx, accountNameToId, transactions, skipped);
        } else if (marker == 'TRANSFERS') {
          _parseTransfers(data, idx, accountNameToId, transfers, skipped);
        } else if (marker == 'DEBTS') {
          _parseDebts(data, idx, debts, skipped);
        } else if (marker == 'BUDGETS') {
          _parseBudgets(data, idx, budgets, skipped);
        } else if (marker == 'RECURRING') {
          _parseRecurring(data, idx, accountNameToId, recurring, skipped);
        }
      } catch (_) {
        skipped.add('$marker section');
      }
    }

    return CsvImportResult(
      transactions: transactions,
      transfers: transfers,
      debts: debts,
      budgets: budgets,
      recurring: recurring,
      skipped: skipped,
    );
  }

  static void _parseTransactions(
    Iterable<List<dynamic>> rows,
    int Function(String) idx,
    Map<String, String> accountNameToId,
    List<Transaction> out,
    List<String> skipped,
  ) {
    for (final row in rows) {
      String v(String name) => _at(row, idx(name));
      final accountName = v('account');
      final accountId = accountNameToId[accountName];
      final amount = double.tryParse(v('amount'));
      final date = DateTime.tryParse(v('date'));
      final title = v('title');
      if (amount == null || date == null || accountId == null) {
        skipped.add(title.isEmpty ? 'transaction row' : title);
        continue;
      }
      out.add(Transaction(
        id: '${DateTime.now().microsecondsSinceEpoch.toString()}-${out.length}',
        title: title,
        amount: amount,
        type: v('type').toLowerCase() == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        accountId: accountId,
        category: _category(v('category')),
        date: date,
        note: v('note').isEmpty ? null : v('note'),
        currency: v('currency').isEmpty ? Currency.defaultCode : v('currency'),
        fee: double.tryParse(v('fee')) ?? 0.0,
        rateToBase: double.tryParse(v('rateToBase')) ?? 1.0,
        tags: _decodeTags(v('tags')),
        splits: _decodeSplits(v('splits')),
      ));
    }
  }

  /// `tags`/`splits` are JSON-encoded by the exporter; a missing, empty or
  /// corrupt cell degrades to the pre-feature defaults rather than skipping
  /// the whole row.
  static List<String> _decodeTags(String raw) {
    if (raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  static List<TransactionSplit> _decodeSplits(String raw) {
    if (raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => TransactionSplit.fromMap(
              (e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static void _parseTransfers(
    Iterable<List<dynamic>> rows,
    int Function(String) idx,
    Map<String, String> accountNameToId,
    List<Transfer> out,
    List<String> skipped,
  ) {
    for (final row in rows) {
      String v(String name) => _at(row, idx(name));
      final from = accountNameToId[v('fromAccount')];
      final to = accountNameToId[v('toAccount')];
      final amount = double.tryParse(v('amount'));
      final date = DateTime.tryParse(v('date'));
      if (from == null || to == null || amount == null || date == null) {
        skipped.add('${v('fromAccount')} → ${v('toAccount')}');
        continue;
      }
      out.add(Transfer(
        id: '${DateTime.now().microsecondsSinceEpoch.toString()}-${out.length}',
        fromAccountId: from,
        toAccountId: to,
        amount: amount,
        toAmount: double.tryParse(v('toAmount')) ?? amount,
        fee: double.tryParse(v('fee')) ?? 0.0,
        currency: v('currency').isEmpty ? Currency.defaultCode : v('currency'),
        toCurrency: v('toCurrency').isEmpty
            ? Currency.defaultCode
            : v('toCurrency'),
        rate: double.tryParse(v('rate')) ?? 1.0,
        category: _transferCategory(v('category')),
        date: date,
        note: v('note').isEmpty ? null : v('note'),
        // reversalOfId is dropped: fresh ids break the reference anyway.
      ));
    }
  }

  static void _parseDebts(
    Iterable<List<dynamic>> rows,
    int Function(String) idx,
    List<Debt> out,
    List<String> skipped,
  ) {
    for (final row in rows) {
      String v(String name) => _at(row, idx(name));
      final amount = double.tryParse(v('amount'));
      final date = DateTime.tryParse(v('date'));
      final name = v('name');
      if (amount == null || date == null) {
        skipped.add(name.isEmpty ? 'debt row' : name);
        continue;
      }
      out.add(Debt(
        id: '${DateTime.now().microsecondsSinceEpoch.toString()}-${out.length}',
        name: name,
        amount: amount,
        type: v('type').toLowerCase() == 'owed'
            ? DebtType.owed
            : DebtType.owe,
        date: date,
        dueDate: v('dueDate').isEmpty ? null : DateTime.tryParse(v('dueDate')),
        note: v('note').isEmpty ? null : v('note'),
        isPaid: v('isPaid').toLowerCase() == 'true',
      ));
    }
  }

  static void _parseBudgets(
    Iterable<List<dynamic>> rows,
    int Function(String) idx,
    List<Budget> out,
    List<String> skipped,
  ) {
    for (final row in rows) {
      String v(String name) => _at(row, idx(name));
      final amount = double.tryParse(v('amount'));
      if (amount == null) {
        skipped.add('budget row');
        continue;
      }
      final category = v('category').isEmpty
          ? null
          : _category(v('category'));
      out.add(Budget(
        id: '${DateTime.now().microsecondsSinceEpoch.toString()}-${out.length}',
        period: BudgetPeriod.values
            .asNameMap()[v('period').toLowerCase()] ??
            BudgetPeriod.monthly,
        amount: amount,
        category: category,
      ));
    }
  }

  static void _parseRecurring(
    Iterable<List<dynamic>> rows,
    int Function(String) idx,
    Map<String, String> accountNameToId,
    List<RecurringTransaction> out,
    List<String> skipped,
  ) {
    for (final row in rows) {
      String v(String name) => _at(row, idx(name));
      final accountId = accountNameToId[v('account')];
      final amount = double.tryParse(v('amount'));
      final nextDue = DateTime.tryParse(v('nextDue'));
      final title = v('title');
      if (amount == null || nextDue == null || accountId == null) {
        skipped.add(title.isEmpty ? 'recurring row' : title);
        continue;
      }
      out.add(RecurringTransaction(
        id: '${DateTime.now().microsecondsSinceEpoch.toString()}-${out.length}',
        title: title,
        amount: amount,
        type: v('type').toLowerCase() == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        category: _category(v('category')),
        accountId: accountId,
        currency: v('currency').isEmpty ? Currency.defaultCode : v('currency'),
        frequency: RecurrenceFrequency.values
                .asNameMap()[v('frequency').toLowerCase()] ??
            RecurrenceFrequency.monthly,
        nextDue: nextDue,
        note: v('note').isEmpty ? null : v('note'),
        isActive: v('isActive').toLowerCase() != 'false',
      ));
    }
  }

  static TransactionCategory _category(String name) =>
      TransactionCategory.values.asNameMap()[name.toLowerCase()] ??
      TransactionCategory.other;

  static TransferCategory? _transferCategory(String name) =>
      name.isEmpty ? null : TransferCategory.values.asNameMap()[name.toLowerCase()];

  static String _at(List<dynamic> row, int i) =>
      (i >= 0 && i < row.length) ? row[i].toString().trim() : '';
}

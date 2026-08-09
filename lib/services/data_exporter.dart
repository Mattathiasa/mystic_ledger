import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../models/transfer_model.dart';
import '../models/debt_model.dart';
import '../models/budget_model.dart';
import '../models/recurring_transaction.dart';
import 'finance_service.dart';

/// Exports the user's data to a CSV file and shares it (share sheet on
/// Android/iOS, download on the web).
///
/// One file per kind of record — transactions, transfers, debts, budgets —
/// so the shapes stay honest and importing anywhere is straightforward.
class DataExporter {
  DataExporter._();

  static String _escape(String? v) {
    if (v == null) return '';
    return v.replaceAll('"', '""');
  }

  static List<List<String>> _transactionsRows(
      List<Transaction> transactions, Map<String, String> accountNames) {
    final rows = <List<String>>[
      ['id', 'title', 'type', 'category', 'amount', 'currency', 'fee', 'account',
       'date', 'note', 'rateToBase', 'tags', 'splits'],
    ];
    for (final t in transactions) {
      rows.add([
        _escape(t.id),
        _escape(t.title),
        t.type.name,
        t.category.name,
        t.amount.toStringAsFixed(2),
        t.currency,
        t.fee.toStringAsFixed(2),
        _escape(accountNames[t.accountId] ?? t.accountId),
        t.date.toIso8601String(),
        _escape(t.note),
        t.rateToBase.toString(),
        // JSON-encoded so any character a tag or note may hold survives the
        // round-trip; the CSV layer handles quoting.
        jsonEncode(t.tags),
        jsonEncode(t.splits.map((s) => s.toMap()).toList()),
      ]);
    }
    return rows;
  }

  static List<List<String>> _transfersRows(
      List<Transfer> transfers, Map<String, String> accountNames) {
    final rows = <List<String>>[
      ['id', 'fromAccount', 'toAccount', 'amount', 'currency', 'toAmount',
       'toCurrency', 'fee', 'rate', 'category', 'date', 'note', 'reversalOfId'],
    ];
    for (final t in transfers) {
      rows.add([
        _escape(t.id),
        _escape(accountNames[t.fromAccountId] ?? t.fromAccountId),
        _escape(accountNames[t.toAccountId] ?? t.toAccountId),
        t.amount.toStringAsFixed(2),
        t.currency,
        t.toAmount.toStringAsFixed(2),
        t.toCurrency,
        t.fee.toStringAsFixed(2),
        t.rate.toString(),
        t.category?.name ?? '',
        t.date.toIso8601String(),
        _escape(t.note),
        _escape(t.reversalOfId),
      ]);
    }
    return rows;
  }

  static List<List<String>> _debtsRows(List<Debt> debts) {
    final rows = <List<String>>[
      ['id', 'name', 'amount', 'type', 'date', 'dueDate', 'note', 'isPaid'],
    ];
    for (final d in debts) {
      rows.add([
        _escape(d.id),
        _escape(d.name),
        d.amount.toStringAsFixed(2),
        d.type.name,
        d.date.toIso8601String(),
        d.dueDate?.toIso8601String() ?? '',
        _escape(d.note),
        d.isPaid.toString(),
      ]);
    }
    return rows;
  }

  static List<List<String>> _budgetsRows(List<Budget> budgets) {
    final rows = <List<String>>[
      ['id', 'period', 'amount', 'category'],
    ];
    for (final b in budgets) {
      rows.add([
        _escape(b.id),
        b.period.name,
        b.amount.toStringAsFixed(2),
        b.category?.name ?? 'overall',
      ]);
    }
    return rows;
  }

  static List<List<String>> _recurringRows(
      List<RecurringTransaction> recurring, Map<String, String> accountNames) {
    final rows = <List<String>>[
      ['id', 'title', 'amount', 'type', 'category', 'account', 'currency',
       'frequency', 'nextDue', 'note', 'isActive'],
    ];
    for (final r in recurring) {
      rows.add([
        _escape(r.id),
        _escape(r.title),
        r.amount.toStringAsFixed(2),
        r.type.name,
        r.category.name,
        _escape(accountNames[r.accountId] ?? r.accountId),
        r.currency,
        r.frequency.name,
        r.nextDue.toIso8601String(),
        _escape(r.note),
        r.isActive.toString(),
      ]);
    }
    return rows;
  }

  /// Builds one CSV document containing all sections, each with its own
  /// header. Returns the CSV as a string.
  static String buildCsv(FinanceService svc) {
    final accountNames = {
      for (final a in svc.allAccounts) a.id: a.name,
    };

    final sections = <String>[
      'TRANSACTIONS\n${_encode(_transactionsRows(svc.transactions, accountNames))}',
      'TRANSFERS\n${_encode(_transfersRows(svc.transfers, accountNames))}',
      'DEBTS\n${_encode(_debtsRows(svc.debts))}',
      'BUDGETS\n${_encode(_budgetsRows(svc.budgets))}',
      'RECURRING\n${_encode(_recurringRows(svc.recurring, accountNames))}',
    ];

    return sections.join('\n\n');
  }

  // eol must be explicit: csv 6.x defaults to \r\n, and the importer
  // normalises to \n — keeping exports on the same line endings avoids
  // surprises in spreadsheets and editors.
  static String _encode(List<List<String>> rows) =>
      const ListToCsvConverter(eol: '\n').convert(rows);

  /// Shares the exported CSV. On the web, `Share.shareXFiles` with a byte
  /// source falls back to a browser download; on mobile the share sheet
  /// presents the same byte-backed file.
  static Future<bool> share(FinanceService svc) async {
    final csv = buildCsv(svc);
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;

    final file = XFile.fromData(utf8.encode(csv),
        mimeType: 'text/csv', name: 'mystic_ledger_$stamp.csv');
    final result = await Share.shareXFiles([file], subject: 'Mystic Ledger export');
    return result.status != ShareResultStatus.dismissed;
  }
}

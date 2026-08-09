import 'package:flutter_test/flutter_test.dart';
import 'package:mystic_ledger/models/recurring_transaction.dart';
import 'package:mystic_ledger/models/transaction.dart';
import 'package:mystic_ledger/services/csv_importer.dart';

void main() {
  final accountMap = {'CBE': 'acc-cbe', 'Telebirr': 'acc-tel'};

  final csv = [
    'TRANSACTIONS',
    'id,title,type,category,amount,currency,fee,account,date,note,rateToBase',
    't1,Coffee,expense,food,80.00,ETB,0.00,CBE,2026-08-01T09:00:00.000,Morning brew,1.0',
    't2,Salary,income,salary,10000.00,ETB,0.00,CBE,2026-08-01T08:00:00.000,,1.0',
    '',
    'TRANSFERS',
    'id,fromAccount,toAccount,amount,currency,toAmount,toCurrency,fee,rate,category,date,note,reversalOfId',
    'x1,CBE,Telebirr,500.00,ETB,500.00,ETB,2.50,1.0,savings,2026-08-02T10:00:00.000,Moved,',
  ].join('\n');

  test('parses transactions and transfers with account resolution', () {
    final result = CsvImporter.parse(csv, accountMap);
    expect(result.transactions.length, 2);
    expect(result.transfers.length, 1);
    expect(result.debts, isEmpty);
    expect(result.budgets, isEmpty);
    expect(result.skipped, isEmpty);
    expect(result.total, 3);

    final coffee = result.transactions.first;
    expect(coffee.title, 'Coffee');
    expect(coffee.type, TransactionType.expense);
    expect(coffee.category, TransactionCategory.food);
    expect(coffee.amount, 80.0);
    expect(coffee.accountId, 'acc-cbe');
    expect(coffee.note, 'Morning brew');

    final salary = result.transactions[1];
    expect(salary.type, TransactionType.income);
    expect(salary.note, isNull);

    final move = result.transfers.single;
    expect(move.fromAccountId, 'acc-cbe');
    expect(move.toAccountId, 'acc-tel');
    expect(move.amount, 500.0);
    expect(move.fee, 2.5);
  });

  test('rows referencing unknown accounts are skipped', () {
    final withUnknown = '$csv'
        '\n\nTRANSACTIONS\n'
        'id,title,type,category,amount,currency,fee,account,date,note,rateToBase\n'
        't9,Mystery,expense,other,10.00,ETB,0.00,NoSuchAccount,2026-08-03T09:00:00.000,,1.0';
    final result = CsvImporter.parse(withUnknown, accountMap);
    expect(result.transactions.length, 2);
    expect(result.skipped, isNotEmpty);
  });

  test('imported records always get fresh ids', () {
    final result = CsvImporter.parse(csv, accountMap);
    final ids = result.transactions.map((t) => t.id).toSet();
    expect(ids.length, 2);
    for (final t in result.transactions) {
      expect(t.id, isNot('t1'));
      expect(t.id, isNot('t2'));
    }
  });

  test('tolerates a bare transactions table without section markers', () {
    final bare = [
      'id,title,type,category,amount,currency,fee,account,date,note,rateToBase',
      't3,Rent,expense,rent,3000.00,ETB,0.00,CBE,2026-08-05T00:00:00.000,,1.0',
    ].join('\n');
    final result = CsvImporter.parse(bare, accountMap);
    expect(result.transactions.length, 1);
    expect(result.transactions.single.category, TransactionCategory.rent);
  });

  test('round-trips tags and splits from the exporter format', () {
    final withMeta = [
      'TRANSACTIONS',
      'id,title,type,category,amount,currency,fee,account,date,note,rateToBase,tags,splits',
      // JSON cells are RFC-4180 quoted exactly as the exporter emits them.
      // tags JSON: ["vacation","reimbursable"] ; splits: two line items.
      't5,Grocery,expense,food,1200.00,ETB,0.00,CBE,2026-08-06T09:00:00.000,Weekly shop,1.0,'
          '"[""vacation"",""reimbursable""]",'
          '"[{""category"":""food"",""amount"":800.0,""note"":null},'
          '{""category"":""transport"",""amount"":400.0,""note"":""taxi""}]"',
    ].join('\n');

    final result = CsvImporter.parse(withMeta, accountMap);
    final tx = result.transactions.single;
    expect(tx.tags, ['vacation', 'reimbursable']);
    expect(tx.isSplit, isTrue);
    expect(tx.splits.length, 2);
    expect(tx.splits.first.category, TransactionCategory.food);
    expect(tx.splits.first.amount, 800.0);
    expect(tx.splits[1].note, 'taxi');
  });

  test('missing or corrupt tags/splits degrade to empty, not a skipped row', () {
    final corrupt = [
      'TRANSACTIONS',
      'id,title,type,category,amount,currency,fee,account,date,note,rateToBase,tags,splits',
      't6,Broken,expense,food,50.00,ETB,0.00,CBE,2026-08-06T10:00:00.000,,1.0,not-json,[oops',
    ].join('\n');
    final result = CsvImporter.parse(corrupt, accountMap);
    expect(result.skipped, isEmpty);
    expect(result.transactions.single.tags, isEmpty);
    expect(result.transactions.single.splits, isEmpty);
  });

  test('parses a RECURRING section with account resolution', () {
    final withRecurring = [
      'RECURRING',
      'id,title,amount,type,category,account,currency,frequency,nextDue,note,isActive',
      'r1,Rent,15000.00,expense,rent,CBE,ETB,monthly,2026-09-01T00:00:00.000,Flat,true',
      'r2,Salary,80000.00,income,salary,Telebirr,ETB,monthly,2026-09-01T00:00:00.000,,false',
    ].join('\n');

    final result = CsvImporter.parse(withRecurring, accountMap);
    expect(result.recurring.length, 2);
    final rent = result.recurring.first;
    expect(rent.title, 'Rent');
    expect(rent.type, TransactionType.expense);
    expect(rent.accountId, 'acc-cbe');
    expect(rent.frequency, RecurrenceFrequency.monthly);
    expect(rent.isActive, isTrue);
    expect(rent.note, 'Flat');

    final salary = result.recurring[1];
    expect(salary.type, TransactionType.income);
    expect(salary.accountId, 'acc-tel');
    expect(salary.isActive, isFalse);
    expect(result.total, 2);
  });

  test('recurring rows referencing unknown accounts are skipped', () {
    final withUnknown = [
      'RECURRING',
      'id,title,amount,type,category,account,currency,frequency,nextDue,note,isActive',
      'r9,Gym,500.00,expense,other,NoSuchAccount,ETB,monthly,2026-09-01T00:00:00.000,,true',
    ].join('\n');
    final result = CsvImporter.parse(withUnknown, accountMap);
    expect(result.recurring, isEmpty);
    expect(result.skipped, isNotEmpty);
  });
}


import 'package:flutter/material.dart';
import 'currency_model.dart';

enum AccountType { bank, mobile, cash, savings }

class Account {
  final String id;
  final String name;
  final AccountType type;
  final bool isActive;  // false = soft-deleted (hidden, data preserved)

  /// Currency this account holds. All transactions and transfers recorded
  /// against it are stored in this currency.
  final String currency;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = true,
    this.currency = Currency.defaultCode,
  });

  // ── Firestore serialisation ──────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id':       id,
        'name':     name,
        'type':     type.name,
        'isActive': isActive,
        'currency': currency,
      };

  factory Account.fromMap(Map<String, dynamic> m) => Account(
        id:       m['id']   as String,
        name:     m['name'] as String,
        type:     AccountType.values.firstWhere(
          (e) => e.name == m['type'],
          orElse: () => AccountType.bank,
        ),
        isActive: m['isActive'] as bool? ?? true,
        // Documents written before multi-currency have no code — they are ETB.
        currency: m['currency'] as String? ?? Currency.defaultCode,
      );

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get typeLabel {
    switch (type) {
      case AccountType.bank:    return 'Bank';
      case AccountType.mobile:  return 'Mobile Money';
      case AccountType.cash:    return 'Cash';
      case AccountType.savings: return 'Savings Vault';
    }
  }

  IconData get icon {
    switch (type) {
      case AccountType.bank:    return Icons.account_balance_outlined;
      case AccountType.mobile:  return Icons.account_balance_wallet_outlined;
      case AccountType.cash:    return Icons.payments_outlined;
      case AccountType.savings: return Icons.savings_outlined;
    }
  }

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    bool? isActive,
    String? currency,
  }) =>
      Account(
        id:       id       ?? this.id,
        name:     name     ?? this.name,
        type:     type     ?? this.type,
        isActive: isActive ?? this.isActive,
        currency: currency ?? this.currency,
      );
}

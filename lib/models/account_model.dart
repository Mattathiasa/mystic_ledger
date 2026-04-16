import 'package:flutter/material.dart';

enum AccountType { bank, mobile, cash, savings }

class Account {
  final String id;
  final String name;
  final AccountType type;
  final bool isActive;  // false = soft-deleted (hidden, data preserved)

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = true,
  });

  // ── Firestore serialisation ──────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id':       id,
        'name':     name,
        'type':     type.name,
        'isActive': isActive,
      };

  factory Account.fromMap(Map<String, dynamic> m) => Account(
        id:       m['id']   as String,
        name:     m['name'] as String,
        type:     AccountType.values.firstWhere(
          (e) => e.name == m['type'],
          orElse: () => AccountType.bank,
        ),
        isActive: m['isActive'] as bool? ?? true,
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

  Account copyWith({String? id, String? name, AccountType? type, bool? isActive}) =>
      Account(
        id:       id       ?? this.id,
        name:     name     ?? this.name,
        type:     type     ?? this.type,
        isActive: isActive ?? this.isActive,
      );
}

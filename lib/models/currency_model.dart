import 'package:cloud_firestore/cloud_firestore.dart';

/// A currency the ledger can hold money in.
///
/// Amounts are always stored in the currency of the account that holds them.
/// Conversion to the user's base currency happens only for totals and reports,
/// using the rate snapshot stored on each record.
class Currency {
  final String code;   // ISO 4217, e.g. 'ETB'
  final String symbol; // Display symbol, e.g. 'Br'
  final String name;   // Human name, e.g. 'Ethiopian Birr'

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  /// Currencies offered in pickers. ETB first — it is the default base.
  static const List<Currency> registry = [
    Currency(code: 'ETB', symbol: 'Br',  name: 'Ethiopian Birr'),
    Currency(code: 'USD', symbol: r'$',  name: 'US Dollar'),
    Currency(code: 'EUR', symbol: '€',   name: 'Euro'),
    Currency(code: 'GBP', symbol: '£',   name: 'British Pound'),
    Currency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    Currency(code: 'SAR', symbol: '﷼',   name: 'Saudi Riyal'),
    Currency(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling'),
    Currency(code: 'DJF', symbol: 'Fdj', name: 'Djiboutian Franc'),
  ];

  static const String defaultCode = 'ETB';

  /// Looks up a currency by code, falling back to a bare placeholder so an
  /// unknown code stored in Firestore can never crash a screen.
  static Currency byCode(String code) {
    for (final c in registry) {
      if (c.code == code) return c;
    }
    return Currency(code: code, symbol: code, name: code);
  }

  static Currency get base => byCode(defaultCode);
}

/// A user-maintained conversion rate: 1 unit of [code] == [rateToBase] units
/// of the user's base currency.
class ExchangeRate {
  final String code;
  final double rateToBase;
  final DateTime updatedAt;

  const ExchangeRate({
    required this.code,
    required this.rateToBase,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'code':       code,
        'rateToBase': rateToBase,
        'updatedAt':  Timestamp.fromDate(updatedAt),
      };

  factory ExchangeRate.fromMap(Map<String, dynamic> m) => ExchangeRate(
        code:       m['code'] as String,
        rateToBase: (m['rateToBase'] as num?)?.toDouble() ?? 1.0,
        updatedAt:  (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

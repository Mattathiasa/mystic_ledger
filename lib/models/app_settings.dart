import 'currency_model.dart';

/// Per-user preferences stored at `users/{uid}/settings/prefs`.
///
/// Kept separate from [UserModel] so [FinanceService] can stream it without
/// pulling in profile concerns.
class AppSettings {
  /// Currency that totals and reports are expressed in.
  final String baseCurrency;

  /// Fraction of income owed as tithe (0.10 == 10%).
  final double titheRate;

  /// 1 unit of key == value units of [baseCurrency].
  /// The base currency itself is always 1.0 and is not stored here.
  final Map<String, double> rates;

  const AppSettings({
    this.baseCurrency = Currency.defaultCode,
    this.titheRate    = 0.10,
    this.rates        = const {},
  });

  Map<String, dynamic> toMap() => {
        'baseCurrency': baseCurrency,
        'titheRate':    titheRate,
        'rates':        rates,
      };

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
        baseCurrency: m['baseCurrency'] as String? ?? Currency.defaultCode,
        titheRate:    (m['titheRate'] as num?)?.toDouble() ?? 0.10,
        rates: (m['rates'] as Map?)
                ?.map((k, v) => MapEntry(
                      k as String,
                      (v as num).toDouble(),
                    )) ??
            const {},
      );

  /// 1 unit of [code] expressed in [baseCurrency].
  /// Unknown codes fall back to 1.0 so a missing rate never zeroes a balance.
  double rateFor(String code) {
    if (code == baseCurrency) return 1.0;
    return rates[code] ?? 1.0;
  }

  AppSettings copyWith({
    String? baseCurrency,
    double? titheRate,
    Map<String, double>? rates,
  }) =>
      AppSettings(
        baseCurrency: baseCurrency ?? this.baseCurrency,
        titheRate:    titheRate    ?? this.titheRate,
        rates:        rates        ?? this.rates,
      );
}

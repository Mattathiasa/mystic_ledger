import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches live exchange rates from the free open.er-api.com endpoint.
///
/// No API key required and CORS-enabled, so it works from the web build too.
/// The endpoint answers "1 unit of X in terms of every other currency"; the
/// rate table the ledger stores is the inverse — how many units of the *base*
/// currency one unit of the quoted currency buys — so each result is inverted.
class RateFetcher {
  RateFetcher._();

  static const _baseUrl = 'https://open.er-api.com/v6/latest';

  /// One rate fetched. Null result on network/parse failure.
  static Future<({Map<String, double> ratesToBase, String base})?> fetch({
    required String baseCurrency,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/$baseCurrency'))
          .timeout(timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['result'] != 'success') return null;
      final rates = body['rates'] as Map<String, dynamic>;

      final ratesToBase = <String, double>{};
      rates.forEach((code, v) {
        final perUnit = (v as num).toDouble();
        // The feed says how much of `base` one unit of `code` buys; for the
        // base currency itself it is 1.0, which is exactly what the ledger
        // stores for it. Guard against zero/negative garbage from the feed.
        if (code == baseCurrency) {
          ratesToBase[code] = 1.0;
        } else if (perUnit > 0) {
          ratesToBase[code] = 1 / perUnit;
        }
      });

      return (ratesToBase: ratesToBase, base: baseCurrency);
    } catch (_) {
      return null;
    }
  }
}

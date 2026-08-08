import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../services/finance_service.dart';
import '../services/rate_fetcher.dart';
import '../models/currency_model.dart';

/// Base currency and the exchange rates used to convert other currencies into
/// it for totals and reports.
///
/// Rates are entered by the user, not fetched — you record the rate you
/// actually get. Individual transfers snapshot their own rate at the time, so
/// editing the table here never rewrites history; it only affects how current
/// balances in other currencies are totalled.
class CurrencySettingsScreen extends StatelessWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MysticColors.background,
      appBar: AppBar(
        backgroundColor: MysticColors.appBarBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: MysticColors.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Currency',
            style: headlineStyle(22, italic: true, weight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
              height: 1.5,
              color: MysticColors.outlineVariant.withOpacity(0.5)),
        ),
      ),
      body: Consumer<FinanceService>(
        builder: (context, svc, _) {
          final base = svc.baseCurrency;
          // Only currencies actually in use need a rate.
          final inUse = svc.allAccounts
              .map((a) => a.currency)
              .toSet()
              .where((c) => c != base)
              .toList()
            ..sort();

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 60),
            children: [
              Text('BASE CURRENCY',
                  style: labelStyle(10,
                      letterSpacing: 1.5,
                      color:
                          MysticColors.onSurfaceVariant.withOpacity(0.7))),
              const SizedBox(height: 8),
              Text(
                'Your home total and all reports are shown in this currency.',
                style: bodyStyle(13, color: MysticColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: MysticColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: MysticColors.outlineVariant.withOpacity(0.25)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: base,
                    isExpanded: true,
                    dropdownColor: MysticColors.surfaceContainerLow,
                    style: bodyStyle(15, weight: FontWeight.w600),
                    onChanged: (v) {
                      if (v == null || v == base) return;
                      reportIfWriteFails(ScaffoldMessenger.maybeOf(context),
                          svc.setBaseCurrency(v));
                    },
                    items: Currency.registry
                        .map((c) => DropdownMenuItem(
                              value: c.code,
                              child: Text('${c.code} · ${c.name}'),
                            ))
                        .toList(),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('EXCHANGE RATES',
                      style: labelStyle(10,
                          letterSpacing: 1.5,
                          color: MysticColors.onSurfaceVariant
                              .withOpacity(0.7))),
                  _RefreshRatesButton(base: base, svc: svc),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'What one unit of each currency is worth in $base. Used to '
                'total accounts held in other currencies. Past transfers keep '
                'the rate they were recorded with.',
                style: bodyStyle(13, color: MysticColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),

              if (inUse.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: MysticColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            MysticColors.outlineVariant.withOpacity(0.2)),
                  ),
                  child: Text(
                    'Every account is in $base, so no rates are needed. '
                    'Give an account a different currency and it will appear '
                    'here.',
                    style: bodyStyle(13,
                            color: MysticColors.onSurfaceVariant)
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
                )
              else
                ...inUse.map((code) => _RateRow(
                      code: code,
                      base: base,
                      rate: svc.settings.rateFor(code),
                      onSave: (v) => reportIfWriteFails(
                          ScaffoldMessenger.maybeOf(context),
                          svc.setRate(code, v)),
                    )),
            ],
          );
        },
      ),
    );
  }
}

// ── Refresh rates button ──────────────────────────────────────────────────────

/// Fetches live rates for [base] and writes them into the user's rate table
/// (only for currencies the app actually offers — no point importing a table
/// of 160 rows the user can never use).
class _RefreshRatesButton extends StatefulWidget {
  final String base;
  final FinanceService svc;
  const _RefreshRatesButton({required this.base, required this.svc});

  @override
  State<_RefreshRatesButton> createState() => _RefreshRatesButtonState();
}

class _RefreshRatesButtonState extends State<_RefreshRatesButton> {
  bool _busy = false;

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() => _busy = true);

    final messenger = ScaffoldMessenger.of(context);
    void snack(String msg, Color color) => messenger.showSnackBar(SnackBar(
          content: Text(msg, style: bodyStyle(13, color: Colors.white)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));

    final result = await RateFetcher.fetch(baseCurrency: widget.base);
    if (!mounted) return;
    setState(() => _busy = false);

    if (result == null) {
      snack('Could not reach the rate service — try again later.',
          MysticColors.tertiary);
      return;
    }

    // Apply only the currencies this app recognises.
    final offered = Currency.registry.map((c) => c.code).toSet();
    var updated = 0;
    for (final code in offered) {
      final rate = result.ratesToBase[code];
      if (rate == null || rate <= 0) continue;
      if (code == widget.base) continue; // base is always 1.0
      await widget.svc.setRate(code, rate);
      updated++;
    }
    snack('Rates refreshed for $updated currencies.', MysticColors.secondary);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _busy ? null : _refresh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _busy
              ? MysticColors.onSurface.withOpacity(0.08)
              : MysticColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _busy
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    color: MysticColors.primary, strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh,
                      size: 13, color: MysticColors.onPrimary),
                  const SizedBox(width: 5),
                  Text('REFRESH RATES',
                      style: labelStyle(9,
                          letterSpacing: 1.0,
                          color: MysticColors.onPrimary,
                          weight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}

class _RateRow extends StatefulWidget {
  final String code;
  final String base;
  final double rate;
  final ValueChanged<double> onSave;

  const _RateRow({
    required this.code,
    required this.base,
    required this.rate,
    required this.onSave,
  });

  @override
  State<_RateRow> createState() => _RateRowState();
}

class _RateRowState extends State<_RateRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.rate == 1.0 ? '' : widget.rate.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final v = double.tryParse(_ctrl.text.replaceAll(',', ''));
    // A zero or negative rate would wipe out the converted balance.
    if (v == null || v <= 0) return;
    widget.onSave(v);
  }

  @override
  Widget build(BuildContext context) {
    final name = Currency.byCode(widget.code).name;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: MysticColors.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.code} · $name',
              style: bodyStyle(14, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('1 ${widget.code}  =',
                  style: bodyStyle(13, weight: FontWeight.w600)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  onSubmitted: (_) => _commit(),
                  onTapOutside: (_) {
                    FocusScope.of(context).unfocus();
                    _commit();
                  },
                  style: bodyStyle(18,
                      weight: FontWeight.w800, color: MysticColors.primary),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0.00',
                    hintStyle: bodyStyle(18,
                        weight: FontWeight.w800,
                        color: MysticColors.onSurface.withOpacity(0.2)),
                    contentPadding: const EdgeInsets.only(bottom: 6),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: MysticColors.outlineVariant
                              .withOpacity(0.4)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: MysticColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(widget.base,
                  style: bodyStyle(13, weight: FontWeight.w600)),
            ],
          ),
          if (widget.rate == 1.0) ...[
            const SizedBox(height: 6),
            Text(
              'No rate set — this currency is currently counted 1:1 in your '
              'total, which is almost certainly wrong.',
              style: labelStyle(10, color: MysticColors.tertiary),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              '100 ${widget.code} ≈ ${widget.base} '
              '${NumberFormat('#,##0.00').format(widget.rate * 100)}',
              style: labelStyle(10,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
            ),
          ],
        ],
      ),
    );
  }
}

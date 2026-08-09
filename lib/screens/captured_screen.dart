import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sms_capture_service.dart';
import '../services/sms_parser.dart';
import '../services/l10n.dart';
import '../widgets/app_theme.dart';
import 'journal_screen.dart'; // entrySlideUpRoute
import 'new_entry_screen.dart';

/// Review queue for SMS-captured bank alerts (Telebirr, CBE, Awash).
///
/// Nothing captured here is ever recorded until the user explicitly records it
/// (or dismisses it). Approving pre-fills [NewEntryScreen] with the parsed
/// fields; the account and category still get the user's say-so.
class CapturedScreen extends StatefulWidget {
  const CapturedScreen({super.key});

  @override
  State<CapturedScreen> createState() => _CapturedScreenState();
}

enum _DraftSort { newest, oldest, amountHigh, amountLow }

extension _DraftSortLabel on _DraftSort {
  String get label => switch (this) {
        _DraftSort.newest     => L10n.t('Newest first'),
        _DraftSort.oldest     => L10n.t('Oldest first'),
        _DraftSort.amountHigh => L10n.t('Largest amount'),
        _DraftSort.amountLow  => L10n.t('Smallest amount'),
      };
}

class _CapturedScreenState extends State<CapturedScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _DraftSort _sort = _DraftSort.newest; // recent first by default
  CapturedBank? _bank;
  CapturedDirection? _direction;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CapturedSms> _visible(List<CapturedSms> drafts) {
    final q = _query.trim().toLowerCase();
    var list = drafts.where((d) {
      if (_bank != null && d.bank != _bank) return false;
      if (_direction != null && d.direction != _direction) return false;
      if (q.isEmpty) return true;
      final haystack = [
        d.counterparty ?? '',
        d.reference ?? '',
        d.sender,
        d.body,
        d.amount == null ? '' : d.amount!.toStringAsFixed(2),
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();

    switch (_sort) {
      case _DraftSort.newest:
        list.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      case _DraftSort.oldest:
        list.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
      case _DraftSort.amountHigh:
        list.sort((a, b) => (b.amount ?? -1).compareTo(a.amount ?? -1));
      case _DraftSort.amountLow:
        list.sort((a, b) => (a.amount ?? -1).compareTo(b.amount ?? -1));
    }
    return list;
  }

  Future<void> _record(BuildContext context, CapturedSms draft) async {
    final saved = await Navigator.of(context).push<bool>(
      entrySlideUpRoute(NewEntryScreen(draft: draft)),
    );
    if (saved == true) {
      await SmsCaptureService.instance.approve(draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when dark mode or the language flips: the palette and strings
    // live in mutable statics, so const widget instances would skip us.
    Theme.of(context);
    Localizations.localeOf(context);

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
        title: Text(L10n.t('Captured'),
            style: headlineStyle(22, italic: true, weight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
              height: 1.5,
              color: MysticColors.outlineVariant.withOpacity(0.5)),
        ),
      ),
      body: ListenableBuilder(
        listenable: SmsCaptureService.instance,
        builder: (context, _) {
          final svc = SmsCaptureService.instance;
          final drafts = svc.pendingDrafts;

          if (drafts.isEmpty) {
            return _EmptyQueue(svc: SmsCaptureService.instance);
          }

          final visible = _visible(drafts);
          final fmt = NumberFormat('#,##0.00');
          return Column(
            children: [
              _QueueHeader(
                total: drafts.length,
                visible: visible.length,
                sort: _sort,
                onSort: (s) => setState(() => _sort = s),
              ),
              _QueueSearch(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
              ),
              _BankRow(selected: _bank, onChanged: (b) => setState(() => _bank = b)),
              _DirectionRow(
                  selected: _direction, onChanged: (d) => setState(() => _direction = d)),
              const SizedBox(height: 4),
              Expanded(
                child: visible.isEmpty
                    ? _NoMatches()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
                        itemCount: visible.length,
                        itemBuilder: (context, i) {
                          final d = visible[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _DraftCard(
                              draft: d,
                              fmt: fmt,
                              onRecord: () => _record(context, d),
                              onDismiss: () =>
                                  SmsCaptureService.instance.dismiss(d.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Toolbar: count + sort ────────────────────────────────────────────────────

class _QueueHeader extends StatelessWidget {
  final int total;
  final int visible;
  final _DraftSort sort;
  final ValueChanged<_DraftSort> onSort;
  const _QueueHeader({
    required this.total,
    required this.visible,
    required this.sort,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final count = total == 1
        ? L10n.t('One message awaits your hand')
        : '$total ${L10n.t('messages await your hand')}';
    final label = visible == total
        ? count
        : '${L10n.t('Showing')} $visible ${L10n.t('of')} $total';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: labelStyle(10,
                    letterSpacing: 2.0,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
          ),
          PopupMenuButton<_DraftSort>(
            initialValue: sort,
            color: MysticColors.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: MysticColors.outlineVariant.withOpacity(0.3)),
            ),
            offset: const Offset(0, 40),
            onSelected: onSort,
            itemBuilder: (context) => [
              for (final s in _DraftSort.values)
                PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(
                        s == sort ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 16,
                        color: s == sort
                            ? MysticColors.primary
                            : MysticColors.onSurfaceVariant.withOpacity(0.4),
                      ),
                      const SizedBox(width: 10),
                      Text(s.label,
                          style: bodyStyle(14, weight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: MysticColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: MysticColors.outlineVariant.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert,
                      size: 15, color: MysticColors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(sort.label,
                      style: labelStyle(10,
                          letterSpacing: 0.6,
                          color: MysticColors.onSurfaceVariant)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down,
                      size: 16, color: MysticColors.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search field ─────────────────────────────────────────────────────────────

class _QueueSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _QueueSearch({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: MysticColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: MysticColors.outlineVariant.withOpacity(0.2)),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: bodyStyle(15, weight: FontWeight.w600),
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: L10n.t('Search the queue…'),
            hintStyle: bodyStyle(15, color: MysticColors.onSurface.withOpacity(0.3))
                .copyWith(fontStyle: FontStyle.italic),
            icon: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Icon(Icons.search,
                  size: 20, color: MysticColors.onSurfaceVariant),
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: Icon(Icons.close,
                        size: 18, color: MysticColors.onSurfaceVariant),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Filter chip rows ─────────────────────────────────────────────────────────

/// A horizontal scrollable row of filter chips where [T?] null means "All".
class _ChipBar<T> extends StatelessWidget {
  final List<(T?, String)> options;
  final T? selected;
  final ValueChanged<T?> onChanged;
  const _ChipBar({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Row(
        children: [
          for (final (value, label) in options) ...[
            ChoiceChip(
              label: Text(label,
                  style: labelStyle(10,
                      letterSpacing: 0.4,
                      color: value == selected
                          ? MysticColors.onPrimary
                          : MysticColors.onSurfaceVariant)),
              selected: value == selected,
              selectedColor: MysticColors.primary,
              backgroundColor: Colors.transparent,
              side: BorderSide(
                  color: value == selected
                      ? MysticColors.primary
                      : MysticColors.outlineVariant.withOpacity(0.35)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onSelected: (_) => onChanged(value == selected ? null : value),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  final CapturedBank? selected;
  final ValueChanged<CapturedBank?> onChanged;
  const _BankRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _ChipBar<CapturedBank>(
      selected: selected,
      onChanged: onChanged,
      options: [
        (null, L10n.t('All')),
        (CapturedBank.telebirr, 'Telebirr'),
        (CapturedBank.cbe, 'CBE'),
        (CapturedBank.awash, L10n.t('Awash Bank')),
        (CapturedBank.recurring, L10n.t('Recurring')),
      ],
    );
  }
}

class _DirectionRow extends StatelessWidget {
  final CapturedDirection? selected;
  final ValueChanged<CapturedDirection?> onChanged;
  const _DirectionRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _ChipBar<CapturedDirection>(
      selected: selected,
      onChanged: onChanged,
      options: [
        (null, L10n.t('All')),
        (CapturedDirection.income, L10n.t('Received')),
        (CapturedDirection.expense, L10n.t('Sent / Paid')),
        (CapturedDirection.unknown, L10n.t('Unclear')),
      ],
    );
  }
}

// ── Empty states ─────────────────────────────────────────────────────────────

class _NoMatches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: MysticColors.outlineVariant),
            const SizedBox(height: 12),
            Text(
              L10n.t('No matches — try a different search or filter.'),
              textAlign: TextAlign.center,
              style: bodyStyle(14,
                  color: MysticColors.onSurfaceVariant.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  final SmsCaptureService svc;
  const _EmptyQueue({required this.svc});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Column(
        children: [
          Icon(Icons.mark_email_unread_outlined,
              size: 64, color: MysticColors.outlineVariant),
          const SizedBox(height: 20),
          Text(L10n.t('Nothing captured yet'),
              style: headlineStyle(24, italic: true, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(
            svc.supported
                ? svc.isEnabled
                    ? L10n.t('Telebirr, CBE and Awash transaction alerts will '
                        'appear here the moment they arrive. You can also scan '
                        'your inbox to pull in older ones.')
                    : L10n.t('Turn on auto-capture in Profile, then bank alerts will '
                        'queue here for your review before they are recorded.')
                : L10n.t('SMS auto-capture is available on Android. On other '
                    'platforms, entries are written by hand.'),
            textAlign: TextAlign.center,
            style: bodyStyle(14,
                color: MysticColors.onSurfaceVariant.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

// ── One captured message ──────────────────────────────────────────────────────

String _directionLabel(CapturedDirection d) => switch (d) {
      CapturedDirection.income  => L10n.t('Received'),
      CapturedDirection.expense => L10n.t('Sent / Paid'),
      CapturedDirection.unknown => L10n.t('Direction unclear'),
    };

class _DraftCard extends StatelessWidget {
  final CapturedSms draft;
  final NumberFormat fmt;
  final VoidCallback onRecord;
  final VoidCallback onDismiss;

  const _DraftCard({
    required this.draft,
    required this.fmt,
    required this.onRecord,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final income = draft.direction == CapturedDirection.income;
    final accent = income ? MysticColors.secondary : MysticColors.tertiary;
    final unknown = draft.direction == CapturedDirection.unknown;

    return Container(
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: MysticColors.onSurface.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount + direction
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    unknown
                        ? Icons.question_mark
                        : (income
                            ? Icons.call_received
                            : Icons.call_made),
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.amount == null
                            ? '— ${L10n.t('amount unclear')} —'
                            : 'ETB ${fmt.format(draft.amount)}',
                        style: headlineStyle(26,
                            italic: false, weight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_directionLabel(draft.direction)}  ·  ${draft.bank.label}${draft.fee != null ? '  ·  ${L10n.t('fee')} ETB ${fmt.format(draft.fee)}' : ''}',
                        style: bodyStyle(13,
                            weight: FontWeight.w600, color: accent),
                      ),
                    ],
                  ),
                ),
                _ConfidenceBadge(confidence: draft.confidence),
              ],
            ),
            // An own-account transfer (e.g. CBE: account → account) is
            // neither income nor expense. Say so plainly so nobody records it
            // as a spurious expense.
            if (unknown) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.help_outline,
                      size: 14, color: MysticColors.tertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      L10n.t('Direction unclear — check the message before '
                          'recording. A transfer between your own accounts is '
                          'not income or expense.'),
                      style: bodyStyle(11, color: MysticColors.tertiary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // Counterparty / who
            if (draft.counterparty != null) ...[
              Text(draft.counterparty!,
                  style: headlineStyle(17,
                      italic: false, weight: FontWeight.w700)),
              const SizedBox(height: 4),
            ],
            if (draft.date != null)
              Text(
                DateFormat('EEE, MMM d · h:mm a').format(draft.date!),
                style: labelStyle(10,
                    letterSpacing: 0.8,
                    color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
              ),
            if (draft.reference != null) ...[
              const SizedBox(height: 4),
              Text('${L10n.t('Ref')}: ${draft.reference}',
                  style: labelStyle(10,
                      letterSpacing: 0.6,
                      color: MysticColors.onSurfaceVariant.withOpacity(0.5))),
            ],

            // Raw message (collapsible, on-device only)
            const SizedBox(height: 10),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                dense: true,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: MysticColors.onSurfaceVariant.withOpacity(0.4),
                collapsedIconColor:
                    MysticColors.onSurfaceVariant.withOpacity(0.4),
                title: Text(L10n.t('See raw message'),
                    style: labelStyle(10,
                        letterSpacing: 1.2,
                        color: MysticColors.onSurfaceVariant.withOpacity(0.5))),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MysticColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      draft.body,
                      style: bodyStyle(12,
                          color: MysticColors.onSurfaceVariant.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onRecord,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: MysticColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: MysticColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(L10n.t('RECORD'),
                            style: labelStyle(11,
                                letterSpacing: 1.5,
                                color: MysticColors.onPrimary)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: MysticColors.outlineVariant.withOpacity(0.6)),
                    ),
                    child: Center(
                      child: Text(L10n.t('IGNORE'),
                          style: labelStyle(11,
                              letterSpacing: 1.5,
                              color: MysticColors.onSurfaceVariant
                                  .withOpacity(0.6))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confidence badge ──────────────────────────────────────────────────────────

class _ConfidenceBadge extends StatelessWidget {
  final SmsConfidence confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (confidence) {
      SmsConfidence.high   => (L10n.t('CONFIDENT'), MysticColors.secondary),
      SmsConfidence.medium => (L10n.t('CHECK'), MysticColors.primary),
      SmsConfidence.low    => (L10n.t('UNCLEAR'), MysticColors.tertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: labelStyle(8,
              letterSpacing: 1.0, color: color, weight: FontWeight.w600)),
    );
  }
}

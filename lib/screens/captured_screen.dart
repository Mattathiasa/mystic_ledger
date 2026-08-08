import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sms_capture_service.dart';
import '../services/telebirr_parser.dart';
import '../widgets/app_theme.dart';
import 'journal_screen.dart'; // entrySlideUpRoute
import 'new_entry_screen.dart';

/// Review queue for SMS-captured Telebirr alerts.
///
/// Nothing captured here is ever recorded until the user explicitly records it
/// (or dismisses it). Approving pre-fills [NewEntryScreen] with the parsed
/// fields; the account and category still get the user's say-so.
class CapturedScreen extends StatelessWidget {
  const CapturedScreen({super.key});

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
    return Scaffold(
      backgroundColor: MysticColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFCF0),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: MysticColors.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Captured',
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

          final fmt = NumberFormat('#,##0.00');
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
            itemCount: drafts.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    drafts.length == 1
                        ? 'One message awaits your hand'
                        : '${drafts.length} messages await your hand',
                    style: labelStyle(10,
                        letterSpacing: 2.0,
                        color: MysticColors.onSurfaceVariant.withOpacity(0.6)),
                  ),
                );
              }
              final d = drafts[i - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _DraftCard(
                  draft: d,
                  fmt: fmt,
                  onRecord: () => _record(context, d),
                  onDismiss: () => SmsCaptureService.instance.dismiss(d.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Empty queue ───────────────────────────────────────────────────────────────

class _EmptyQueue extends StatelessWidget {
  final SmsCaptureService svc;
  const _EmptyQueue({required this.svc});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Column(
        children: [
          const Icon(Icons.mark_email_unread_outlined,
              size: 64, color: MysticColors.outlineVariant),
          const SizedBox(height: 20),
          Text('Nothing captured yet',
              style: headlineStyle(24, italic: true, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(
            svc.supported
                ? svc.isEnabled
                    ? 'Telebirr transaction alerts will appear here the moment '
                        'they arrive. You can also scan your inbox to pull in '
                        'older ones.'
                    : 'Turn on auto-capture in Profile, then Telebirr alerts '
                        'will queue here for your review before they are '
                        'recorded.'
                : 'SMS auto-capture is available on Android. On other '
                    'platforms, entries are written by hand.',
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
        border: Border.all(
            color: accent.withOpacity(0.25)),
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
                            ? '— amount unclear —'
                            : 'ETB ${fmt.format(draft.amount)}',
                        style: headlineStyle(26,
                            italic: false, weight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${draft.directionLabel}${draft.fee != null ? '  ·  fee ETB ${fmt.format(draft.fee)}' : ''}',
                        style: bodyStyle(13,
                            weight: FontWeight.w600, color: accent),
                      ),
                    ],
                  ),
                ),
                _ConfidenceBadge(confidence: draft.confidence),
              ],
            ),
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
              Text('Ref: ${draft.reference}',
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
                title: Text('See raw message',
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
                        child: Text('RECORD',
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
                      child: Text('IGNORE',
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
      SmsConfidence.high   => ('CONFIDENT', MysticColors.secondary),
      SmsConfidence.medium => ('CHECK', MysticColors.primary),
      SmsConfidence.low    => ('UNCLEAR', MysticColors.tertiary),
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

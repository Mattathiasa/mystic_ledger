import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../services/l10n.dart';
import 'app_theme.dart';

/// One mutable split line in the entry form: a category and its amount.
class SplitDraft {
  TransactionCategory category;
  final TextEditingController amountCtrl;
  SplitDraft(this.category) : amountCtrl = TextEditingController();
}

/// #tag chips + input row for the entry form.
class TagsField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> tags;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  const TagsField({
    super.key,
    required this.controller,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.t('TAGS (OPTIONAL)'),
            style: labelStyle(9,
                letterSpacing: 1.5,
                color: MysticColors.onSurfaceVariant.withOpacity(0.6))),
        const SizedBox(height: 12),
        if (tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < tags.length; i++)
                _TagChip(
                  label: '#${tags[i]}',
                  onRemove: () => onRemove(i),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onAdd(),
                textCapitalization: TextCapitalization.none,
                style: bodyStyle(14, weight: FontWeight.w600),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: L10n.t('Add a tag…'),
                  hintStyle: bodyStyle(14,
                          color: MysticColors.onSurface.withOpacity(0.25))
                      .copyWith(fontStyle: FontStyle.italic),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: MysticColors.outlineVariant.withOpacity(0.3),
                        width: 1.5),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: MysticColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: MysticColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add,
                    size: 18, color: MysticColors.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _TagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: MysticColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: MysticColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: labelStyle(10,
                  letterSpacing: 0.5,
                  color: MysticColors.primary,
                  weight: FontWeight.w600)),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close,
                  size: 13, color: MysticColors.primary.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle that switches the entry into split mode.
class SplitToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const SplitToggle({super.key, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.call_split,
            size: 18,
            color: enabled
                ? MysticColors.primary
                : MysticColors.onSurfaceVariant.withOpacity(0.4)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(L10n.t('Split across categories'),
              style: bodyStyle(14, weight: FontWeight.w600)),
        ),
        Switch(
          value: enabled,
          activeTrackColor: MysticColors.primary.withOpacity(0.5),
          activeColor: MysticColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// The split lines themselves, with a live sum that must match [total].
class SplitEditor extends StatelessWidget {
  final List<SplitDraft> drafts;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int index, TransactionCategory category) onCategory;
  final double total;
  final double? sum;
  const SplitEditor({
    super.key,
    required this.drafts,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
    required this.onCategory,
    required this.total,
    required this.sum,
  });

  @override
  Widget build(BuildContext context) {
    final balanced = sum != null && (sum! - total).abs() <= 0.005;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MysticColors.surfaceContainerHigh.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: balanced
                ? MysticColors.secondary.withOpacity(0.35)
                : MysticColors.tertiary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < drafts.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _SplitRow(
              draft: drafts[i],
              onChanged: onChanged,
              onRemove: () => onRemove(i),
              onCategory: (c) => onCategory(i, c),
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: MysticColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: MysticColors.primary.withOpacity(0.3)),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: MysticColors.primary),
                    const SizedBox(width: 6),
                    Text(L10n.t('Add line'),
                        style: labelStyle(11,
                            letterSpacing: 1.0,
                            color: MysticColors.primary,
                            weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Live balance feedback — green when the lines match the total.
          Row(
            children: [
              Icon(
                balanced ? Icons.check_circle_outline : Icons.info_outline,
                size: 15,
                color: balanced
                    ? MysticColors.secondary
                    : MysticColors.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sum == null
                      ? L10n.t('Enter an amount for every line.')
                      : balanced
                          ? L10n.t('Lines add up to the entry total.')
                          : '${L10n.t('Lines total')} ${_fmt(sum!)} — '
                              '${L10n.t('they must equal')} ${_fmt(total)}.',
                  style: labelStyle(10,
                      color: balanced
                          ? MysticColors.secondary
                          : MysticColors.tertiary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) => v.toStringAsFixed(2);
}

class _SplitRow extends StatelessWidget {
  final SplitDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final ValueChanged<TransactionCategory> onCategory;
  const _SplitRow({
    required this.draft,
    required this.onChanged,
    required this.onRemove,
    required this.onCategory,
  });

  static const _categories = [
    TransactionCategory.food,
    TransactionCategory.transport,
    TransactionCategory.utilities,
    TransactionCategory.entertainment,
    TransactionCategory.health,
    TransactionCategory.education,
    TransactionCategory.rent,
    TransactionCategory.clothing,
    TransactionCategory.business,
    TransactionCategory.taxes,
    TransactionCategory.insurance,
    TransactionCategory.subscriptions,
    TransactionCategory.tithe,
    TransactionCategory.other,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TransactionCategory>(
              value: draft.category,
              isExpanded: true,
              dropdownColor: MysticColors.surfaceContainerLow,
              style: bodyStyle(13, weight: FontWeight.w600),
              onChanged: (c) {
                if (c != null) onCategory(c);
              },
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.mystiqueLabel,
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: draft.amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            onChanged: (_) => onChanged(),
            style: bodyStyle(14, weight: FontWeight.w800),
            decoration: InputDecoration(
              isDense: true,
              hintText: '0.00',
              hintStyle: bodyStyle(14,
                      color: MysticColors.onSurface.withOpacity(0.2))
                  .copyWith(fontStyle: FontStyle.italic),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: MysticColors.outlineVariant.withOpacity(0.3),
                    width: 1.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: MysticColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.close,
                size: 17, color: MysticColors.tertiary.withOpacity(0.7)),
          ),
        ),
      ],
    );
  }
}

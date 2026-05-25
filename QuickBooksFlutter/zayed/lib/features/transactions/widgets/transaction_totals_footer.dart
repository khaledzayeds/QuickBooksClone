import 'package:flutter/material.dart';

import 'transaction_models.dart';

class TransactionTotalsFooter extends StatelessWidget {
  const TransactionTotalsFooter({super.key, required this.totals});

  final TransactionTotalsUiModel totals;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 28, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Spacer(),
            SizedBox(
              width: 290,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TotalRow(label: 'Subtotal', value: totals.subtotal, currency: totals.currency),
                  if (totals.discountTotal != 0)
                    _TotalRow(label: 'Discount', value: totals.discountTotal, currency: totals.currency),
                  if (totals.taxTotal != 0)
                    _TotalRow(label: 'Tax', value: totals.taxTotal, currency: totals.currency),
                  if (totals.shipping != 0)
                    _TotalRow(label: 'Shipping', value: totals.shipping, currency: totals.currency),
                  const Divider(height: 12),
                  _TotalRow(label: 'Total', value: totals.total, currency: totals.currency, strong: true),
                  _TotalRow(label: 'Payments Applied', value: totals.paid, currency: totals.currency),
                  _TotalRow(label: 'Balance Due', value: totals.balanceDue, currency: totals.currency, strong: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.currency,
    this.strong = false,
  });

  final String label;
  final double value;
  final String currency;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = theme.textTheme.bodySmall?.copyWith(
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
      color: strong ? cs.onSurface : cs.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            '${value.toStringAsFixed(2)} $currency',
            style: style,
          ),
        ],
      ),
    );
  }
}

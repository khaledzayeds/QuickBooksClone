import 'package:flutter/material.dart';

import 'transaction_models.dart';

class TransactionTotalsFooter extends StatelessWidget {
  const TransactionTotalsFooter({super.key, required this.totals});

  final TransactionTotalsUiModel totals;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final metrics = [
              _TotalMetric('Subtotal', totals.subtotal, totals.currency, Icons.summarize_outlined),
              _TotalMetric('Discount', totals.discountTotal, totals.currency, Icons.discount_outlined),
              _TotalMetric('Tax', totals.taxTotal, totals.currency, Icons.receipt_long_outlined),
              if (totals.shipping != 0) _TotalMetric('Shipping', totals.shipping, totals.currency, Icons.local_shipping_outlined),
              _TotalMetric('Total', totals.total, totals.currency, Icons.calculate_outlined, strong: true),
              if (totals.paid != 0) _TotalMetric('Paid', totals.paid, totals.currency, Icons.payments_outlined),
              _TotalMetric('Balance Due', totals.balanceDue, totals.currency, Icons.account_balance_wallet_outlined, strong: true),
            ];

            if (compact) {
              return Column(children: metrics.map((m) => Padding(padding: const EdgeInsets.only(bottom: 8), child: m)).toList());
            }

            return Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.end, children: metrics);
          },
        ),
      ),
    );
  }
}

class _TotalMetric extends StatelessWidget {
  const _TotalMetric(this.label, this.value, this.currency, this.icon, {this.strong = false});

  final String label;
  final double value;
  final String currency;
  final IconData icon;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: strong ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: strong ? cs.onPrimaryContainer : cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: strong ? cs.onPrimaryContainer : cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('${value.toStringAsFixed(2)} $currency', style: TextStyle(fontWeight: FontWeight.w900, color: strong ? cs.onPrimaryContainer : null)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

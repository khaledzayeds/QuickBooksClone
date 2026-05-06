import 'package:flutter/material.dart';

import 'transaction_models.dart';

class TransactionTotalsFooter extends StatelessWidget {
  const TransactionTotalsFooter({super.key, required this.totals});

  final TransactionTotalsUiModel totals;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final metrics = [
              _TotalMetric(
                'Subtotal',
                totals.subtotal,
                totals.currency,
                Icons.summarize_outlined,
              ),
              _TotalMetric(
                'Discount',
                totals.discountTotal,
                totals.currency,
                Icons.discount_outlined,
              ),
              _TotalMetric(
                'Tax',
                totals.taxTotal,
                totals.currency,
                Icons.receipt_long_outlined,
              ),
              if (totals.shipping != 0)
                _TotalMetric(
                  'Shipping',
                  totals.shipping,
                  totals.currency,
                  Icons.local_shipping_outlined,
                ),
              _TotalMetric(
                'Total',
                totals.total,
                totals.currency,
                Icons.calculate_outlined,
                strong: true,
              ),
              if (totals.paid != 0)
                _TotalMetric(
                  'Paid',
                  totals.paid,
                  totals.currency,
                  Icons.payments_outlined,
                ),
              _TotalMetric(
                'Balance Due',
                totals.balanceDue,
                totals.currency,
                Icons.account_balance_wallet_outlined,
                strong: true,
              ),
            ];

            if (compact) {
              return Column(
                children: metrics
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: m,
                      ),
                    )
                    .toList(),
              );
            }

            return Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: metrics,
            );
          },
        ),
      ),
    );
  }
}

class _TotalMetric extends StatelessWidget {
  const _TotalMetric(
    this.label,
    this.value,
    this.currency,
    this.icon, {
    this.strong = false,
  });

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
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: strong
            ? cs.primaryContainer
            : cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: strong
              ? cs.primary.withValues(alpha: 0.25)
              : cs.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: strong ? cs.onPrimaryContainer : cs.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: strong ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${value.toStringAsFixed(2)} $currency',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: strong ? cs.onPrimaryContainer : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

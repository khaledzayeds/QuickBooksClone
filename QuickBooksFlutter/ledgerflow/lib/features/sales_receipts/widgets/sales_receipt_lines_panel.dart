import 'package:flutter/material.dart';

import '../../../core/widgets/qb/qb_transaction_line_grid.dart';
import '../../../core/widgets/qb/transaction_line_price_mode.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_models.dart';
import '../../transactions/widgets/transaction_totals_footer.dart';

class SalesReceiptLinesPanel extends StatelessWidget {
  const SalesReceiptLinesPanel({
    super.key,
    required this.lines,
    required this.totals,
    required this.onAddLine,
    required this.onLinesChanged,
  });

  final List<TransactionLineEntry> lines;
  final TransactionTotalsUiModel totals;
  final VoidCallback onAddLine;
  final VoidCallback onLinesChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Expanded(
      child: Column(
        children: [
          Container(
            color: cs.surfaceContainerLowest,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Text(
                  'Products and services',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  '• Tab through cells  • Enter adds a new line',
                  style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAddLine,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add line'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: QbTransactionLineGrid(
                    lines: lines,
                    priceMode: TransactionLinePriceMode.sales,
                    fillWidth: true,
                    compact: true,
                    showAddLineFooter: true,
                    onChanged: onLinesChanged,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(top: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: TransactionTotalsFooter(totals: totals),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

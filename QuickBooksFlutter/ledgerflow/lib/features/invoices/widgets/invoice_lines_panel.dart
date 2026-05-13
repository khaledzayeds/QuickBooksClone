import 'package:flutter/material.dart';

import '../../../core/widgets/qb/qb_transaction_line_grid.dart';
import '../../../core/widgets/qb/transaction_line_price_mode.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_models.dart';

class InvoiceLinesPanel extends StatelessWidget {
  const InvoiceLinesPanel({
    super.key,
    required this.lines,
    required this.totals,
    required this.onAddLine,
    required this.onLinesChanged,
    this.memoField,
    this.saving = false,
    this.posting = false,
    this.readOnly = false,
    this.onSaveAndClose,
    this.onSaveAndNew,
    this.onClear,
  });

  final List<TransactionLineEntry> lines;
  final TransactionTotalsUiModel totals;
  final VoidCallback onAddLine;
  final VoidCallback onLinesChanged;
  final Widget? memoField;
  final bool saving;
  final bool posting;
  final bool readOnly;
  final VoidCallback? onSaveAndClose;
  final VoidCallback? onSaveAndNew;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFE9EFF2),
            border: Border(
              top: BorderSide(color: Color(0xFFB7C3CB)),
              bottom: BorderSide(color: Color(0xFFB7C3CB)),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Products and Services',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF233F4C),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Tab moves across cells • Enter commits row',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF596B74),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: readOnly ? null : onAddLine,
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Add Line'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: QbTransactionLineGrid(
              lines: lines,
              priceMode: TransactionLinePriceMode.sales,
              fillWidth: true,
              compact: true,
              showAddLineFooter: false,
              readOnly: readOnly,
              onChanged: onLinesChanged,
            ),
          ),
        ),
        _QuickBooksInvoiceFooter(
          totals: totals,
          memoField: memoField,
          saving: saving,
          posting: posting,
          onSaveAndClose: onSaveAndClose,
          onSaveAndNew: onSaveAndNew,
          onClear: onClear,
          readOnly: readOnly,
        ),
      ],
    );
  }
}

class _QuickBooksInvoiceFooter extends StatelessWidget {
  const _QuickBooksInvoiceFooter({
    required this.totals,
    required this.saving,
    required this.posting,
    required this.readOnly,
    this.memoField,
    this.onSaveAndClose,
    this.onSaveAndNew,
    this.onClear,
  });

  final TransactionTotalsUiModel totals;
  final Widget? memoField;
  final bool saving;
  final bool posting;
  final bool readOnly;
  final VoidCallback? onSaveAndClose;
  final VoidCallback? onSaveAndNew;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = saving || posting;
    final memo = memoField ?? _LegacyMemoPlaceholder();

    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F9),
        border: Border(top: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUSTOMER MESSAGE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF53646D),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFB7C3CB)),
                  ),
                  child: Text(
                    'Thank you for your business.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF3B4D56),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'MEMO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF53646D),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(height: 34, child: memo),
              ],
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 310,
            child: Column(
              children: [
                _TotalRow(
                  label: 'TOTAL',
                  value: totals.total,
                  currency: totals.currency,
                ),
                _TotalRow(
                  label: 'PAYMENTS APPLIED',
                  value: totals.paid,
                  currency: totals.currency,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F1F4),
                    border: Border.all(color: const Color(0xFF9DB2BC)),
                  ),
                  child: _TotalRow(
                    label: 'BALANCE DUE',
                    value: totals.balanceDue,
                    currency: totals.currency,
                    strong: true,
                    noPadding: true,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: busy || readOnly ? null : onSaveAndClose,
                      style: _buttonStyle(),
                      child: Text(saving ? 'Saving...' : 'Save & Close'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: busy || readOnly ? null : onSaveAndNew,
                      style: _buttonStyle(),
                      child: const Text('Save & New'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: busy ? null : onClear,
                      style: _buttonStyle(),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      side: const BorderSide(color: Color(0xFF8FA1AB)),
    );
  }
}

class _LegacyMemoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7C3CB)),
      ),
      child: Text(
        'Optional',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7B8B93)),
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
    this.noPadding = false,
  });

  final String label;
  final double value;
  final String currency;
  final bool strong;
  final bool noPadding;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
      color: const Color(0xFF253C47),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: noPadding ? 0 : 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('${value.toStringAsFixed(2)} $currency', style: style),
        ],
      ),
    );
  }
}

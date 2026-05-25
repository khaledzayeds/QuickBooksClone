import 'package:flutter/material.dart';

import '../../features/purchase_orders/data/models/order_line_entry.dart';
import 'qb/qb_transaction_line_grid.dart';
import 'qb/transaction_line_price_mode.dart';

export 'qb/transaction_line_price_mode.dart';

class TransactionLineTable extends StatelessWidget {
  const TransactionLineTable({
    super.key,
    required this.lines,
    required this.onChanged,
    this.priceMode = TransactionLinePriceMode.purchase,
    this.fillWidth = false,
    this.compact = false,
    this.showAddLineFooter = true,
  });

  final List<TransactionLineEntry> lines;
  final VoidCallback onChanged;
  final TransactionLinePriceMode priceMode;
  final bool fillWidth;
  final bool compact;
  final bool showAddLineFooter;

  @override
  Widget build(BuildContext context) {
    return QbTransactionLineGrid(
      lines: lines,
      onChanged: onChanged,
      priceMode: priceMode,
      fillWidth: fillWidth,
      compact: compact,
      showAddLineFooter: showAddLineFooter,
    );
  }
}

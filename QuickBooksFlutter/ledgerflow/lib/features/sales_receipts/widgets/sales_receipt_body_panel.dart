import 'package:flutter/material.dart';

import '../../accounts/data/models/account_model.dart';
import '../../customers/data/models/customer_model.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_models.dart';
import 'sales_receipt_header_panel.dart';
import 'sales_receipt_lines_panel.dart';

class SalesReceiptBodyPanel extends StatelessWidget {
  const SalesReceiptBodyPanel({
    super.key,
    required this.numberField,
    required this.dateField,
    required this.referenceField,
    required this.customerField,
    required this.depositAccountField,
    required this.paymentMethodField,
    required this.lines,
    required this.totals,
    required this.onAddLine,
    required this.onLinesChanged,
    this.customers = const <CustomerModel>[],
    this.accounts = const <AccountModel>[],
  });

  final Widget numberField;
  final Widget dateField;
  final Widget referenceField;
  final Widget customerField;
  final Widget depositAccountField;
  final Widget paymentMethodField;
  final List<TransactionLineEntry> lines;
  final TransactionTotalsUiModel totals;
  final VoidCallback onAddLine;
  final VoidCallback onLinesChanged;

  // Kept as optional inputs for future body-level validation/empty states.
  final List<CustomerModel> customers;
  final List<AccountModel> accounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SalesReceiptHeaderPanel(
          numberField: numberField,
          dateField: dateField,
          referenceField: referenceField,
          customerField: customerField,
          depositAccountField: depositAccountField,
          paymentMethodField: paymentMethodField,
        ),
        Divider(height: 1, color: theme.dividerColor),
        SalesReceiptLinesPanel(
          lines: lines,
          totals: totals,
          onAddLine: onAddLine,
          onLinesChanged: onLinesChanged,
        ),
      ],
    );
  }
}

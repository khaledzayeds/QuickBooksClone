import 'package:flutter/material.dart';

import '../../customers/data/models/customer_model.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_models.dart';
import 'invoice_header_panel.dart';
import 'invoice_lines_panel.dart';

class InvoiceBodyPanel extends StatelessWidget {
  const InvoiceBodyPanel({
    super.key,
    required this.customerField,
    required this.invoiceNumberField,
    required this.invoiceDateField,
    required this.dueDateField,
    required this.billingTermsField,
    required this.memoField,
    required this.lines,
    required this.totals,
    required this.customer,
    required this.onAddLine,
    required this.onLinesChanged,
  });

  final Widget customerField;
  final Widget invoiceNumberField;
  final Widget invoiceDateField;
  final Widget dueDateField;
  final Widget billingTermsField;
  final Widget memoField;
  final List<TransactionLineEntry> lines;
  final TransactionTotalsUiModel totals;
  final CustomerModel? customer;
  final VoidCallback onAddLine;
  final VoidCallback onLinesChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        InvoiceHeaderPanel(
          customerField: customerField,
          invoiceNumberField: invoiceNumberField,
          invoiceDateField: invoiceDateField,
          dueDateField: dueDateField,
          billingTermsField: billingTermsField,
          memoField: memoField,
          customer: customer,
        ),
        Divider(height: 1, color: theme.dividerColor),
        InvoiceLinesPanel(
          lines: lines,
          totals: totals,
          onAddLine: onAddLine,
          onLinesChanged: onLinesChanged,
        ),
      ],
    );
  }
}

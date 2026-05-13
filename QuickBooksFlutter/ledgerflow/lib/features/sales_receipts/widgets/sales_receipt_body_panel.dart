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
    this.customer,
    this.readOnly = false,
    this.saving = false,
    this.onSaveAndClose,
    this.onSaveAndNew,
    this.onClear,
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
  final CustomerModel? customer;
  final bool readOnly;
  final bool saving;
  final VoidCallback? onSaveAndClose;
  final VoidCallback? onSaveAndNew;
  final VoidCallback? onClear;

  final List<CustomerModel> customers;
  final List<AccountModel> accounts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SalesReceiptHeaderPanel(
          numberField: numberField,
          dateField: dateField,
          referenceField: referenceField,
          customerField: customerField,
          depositAccountField: depositAccountField,
          paymentMethodField: paymentMethodField,
          customer: customer,
        ),
        Expanded(
          child: SalesReceiptLinesPanel(
            lines: lines,
            totals: totals,
            referenceField: referenceField,
            onAddLine: onAddLine,
            onLinesChanged: onLinesChanged,
            readOnly: readOnly,
            saving: saving,
            onSaveAndClose: onSaveAndClose,
            onSaveAndNew: onSaveAndNew,
            onClear: onClear,
          ),
        ),
      ],
    );
  }
}

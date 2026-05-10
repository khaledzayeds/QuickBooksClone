import 'package:flutter/material.dart';

import '../../customers/data/models/customer_model.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_form_shell.dart';
import '../../transactions/widgets/transaction_models.dart';
import 'sales_receipt_body_panel.dart';
import 'sales_receipt_context_panel.dart';
import 'sales_receipt_form_actions.dart';

class SalesReceiptShell extends StatelessWidget {
  const SalesReceiptShell({
    super.key,
    required this.numberField,
    required this.dateField,
    required this.referenceField,
    required this.customerField,
    required this.depositAccountField,
    required this.paymentMethodField,
    required this.lines,
    required this.totals,
    required this.customer,
    required this.metrics,
    required this.activities,
    required this.loadingActivity,
    required this.warning,
    required this.referenceText,
    required this.saving,
    required this.onAddLine,
    required this.onLinesChanged,
    required this.onPrint,
    required this.onClear,
    required this.onSaveAndNew,
    required this.onSaveAndClose,
    required this.onClose,
  });

  final Widget numberField;
  final Widget dateField;
  final Widget referenceField;
  final Widget customerField;
  final Widget depositAccountField;
  final Widget paymentMethodField;
  final List<TransactionLineEntry> lines;
  final TransactionTotalsUiModel totals;
  final CustomerModel? customer;
  final List<TransactionContextMetric> metrics;
  final List<TransactionContextActivity> activities;
  final bool loadingActivity;
  final String? warning;
  final String? referenceText;
  final bool saving;
  final VoidCallback onAddLine;
  final VoidCallback onLinesChanged;
  final VoidCallback onPrint;
  final VoidCallback onClear;
  final VoidCallback onSaveAndNew;
  final VoidCallback onSaveAndClose;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return TransactionFormShell(
      title: 'New Sales Receipt',
      breadcrumb: 'Sales / Receipts / New',
      onBack: onClose,
      shortcuts: TransactionFormShortcutSet(
        onSaveAndNew: saving ? null : onSaveAndNew,
        onSaveAndClose: saving ? null : onSaveAndClose,
        onPrint: onPrint,
        onClose: onClose,
      ),
      actions: buildSalesReceiptFormActions(
        saving: saving,
        onPrint: onPrint,
        onClear: onClear,
        onSaveAndNew: onSaveAndNew,
        onSaveAndClose: onSaveAndClose,
      ),
      body: SalesReceiptBodyPanel(
        numberField: numberField,
        dateField: dateField,
        referenceField: referenceField,
        customerField: customerField,
        depositAccountField: depositAccountField,
        paymentMethodField: paymentMethodField,
        lines: lines,
        totals: totals,
        onAddLine: onAddLine,
        onLinesChanged: onLinesChanged,
      ),
      sidebar: buildSalesReceiptContextPanel(
        customer: customer,
        metrics: metrics,
        activities: activities,
        totals: totals,
        isLoading: loadingActivity,
        warning: warning,
        referenceText: referenceText,
      ),
    );
  }
}

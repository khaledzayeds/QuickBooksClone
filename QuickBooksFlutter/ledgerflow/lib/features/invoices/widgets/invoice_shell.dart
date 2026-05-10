import 'package:flutter/material.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../customers/data/models/customer_model.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_form_shell.dart';
import '../../transactions/widgets/transaction_models.dart';
import 'invoice_body_panel.dart';
import 'invoice_context_panel.dart';
import 'invoice_form_actions.dart';

class InvoiceShell extends StatelessWidget {
  const InvoiceShell({
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
    required this.metrics,
    required this.activities,
    required this.loadingActivity,
    required this.warning,
    required this.memoText,
    required this.saving,
    required this.posting,
    required this.onAddLine,
    required this.onLinesChanged,
    required this.onSaveDraft,
    required this.onSave,
    required this.onPost,
    required this.onPrint,
    required this.onVoid,
    required this.onClose,
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
  final List<TransactionContextMetric> metrics;
  final List<TransactionContextActivity> activities;
  final bool loadingActivity;
  final String? warning;
  final String? memoText;
  final bool saving;
  final bool posting;
  final VoidCallback onAddLine;
  final VoidCallback onLinesChanged;
  final VoidCallback onSaveDraft;
  final VoidCallback onSave;
  final VoidCallback onPost;
  final VoidCallback onPrint;
  final VoidCallback onVoid;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = saving || posting;

    return TransactionFormShell(
      title: l10n.newInvoice,
      breadcrumb: 'Sales / Invoices / New',
      onBack: onClose,
      shortcuts: TransactionFormShortcutSet(
        onSaveAndNew: null,
        onSaveAndClose: busy ? null : onSave,
        onPrint: onPrint,
        onClose: onClose,
      ),
      actions: buildInvoiceFormActions(
        saving: saving,
        posting: posting,
        onSaveDraft: onSaveDraft,
        onSave: onSave,
        onPost: onPost,
        onPrint: onPrint,
        onVoid: onVoid,
      ),
      body: InvoiceBodyPanel(
        customerField: customerField,
        invoiceNumberField: invoiceNumberField,
        invoiceDateField: invoiceDateField,
        dueDateField: dueDateField,
        billingTermsField: billingTermsField,
        memoField: memoField,
        lines: lines,
        totals: totals,
        onAddLine: onAddLine,
        onLinesChanged: onLinesChanged,
      ),
      sidebar: buildInvoiceContextPanel(
        customer: customer,
        metrics: metrics,
        activities: activities,
        totals: totals,
        isLoading: loadingActivity,
        warning: warning,
        memoText: memoText,
      ),
    );
  }
}

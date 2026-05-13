import 'package:flutter/material.dart';

import '../../customers/data/models/customer_model.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_models.dart';
import 'sales_receipt_body_panel.dart';
import 'sales_receipt_context_panel.dart';

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
    required this.isEdit,
    required this.readOnly,
    required this.onAddLine,
    required this.onLinesChanged,
    required this.onFind,
    required this.onPrint,
    this.onVoid,
    required this.onClear,
    this.onSaveAndNew,
    this.onSaveAndClose,
    required this.onClose,
    this.onViewAll,
    this.onEditNotes,
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
  final bool isEdit;
  final bool readOnly;
  final VoidCallback onAddLine;
  final VoidCallback onLinesChanged;
  final VoidCallback onFind;
  final VoidCallback onPrint;
  final VoidCallback? onVoid;
  final VoidCallback onClear;
  final VoidCallback? onSaveAndNew;
  final VoidCallback? onSaveAndClose;
  final VoidCallback onClose;
  final VoidCallback? onViewAll;
  final VoidCallback? onEditNotes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: SafeArea(
        child: Column(
          children: [
            _CommandBar(
              saving: saving,
              readOnly: readOnly,
              isEdit: isEdit,
              onFind: onFind,
              onNew: onClear,
              onSave: onSaveAndClose,
              onSaveNew: onSaveAndNew,
              onPrint: onPrint,
              onVoid: onVoid,
              onClear: onClear,
              onClose: onClose,
              onNotes: onEditNotes,
            ),
            if (readOnly)
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                color: const Color(0xFFFFE8BF),
                child: Text(
                  'Saved sales receipts are read-only. Available actions remain enabled in the toolbar.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF6B4300),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(10, 8, 0, 8),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border.all(color: const Color(0xFFB9C3CA)),
                      ),
                      child: SalesReceiptBodyPanel(
                        numberField: numberField,
                        dateField: dateField,
                        referenceField: referenceField,
                        customerField: customerField,
                        depositAccountField: depositAccountField,
                        paymentMethodField: paymentMethodField,
                        lines: lines,
                        totals: totals,
                        customer: customer,
                        onAddLine: onAddLine,
                        onLinesChanged: onLinesChanged,
                        readOnly: readOnly,
                        saving: saving,
                        onSaveAndClose: onSaveAndClose,
                        onSaveAndNew: onSaveAndNew,
                        onClear: onClear,
                      ),
                    ),
                  ),
                  Container(
                    width: 258,
                    margin: const EdgeInsets.fromLTRB(8, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      border: Border.all(color: const Color(0xFFB9C3CA)),
                    ),
                    child: buildSalesReceiptContextPanel(
                      customer: customer,
                      metrics: metrics,
                      activities: activities,
                      totals: totals,
                      isLoading: loadingActivity,
                      warning: warning,
                      referenceText: referenceText,
                      onViewAll: onViewAll,
                      onEditNotes: onEditNotes,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              color: const Color(0xFFD4DDE3),
              child: Text(
                'Sales receipt workspace  •  F2 Save & New  •  F4 Save & Close  •  Ctrl+P Print  •  Esc Close',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF33434C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandBar extends StatelessWidget {
  const _CommandBar({
    required this.saving,
    required this.readOnly,
    required this.isEdit,
    required this.onFind,
    required this.onNew,
    required this.onSave,
    required this.onSaveNew,
    required this.onPrint,
    required this.onVoid,
    required this.onClear,
    required this.onClose,
    this.onNotes,
  });

  final bool saving;
  final bool readOnly;
  final bool isEdit;
  final VoidCallback onFind;
  final VoidCallback onNew;
  final VoidCallback? onSave;
  final VoidCallback? onSaveNew;
  final VoidCallback onPrint;
  final VoidCallback? onVoid;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final VoidCallback? onNotes;

  @override
  Widget build(BuildContext context) {
    final canSave = !saving && !readOnly;
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F6F7),
        border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _Tool(icon: Icons.search, label: 'Find', onTap: saving ? null : onFind),
          _Tool(icon: Icons.note_add_outlined, label: 'New', onTap: saving ? null : onNew),
          _Tool(icon: Icons.save_outlined, label: saving ? 'Saving' : 'Save', onTap: canSave ? onSave : null),
          _Tool(icon: Icons.add_circle_outline, label: 'Save New', onTap: canSave ? onSaveNew : null),
          _Tool(icon: Icons.delete_outline, label: isEdit ? 'Void' : 'Clear', onTap: isEdit ? onVoid : (saving ? null : onClear)),
          const _Sep(),
          _Tool(icon: Icons.print_outlined, label: 'Print', onTap: saving ? null : onPrint),
          const _Tool(icon: Icons.email_outlined, label: 'Email'),
          _Tool(icon: Icons.attach_file, label: 'Notes', onTap: onNotes),
          const _Sep(),
          const _Tool(icon: Icons.assignment_return_outlined, label: 'Refund'),
          const _Tool(icon: Icons.payments_outlined, label: 'Deposit'),
          const Spacer(),
          _Tool(icon: Icons.close, label: 'Close', onTap: saving ? null : onClose),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: enabled ? const Color(0xFF234C5D) : const Color(0xFF7D8B93)),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: enabled ? const Color(0xFF273A43) : const Color(0xFF7D8B93),
                fontWeight: enabled ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFC7D0D6),
    );
  }
}

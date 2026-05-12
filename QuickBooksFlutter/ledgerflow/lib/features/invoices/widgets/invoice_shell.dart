import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../customers/data/models/customer_model.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_models.dart';
import 'invoice_context_panel.dart';
import 'invoice_header_panel.dart';
import 'invoice_lines_panel.dart';

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
    required this.isEdit,
    required this.onAddLine,
    required this.onLinesChanged,
    required this.onSaveDraft,
    required this.onSave,
    this.onSaveAndNew,
    required this.onPost,
    required this.onPrint,
    required this.onVoid,
    this.onClear,
    required this.onClose,
    this.onViewAll,
    this.onEditNotes,
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
  final bool isEdit;
  final VoidCallback onAddLine;
  final VoidCallback onLinesChanged;
  final VoidCallback onSaveDraft;
  final VoidCallback onSave;
  final VoidCallback? onSaveAndNew;
  final VoidCallback onPost;
  final VoidCallback onPrint;
  final VoidCallback onVoid;
  final VoidCallback? onClear;
  final VoidCallback onClose;
  final VoidCallback? onViewAll;
  final VoidCallback? onEditNotes;

  @override
  Widget build(BuildContext context) {
    final busy = saving || posting;
    final cs = Theme.of(context).colorScheme;
    final clearAction = onClear ?? onClose;
    final saveAndNewAction = onSaveAndNew ?? onSaveDraft;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: SafeArea(
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.escape): _CloseInvoiceIntent(),
            SingleActivator(LogicalKeyboardKey.keyP, control: true): _PrintInvoiceIntent(),
            SingleActivator(LogicalKeyboardKey.f4): _SaveInvoiceIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _CloseInvoiceIntent: CallbackAction<_CloseInvoiceIntent>(onInvoke: (_) {
                onClose();
                return null;
              }),
              _PrintInvoiceIntent: CallbackAction<_PrintInvoiceIntent>(onInvoke: (_) {
                if (!busy) onPrint();
                return null;
              }),
              _SaveInvoiceIntent: CallbackAction<_SaveInvoiceIntent>(onInvoke: (_) {
                if (!busy) onSave();
                return null;
              }),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                children: [
                  _QuickBooksMenuBar(onClose: onClose),
                  _InvoiceCommandBar(
                    saving: saving,
                    posting: posting,
                    isEdit: isEdit,
                    onNew: clearAction,
                    onSaveDraft: onSaveDraft,
                    onSave: onSave,
                    onPost: onPost,
                    onPrint: onPrint,
                    onVoid: onVoid,
                    onClear: clearAction,
                    onClose: onClose,
                    onEditNotes: onEditNotes,
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
                            child: Column(
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
                                Expanded(
                                  child: InvoiceLinesPanel(
                                    lines: lines,
                                    totals: totals,
                                    onAddLine: onAddLine,
                                    onLinesChanged: onLinesChanged,
                                    memoField: memoField,
                                    saving: saving,
                                    posting: posting,
                                    onSaveAndClose: onSave,
                                    onSaveAndNew: saveAndNewAction,
                                    onClear: clearAction,
                                  ),
                                ),
                              ],
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
                          child: buildInvoiceContextPanel(
                            customer: customer,
                            metrics: metrics,
                            activities: activities,
                            totals: totals,
                            isLoading: loadingActivity,
                            warning: warning,
                            memoText: memoText,
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4DDE3),
                      border: Border(top: BorderSide(color: Color(0xFFAFBBC4))),
                    ),
                    child: Text(
                      'Invoice workspace  •  F4 Save  •  Ctrl+P Print  •  Esc Close',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF33434C),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickBooksMenuBar extends StatelessWidget {
  const _QuickBooksMenuBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        );

    return Container(
      height: 30,
      color: const Color(0xFF243F4C),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          for (final label in const ['File', 'Edit', 'View', 'Lists', 'Favorites', 'Company', 'Customers', 'Vendors', 'Employees', 'Banking', 'Reports', 'Help'])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 18),
              child: Text(label, style: style),
            ),
          const Spacer(),
          InkWell(
            onTap: onClose,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('Close', style: style),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCommandBar extends StatelessWidget {
  const _InvoiceCommandBar({
    required this.saving,
    required this.posting,
    required this.isEdit,
    required this.onNew,
    required this.onSaveDraft,
    required this.onSave,
    required this.onPost,
    required this.onPrint,
    required this.onVoid,
    required this.onClear,
    required this.onClose,
    this.onEditNotes,
  });

  final bool saving;
  final bool posting;
  final bool isEdit;
  final VoidCallback onNew;
  final VoidCallback onSaveDraft;
  final VoidCallback onSave;
  final VoidCallback onPost;
  final VoidCallback onPrint;
  final VoidCallback onVoid;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final VoidCallback? onEditNotes;

  @override
  Widget build(BuildContext context) {
    final busy = saving || posting;
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F6F7),
        border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _ToolAction(icon: Icons.search, label: 'Find'),
          _ToolAction(icon: Icons.note_add_outlined, label: 'New', onTap: busy ? null : onNew),
          _ToolAction(icon: Icons.save_outlined, label: saving ? 'Saving' : 'Save', onTap: busy ? null : onSave),
          _ToolAction(icon: Icons.drafts_outlined, label: 'Draft', onTap: busy ? null : onSaveDraft),
          _ToolAction(icon: Icons.delete_outline, label: isEdit ? 'Void' : 'Clear', onTap: isEdit ? onVoid : onClear),
          const _CommandSeparator(),
          _ToolAction(icon: Icons.print_outlined, label: 'Print', onTap: busy ? null : onPrint),
          _ToolAction(icon: Icons.email_outlined, label: 'Email'),
          _ToolAction(icon: Icons.attach_file, label: 'Attach', onTap: onEditNotes),
          const _CommandSeparator(),
          _ToolAction(icon: Icons.payments_outlined, label: 'Payments'),
          _ToolAction(icon: Icons.assignment_return_outlined, label: 'Refund'),
          const Spacer(),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: FilledButton.icon(
              onPressed: busy ? null : onPost,
              icon: posting
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.task_alt_outlined, size: 16),
              label: Text(posting ? 'Posting...' : 'Post Invoice'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolAction extends StatelessWidget {
  const _ToolAction({required this.icon, required this.label, this.onTap});

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
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandSeparator extends StatelessWidget {
  const _CommandSeparator();

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

class _CloseInvoiceIntent extends Intent {
  const _CloseInvoiceIntent();
}

class _PrintInvoiceIntent extends Intent {
  const _PrintInvoiceIntent();
}

class _SaveInvoiceIntent extends Intent {
  const _SaveInvoiceIntent();
}

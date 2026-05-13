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
    this.statusBadgeText,
    this.statusMessage,
    this.statusColor,
    required this.memoText,
    required this.saving,
    required this.posting,
    required this.isEdit,
    required this.readOnly,
    required this.onAddLine,
    required this.onLinesChanged,
    required this.onFind,
    this.onPrevious,
    this.onNext,
    this.onSaveDraft,
    this.onSave,
    required this.onSaveAndPrint,
    this.onSaveAndNew,
    this.onPost,
    required this.onPrint,
    required this.onPayment,
    required this.onRefund,
    this.onVoid,
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
  final String? statusBadgeText;
  final String? statusMessage;
  final Color? statusColor;
  final String? memoText;
  final bool saving;
  final bool posting;
  final bool isEdit;
  final bool readOnly;
  final VoidCallback onAddLine;
  final VoidCallback onLinesChanged;
  final VoidCallback onFind;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSave;
  final VoidCallback onSaveAndPrint;
  final VoidCallback? onSaveAndNew;
  final VoidCallback? onPost;
  final VoidCallback onPrint;
  final VoidCallback onPayment;
  final VoidCallback onRefund;
  final VoidCallback? onVoid;
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
            SingleActivator(LogicalKeyboardKey.f2):
                _SaveAndPrintInvoiceIntent(),
            SingleActivator(LogicalKeyboardKey.keyP, control: true):
                _PrintInvoiceIntent(),
            SingleActivator(LogicalKeyboardKey.f4): _SaveInvoiceIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _CloseInvoiceIntent: CallbackAction<_CloseInvoiceIntent>(
                onInvoke: (_) {
                  onClose();
                  return null;
                },
              ),
              _PrintInvoiceIntent: CallbackAction<_PrintInvoiceIntent>(
                onInvoke: (_) {
                  if (!busy) onPrint();
                  return null;
                },
              ),
              _SaveInvoiceIntent: CallbackAction<_SaveInvoiceIntent>(
                onInvoke: (_) {
                  if (!busy) onPost?.call();
                  return null;
                },
              ),
              _SaveAndPrintInvoiceIntent:
                  CallbackAction<_SaveAndPrintInvoiceIntent>(
                    onInvoke: (_) {
                      if (!busy) onSaveAndPrint();
                      return null;
                    },
                  ),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                children: [
                  _InvoiceCommandBar(
                    saving: saving,
                    posting: posting,
                    isEdit: isEdit,
                    readOnly: readOnly,
                    onFind: onFind,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onNew: clearAction,
                    onSaveDraft: onSaveDraft,
                    onSave: onPost,
                    onSaveAndPrint: onSaveAndPrint,
                    onPrint: onPrint,
                    onPayment: onPayment,
                    onRefund: onRefund,
                    onVoid: onVoid,
                    onClear: clearAction,
                    onClose: onClose,
                    onEditNotes: onEditNotes,
                  ),
                  if (statusMessage != null && statusBadgeText != null)
                    _InvoiceStatusStrip(
                      badgeText: statusBadgeText!,
                      message: statusMessage!,
                      color: statusColor ?? const Color(0xFF546E7A),
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
                              border: Border.all(
                                color: const Color(0xFFB9C3CA),
                              ),
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
                                    readOnly: readOnly,
                                    onSaveAndClose: onPost,
                                    onSaveAndNew: saveAndNewAction,
                                    onClear: clearAction,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _CollapsibleInvoiceContextPanel(
                          child: buildInvoiceContextPanel(
                            customer: customer,
                            metrics: metrics,
                            activities: activities,
                            totals: totals,
                            isLoading: loadingActivity,
                            warning: warning,
                            notesText: memoText,
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
                      'Invoice workspace  •  F2 Save & Print  •  F4 Save  •  Ctrl+P Print  •  Esc Close',
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

class _CollapsibleInvoiceContextPanel extends StatefulWidget {
  const _CollapsibleInvoiceContextPanel({required this.child});

  final Widget child;

  @override
  State<_CollapsibleInvoiceContextPanel> createState() =>
      _CollapsibleInvoiceContextPanelState();
}

class _CollapsibleInvoiceContextPanelState
    extends State<_CollapsibleInvoiceContextPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: _expanded ? 258 : 38,
      margin: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: const Color(0xFFB9C3CA)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (_expanded) Positioned.fill(child: widget.child),
          Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: const Color(0xFFE6EEF2),
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Tooltip(
                  message: _expanded ? 'Hide side panel' : 'Show side panel',
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      _expanded ? Icons.chevron_right : Icons.chevron_left,
                      size: 22,
                      color: const Color(0xFF2B4A56),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceStatusStrip extends StatelessWidget {
  const _InvoiceStatusStrip({
    required this.badgeText,
    required this.message,
    required this.color,
  });

  final String badgeText;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.35)),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              badgeText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
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
    required this.readOnly,
    required this.onFind,
    this.onPrevious,
    this.onNext,
    required this.onNew,
    this.onSaveDraft,
    this.onSave,
    required this.onSaveAndPrint,
    required this.onPrint,
    required this.onPayment,
    required this.onRefund,
    this.onVoid,
    required this.onClear,
    required this.onClose,
    this.onEditNotes,
  });

  final bool saving;
  final bool posting;
  final bool isEdit;
  final bool readOnly;
  final VoidCallback onFind;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onNew;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSave;
  final VoidCallback onSaveAndPrint;
  final VoidCallback onPrint;
  final VoidCallback onPayment;
  final VoidCallback onRefund;
  final VoidCallback? onVoid;
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
          _ToolAction(
            icon: Icons.arrow_back,
            label: 'Prev',
            onTap: busy ? null : onPrevious,
          ),
          _ToolAction(
            icon: Icons.arrow_forward,
            label: 'Next',
            onTap: busy ? null : onNext,
          ),
          _ToolAction(
            icon: Icons.search,
            label: 'Find',
            onTap: busy ? null : onFind,
          ),
          _ToolAction(
            icon: Icons.note_add_outlined,
            label: 'New',
            onTap: busy ? null : onNew,
          ),
          _SaveToolAction(
            saving: saving,
            posting: posting,
            onSave: onSave,
            onSaveAndPrint: onSaveAndPrint,
            onSaveDraft: onSaveDraft,
          ),
          _ToolAction(
            icon: Icons.drafts_outlined,
            label: 'Draft',
            onTap: busy ? null : onSaveDraft,
          ),
          _ToolAction(
            icon: Icons.delete_outline,
            label: isEdit ? 'Void' : 'Clear',
            onTap: busy
                ? null
                : isEdit
                ? onVoid
                : onClear,
          ),
          const _CommandSeparator(),
          _ToolAction(
            icon: Icons.print_outlined,
            label: 'Print',
            onTap: busy ? null : onPrint,
          ),
          _ToolAction(icon: Icons.email_outlined, label: 'Email'),
          _ToolAction(
            icon: Icons.sticky_note_2_outlined,
            label: 'Notes',
            onTap: onEditNotes,
          ),
          const _CommandSeparator(),
          _ToolAction(
            icon: Icons.payments_outlined,
            label: 'Payments',
            onTap: busy ? null : onPayment,
          ),
          _ToolAction(
            icon: Icons.assignment_return_outlined,
            label: 'Refund',
            onTap: busy ? null : onRefund,
          ),
          const Spacer(),
          _ToolAction(
            icon: Icons.close,
            label: 'Close',
            onTap: busy ? null : onClose,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

enum _SaveMenuCommand { save, saveAndPrint, draft }

class _SaveToolAction extends StatelessWidget {
  const _SaveToolAction({
    required this.saving,
    required this.posting,
    required this.onSave,
    required this.onSaveAndPrint,
    required this.onSaveDraft,
  });

  final bool saving;
  final bool posting;
  final VoidCallback? onSave;
  final VoidCallback onSaveAndPrint;
  final VoidCallback? onSaveDraft;

  @override
  Widget build(BuildContext context) {
    final busy = saving || posting;
    final enabled = !busy && onSave != null;
    final label = posting
        ? 'Posting'
        : saving
        ? 'Saving'
        : 'Save';
    final enabledColor = enabled
        ? const Color(0xFF234C5D)
        : const Color(0xFF7D8B93);

    if (busy) {
      return SizedBox(
        width: 64,
        height: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: enabledColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: enabledColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<_SaveMenuCommand>(
      tooltip: 'Save options',
      enabled: enabled,
      onSelected: (command) {
        switch (command) {
          case _SaveMenuCommand.save:
            onSave?.call();
            break;
          case _SaveMenuCommand.saveAndPrint:
            onSaveAndPrint();
            break;
          case _SaveMenuCommand.draft:
            onSaveDraft?.call();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _SaveMenuCommand.save, child: Text('Save')),
        PopupMenuItem(
          value: _SaveMenuCommand.saveAndPrint,
          child: Text('Save & Print'),
        ),
        PopupMenuItem(
          value: _SaveMenuCommand.draft,
          child: Text('Save as Draft'),
        ),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          hoverColor: enabled ? const Color(0xFFDCEBF0) : Colors.transparent,
          child: SizedBox(
            width: 64,
            height: 74,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_outlined, size: 22, color: enabledColor),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Save',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: enabledColor,
                        fontWeight: enabled ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 14, color: enabledColor),
                  ],
                ),
              ],
            ),
          ),
        ),
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
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 450),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: enabled ? const Color(0xFFDCEBF0) : Colors.transparent,
          splashColor: enabled ? const Color(0xFFBFD7E0) : Colors.transparent,
          child: SizedBox(
            width: 64,
            height: 74,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: enabled
                      ? const Color(0xFF234C5D)
                      : const Color(0xFF7D8B93),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: enabled
                        ? const Color(0xFF273A43)
                        : const Color(0xFF7D8B93),
                    fontWeight: enabled ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
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

class _SaveAndPrintInvoiceIntent extends Intent {
  const _SaveAndPrintInvoiceIntent();
}

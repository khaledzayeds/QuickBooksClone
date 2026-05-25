import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransactionWorkspaceShell extends StatelessWidget {
  const TransactionWorkspaceShell({
    super.key,
    required this.formContent,
    this.contextPanel,
    this.statusBadgeText,
    this.statusMessage,
    this.statusColor,
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
    this.onSaveAndPrint,
    this.onSaveAndNew,
    this.onPrint,
    this.onPayment,
    this.onRefund,
    this.onReceive,
    this.onVoid,
    this.onClear,
    required this.onClose,
    this.onEmail,
    this.onEditNotes,
    required this.workspaceName,
    this.showPagination = true,
    this.showSaveDraft = true,
    this.showSaveAndPrint = true,
    this.showPrint = true,
    this.showEmail = true,
    this.showEditNotes = true,
    this.showPayment = false,
    this.showRefund = false,
    this.showReceive = false,
    this.showVoid = true,
    this.showClear = true,
  });

  /// The main form area (e.g. Header Panel + Lines Panel)
  final Widget formContent;

  /// The right side context panel. If null, no context panel is shown.
  final Widget? contextPanel;

  final String? statusBadgeText;
  final String? statusMessage;
  final Color? statusColor;

  final bool saving;
  final bool posting;
  final bool isEdit;
  final bool readOnly;

  final String workspaceName; // e.g. "Invoice workspace"

  final VoidCallback onFind;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onNew;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndPrint;
  final VoidCallback? onSaveAndNew;
  final VoidCallback? onPrint;
  final VoidCallback? onPayment;
  final VoidCallback? onRefund;
  final VoidCallback? onReceive;
  final VoidCallback? onVoid;
  final VoidCallback? onClear;
  final VoidCallback onClose;
  final VoidCallback? onEmail;
  final VoidCallback? onEditNotes;
  
  final bool showPagination;
  final bool showSaveDraft;
  final bool showSaveAndPrint;
  final bool showPrint;
  final bool showEmail;
  final bool showEditNotes;
  final bool showPayment;
  final bool showRefund;
  final bool showReceive;
  final bool showVoid;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    final busy = saving || posting;
    final cs = Theme.of(context).colorScheme;
    final clearAction = onClear ?? onClose;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: SafeArea(
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.escape):
                _CloseTransactionIntent(),
            SingleActivator(LogicalKeyboardKey.f2):
                _SaveAndPrintTransactionIntent(),
            SingleActivator(LogicalKeyboardKey.keyP, control: true):
                _PrintTransactionIntent(),
            SingleActivator(LogicalKeyboardKey.f4): _SaveTransactionIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _CloseTransactionIntent: CallbackAction<_CloseTransactionIntent>(
                onInvoke: (_) {
                  onClose();
                  return null;
                },
              ),
              _PrintTransactionIntent: CallbackAction<_PrintTransactionIntent>(
                onInvoke: (_) {
                  if (!busy) onPrint?.call();
                  return null;
                },
              ),
              _SaveTransactionIntent: CallbackAction<_SaveTransactionIntent>(
                onInvoke: (_) {
                  if (!busy) onSave?.call();
                  return null;
                },
              ),
              _SaveAndPrintTransactionIntent:
                  CallbackAction<_SaveAndPrintTransactionIntent>(
                    onInvoke: (_) {
                      if (!busy) onSaveAndPrint?.call();
                      return null;
                    },
                  ),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                children: [
                  TransactionCommandBar(
                    saving: saving,
                    posting: posting,
                    isEdit: isEdit,
                    readOnly: readOnly,
                    onFind: onFind,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onNew: clearAction,
                    onSaveDraft: onSaveDraft,
                    onSave: onSave,
                    onSaveAndPrint: onSaveAndPrint,
                    onSaveAndNew: onSaveAndNew,
                    onPrint: onPrint,
                    onEmail: onEmail,
                    onEditNotes: onEditNotes,
                    onPayment: onPayment,
                    onRefund: onRefund,
                    onReceive: onReceive,
                    onVoid: onVoid,
                    onClear: clearAction,
                    onClose: onClose,
                    showPagination: showPagination,
                    showSaveDraft: showSaveDraft,
                    showSaveAndPrint: showSaveAndPrint,
                    showPrint: showPrint,
                    showEmail: showEmail,
                    showEditNotes: showEditNotes,
                    showPayment: showPayment,
                    showRefund: showRefund,
                    showReceive: showReceive,
                    showVoid: showVoid,
                    showClear: showClear,
                  ),
                  if (statusMessage != null && statusBadgeText != null)
                    TransactionStatusStrip(
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
                            margin: EdgeInsets.fromLTRB(
                              10,
                              8,
                              contextPanel == null ? 10 : 0,
                              8,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              border: Border.all(
                                color: const Color(0xFFB9C3CA),
                              ),
                            ),
                            child: formContent,
                          ),
                        ),
                        if (contextPanel != null)
                          CollapsibleContextPanel(child: contextPanel!),
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
                      '$workspaceName  •  F2 Save & Print  •  F4 Save  •  Ctrl+P Print  •  Esc Close',
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

class CollapsibleContextPanel extends StatefulWidget {
  const CollapsibleContextPanel({super.key, required this.child});

  final Widget child;

  @override
  State<CollapsibleContextPanel> createState() =>
      _CollapsibleContextPanelState();
}

class _CollapsibleContextPanelState extends State<CollapsibleContextPanel> {
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

class TransactionStatusStrip extends StatelessWidget {
  const TransactionStatusStrip({
    super.key,
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
        border: Border(bottom: BorderSide(color: color.withOpacity(0.35))),
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

class TransactionCommandBar extends StatelessWidget {
  const TransactionCommandBar({
    super.key,
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
    this.onSaveAndPrint,
    this.onSaveAndNew,
    this.onPrint,
    this.onEmail,
    this.onEditNotes,
    this.onPayment,
    this.onRefund,
    this.onReceive,
    this.onVoid,
    required this.onClear,
    required this.onClose,
    required this.showPagination,
    required this.showSaveDraft,
    required this.showSaveAndPrint,
    required this.showPrint,
    required this.showEmail,
    required this.showEditNotes,
    required this.showPayment,
    required this.showRefund,
    required this.showReceive,
    required this.showVoid,
    required this.showClear,
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
  final VoidCallback? onSaveAndPrint;
  final VoidCallback? onSaveAndNew;
  final VoidCallback? onPrint;
  final VoidCallback? onEmail;
  final VoidCallback? onEditNotes;
  final VoidCallback? onPayment;
  final VoidCallback? onRefund;
  final VoidCallback? onReceive;
  final VoidCallback? onVoid;
  final VoidCallback onClear;
  final VoidCallback onClose;

  final bool showPagination;
  final bool showSaveDraft;
  final bool showSaveAndPrint;
  final bool showPrint;
  final bool showEmail;
  final bool showEditNotes;
  final bool showPayment;
  final bool showRefund;
  final bool showReceive;
  final bool showVoid;
  final bool showClear;

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
          if (onPrevious != null || onNext != null) ...[
            TransactionToolAction(
              icon: Icons.arrow_back,
              label: 'Prev',
              onTap: busy ? null : onPrevious,
            ),
            TransactionToolAction(
              icon: Icons.arrow_forward,
              label: 'Next',
              onTap: busy ? null : onNext,
            ),
          ],
          TransactionToolAction(
            icon: Icons.search,
            label: 'Find',
            onTap: busy ? null : onFind,
          ),
          TransactionToolAction(
            icon: Icons.note_add_outlined,
            label: 'New',
            onTap: busy ? null : onNew,
          ),
          if (onSave != null || onSaveDraft != null || onSaveAndPrint != null || onSaveAndNew != null)
            _SaveToolAction(
              saving: saving,
              posting: posting,
              onSave: onSave,
              onSaveAndPrint: onSaveAndPrint,
              onSaveAndNew: onSaveAndNew,
              onSaveDraft: onSaveDraft,
            ),
          if (onSaveDraft != null)
            TransactionToolAction(
              icon: Icons.drafts_outlined,
              label: 'Draft',
              onTap: busy ? null : onSaveDraft,
            ),
          if (showVoid || showClear)
            TransactionToolAction(
              icon: Icons.delete_outline,
              label: isEdit ? 'Void' : 'Clear',
              onTap: busy
                  ? null
                  : isEdit
                  ? onVoid
                  : onClear,
            ),
          const _CommandSeparator(),
          if (showPrint)
            TransactionToolAction(
              icon: Icons.print_outlined,
              label: 'Print',
              onTap: busy ? null : onPrint,
            ),
          if (showEmail)
            TransactionToolAction(
              icon: Icons.email_outlined,
              label: 'Email',
              onTap: busy ? null : onEmail,
            ),
          if (showEditNotes)
            TransactionToolAction(
              icon: Icons.sticky_note_2_outlined,
              label: 'Notes',
              onTap: busy ? null : onEditNotes,
            ),
          if (showPayment || showRefund) ...[
            const _CommandSeparator(),
            if (showPayment)
              TransactionToolAction(
                icon: Icons.payments_outlined,
                label: 'Payments',
                onTap: busy ? null : onPayment,
              ),
            if (showRefund)
              TransactionToolAction(
                icon: Icons.assignment_return_outlined,
                label: 'Refund',
                onTap: busy ? null : onRefund,
              ),
            if (showReceive)
              TransactionToolAction(
                icon: Icons.inventory_2_outlined,
                label: 'Receive',
                onTap: busy ? null : onReceive,
              ),
          ],
          const Spacer(),
          TransactionToolAction(
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

enum _SaveMenuCommand { save, saveAndPrint, saveAndNew, draft }

class _SaveToolAction extends StatelessWidget {
  const _SaveToolAction({
    required this.saving,
    required this.posting,
    this.onSave,
    this.onSaveAndPrint,
    this.onSaveAndNew,
    this.onSaveDraft,
  });

  final bool saving;
  final bool posting;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndPrint;
  final VoidCallback? onSaveAndNew;
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
            onSaveAndPrint?.call();
            break;
          case _SaveMenuCommand.saveAndNew:
            onSaveAndNew?.call();
            break;
          case _SaveMenuCommand.draft:
            onSaveDraft?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _SaveMenuCommand.save,
          child: Text('Save'),
        ),
        if (onSaveAndPrint != null)
          const PopupMenuItem(
            value: _SaveMenuCommand.saveAndPrint,
            child: Text('Save & Print'),
          ),
        if (onSaveAndNew != null)
          const PopupMenuItem(
            value: _SaveMenuCommand.saveAndNew,
            child: Text('Save & New'),
          ),
        if (onSaveDraft != null)
          const PopupMenuItem(
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

class TransactionToolAction extends StatelessWidget {
  const TransactionToolAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

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

class _CloseTransactionIntent extends Intent {
  const _CloseTransactionIntent();
}

class _PrintTransactionIntent extends Intent {
  const _PrintTransactionIntent();
}

class _SaveTransactionIntent extends Intent {
  const _SaveTransactionIntent();
}

class _SaveAndPrintTransactionIntent extends Intent {
  const _SaveAndPrintTransactionIntent();
}

import 'package:flutter/material.dart';

class TransactionWorkspaceStatePolicy {
  const TransactionWorkspaceStatePolicy({
    this.financialReadOnly = false,
    this.canSave = true,
    this.canSaveDraft = true,
    this.canPrint = true,
    this.canVoid = false,
    this.canReceivePayment = false,
    this.canRefund = false,
    this.canEditNotes = true,
    this.reason,
  });

  final bool financialReadOnly;
  final bool canSave;
  final bool canSaveDraft;
  final bool canPrint;
  final bool canVoid;
  final bool canReceivePayment;
  final bool canRefund;
  final bool canEditNotes;
  final String? reason;

  bool get isFullyEditable => !financialReadOnly && canSave;
}

class TransactionWorkspaceAction {
  const TransactionWorkspaceAction({
    required this.label,
    required this.icon,
    this.onPressed,
    this.enabled = true,
    this.busy = false,
    this.tooltip,
    this.separatorAfter = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool busy;
  final String? tooltip;
  final bool separatorAfter;

  bool get active => enabled && onPressed != null && !busy;
}

class TransactionWorkspaceFrame extends StatefulWidget {
  const TransactionWorkspaceFrame({
    super.key,
    required this.commandBar,
    required this.body,
    this.contextPanel,
    this.footerText,
    this.panelExpandedWidth = 258,
    this.panelCollapsedWidth = 38,
  });

  final Widget commandBar;
  final Widget body;
  final Widget? contextPanel;
  final String? footerText;
  final double panelExpandedWidth;
  final double panelCollapsedWidth;

  @override
  State<TransactionWorkspaceFrame> createState() =>
      _TransactionWorkspaceFrameState();
}

class _TransactionWorkspaceFrameState extends State<TransactionWorkspaceFrame> {
  bool _panelExpanded = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final panel = widget.contextPanel;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: SafeArea(
        child: Column(
          children: [
            widget.commandBar,
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: widget.body),
                  if (panel != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: _panelExpanded
                          ? widget.panelExpandedWidth
                          : widget.panelCollapsedWidth,
                      margin: const EdgeInsets.fromLTRB(8, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border.all(color: const Color(0xFFB9C3CA)),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          if (_panelExpanded) Positioned.fill(child: panel),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              color: const Color(0xFFE6EEF2),
                              child: InkWell(
                                onTap: () => setState(
                                  () => _panelExpanded = !_panelExpanded,
                                ),
                                child: Tooltip(
                                  message: _panelExpanded
                                      ? 'Hide side panel'
                                      : 'Show side panel',
                                  child: SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Icon(
                                      _panelExpanded
                                          ? Icons.chevron_right
                                          : Icons.chevron_left,
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
                    ),
                ],
              ),
            ),
            if (widget.footerText != null)
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4DDE3),
                  border: Border(top: BorderSide(color: Color(0xFFAFBBC4))),
                ),
                child: Text(
                  widget.footerText!,
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

class TransactionWorkspaceCommandBar extends StatelessWidget {
  const TransactionWorkspaceCommandBar({
    super.key,
    required this.actions,
    this.height = 74,
    this.leadingGap = 8,
  });

  final List<TransactionWorkspaceAction> actions;
  final double height;
  final double leadingGap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F6F7),
        border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          SizedBox(width: leadingGap),
          for (final action in actions) ...[
            _WorkspaceToolAction(action: action, height: height),
            if (action.separatorAfter) const _WorkspaceCommandSeparator(),
          ],
        ],
      ),
    );
  }
}

class TransactionWorkspaceReadOnlyBanner extends StatelessWidget {
  const TransactionWorkspaceReadOnlyBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE8BF),
        border: Border(bottom: BorderSide(color: Color(0xFFD0A760))),
      ),
      child: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF6B4300),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WorkspaceToolAction extends StatelessWidget {
  const _WorkspaceToolAction({required this.action, required this.height});

  final TransactionWorkspaceAction action;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = action.active;
    final fg = enabled ? const Color(0xFF234C5D) : const Color(0xFF7D8B93);

    return Tooltip(
      message: action.tooltip ?? action.label,
      waitDuration: const Duration(milliseconds: 450),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? action.onPressed : null,
          hoverColor: enabled ? const Color(0xFFDCEBF0) : Colors.transparent,
          splashColor: enabled ? const Color(0xFFBFD7E0) : Colors.transparent,
          child: SizedBox(
            width: 64,
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action.busy)
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                else
                  Icon(action.icon, size: 22, color: fg),
                const SizedBox(height: 5),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
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

class _WorkspaceCommandSeparator extends StatelessWidget {
  const _WorkspaceCommandSeparator();

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

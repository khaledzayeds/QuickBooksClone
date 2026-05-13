import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TransactionFormActionStyle { icon, text, outlined, filled }

class TransactionFormAction {
  const TransactionFormAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.style,
    this.filled = false,
    this.enabled = true,
    this.busy = false,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final TransactionFormActionStyle? style;
  final bool filled;
  final bool enabled;
  final bool busy;
  final String? tooltip;

  TransactionFormActionStyle get resolvedStyle {
    if (style != null) return style!;
    return filled
        ? TransactionFormActionStyle.filled
        : TransactionFormActionStyle.outlined;
  }
}

class TransactionFormShortcutSet {
  const TransactionFormShortcutSet({
    this.onSaveAndNew,
    this.onSaveAndClose,
    this.onPrint,
    this.onClose,
  });

  final VoidCallback? onSaveAndNew;
  final VoidCallback? onSaveAndClose;
  final VoidCallback? onPrint;
  final VoidCallback? onClose;
}

class TransactionFormShell extends StatefulWidget {
  const TransactionFormShell({
    super.key,
    required this.title,
    required this.breadcrumb,
    required this.body,
    this.sidebar,
    this.actions = const [],
    this.leading,
    this.onBack,
    this.shortcuts = const TransactionFormShortcutSet(),
    this.showSidebarMinWidth = 860,
    this.toolbarHeight = 48,
  });

  final String title;
  final String breadcrumb;
  final Widget body;
  final Widget? sidebar;
  final List<TransactionFormAction> actions;
  final Widget? leading;
  final VoidCallback? onBack;
  final TransactionFormShortcutSet shortcuts;
  final double showSidebarMinWidth;
  final double toolbarHeight;

  @override
  State<TransactionFormShell> createState() => _TransactionFormShellState();
}

class _TransactionFormShellState extends State<TransactionFormShell> {
  bool _contextPanelExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: _buildAppBar(context),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final showSidebar =
                widget.sidebar != null &&
                constraints.maxWidth >= widget.showSidebarMinWidth;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: widget.body),
                if (showSidebar) ...[
                  VerticalDivider(
                    width: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    width: _contextPanelExpanded ? 286 : 38,
                    child: _ContextPanelFrame(
                      expanded: _contextPanelExpanded,
                      onToggle: () => setState(
                        () => _contextPanelExpanded = !_contextPanelExpanded,
                      ),
                      child: widget.sidebar!,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final isCtrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (event.logicalKey == LogicalKeyboardKey.f2 &&
        widget.shortcuts.onSaveAndNew != null) {
      widget.shortcuts.onSaveAndNew!.call();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.f4 &&
        widget.shortcuts.onSaveAndClose != null) {
      widget.shortcuts.onSaveAndClose!.call();
      return KeyEventResult.handled;
    }
    if (isCtrl &&
        event.logicalKey == LogicalKeyboardKey.keyP &&
        widget.shortcuts.onPrint != null) {
      widget.shortcuts.onPrint!.call();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        widget.shortcuts.onClose != null) {
      widget.shortcuts.onClose!.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppBar(
      toolbarHeight: widget.toolbarHeight,
      backgroundColor: cs.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        children: [
          widget.leading ??
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 20),
                tooltip: 'Back / Close (Esc)',
              ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                widget.breadcrumb,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        for (final action in widget.actions) ...[
          _buildAction(context, action),
          const SizedBox(width: 8),
        ],
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: widget.onBack ?? widget.shortcuts.onClose,
          icon: const Icon(Icons.close, size: 20),
          tooltip: 'Close (Esc)',
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: cs.outlineVariant),
      ),
    );
  }

  Widget _buildAction(BuildContext context, TransactionFormAction action) {
    final cs = Theme.of(context).colorScheme;
    final enabled = action.enabled && !action.busy;
    final icon = action.busy
        ? const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(action.icon, size: 16);

    return switch (action.resolvedStyle) {
      TransactionFormActionStyle.icon => IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: enabled ? action.onPressed : null,
        icon: Icon(action.icon, size: 20),
        tooltip: action.tooltip ?? action.label,
      ),
      TransactionFormActionStyle.text => TextButton.icon(
        onPressed: enabled ? action.onPressed : null,
        icon: icon,
        label: Text(action.label),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      TransactionFormActionStyle.filled => FilledButton.icon(
        onPressed: enabled ? action.onPressed : null,
        icon: icon,
        label: Text(action.label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      TransactionFormActionStyle.outlined => OutlinedButton.icon(
        onPressed: enabled ? action.onPressed : null,
        icon: icon,
        label: Text(action.label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          side: BorderSide(color: cs.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    };
  }
}

class _ContextPanelFrame extends StatelessWidget {
  const _ContextPanelFrame({
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        if (expanded) Positioned.fill(child: child),
        Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: cs.surface,
            child: InkWell(
              onTap: onToggle,
              child: SizedBox(
                width: 38,
                height: 46,
                child: AnimatedRotation(
                  turns: expanded ? 0 : 0.5,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(Icons.chevron_right, size: 20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TransactionFormMainPanel extends StatelessWidget {
  const TransactionFormMainPanel({
    super.key,
    required this.header,
    required this.toolbar,
    required this.lines,
    required this.totals,
    this.headerPadding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
    this.toolbarPadding = const EdgeInsets.fromLTRB(16, 8, 16, 6),
    this.linesPadding = EdgeInsets.zero,
  });

  final Widget header;
  final Widget toolbar;
  final Widget lines;
  final Widget totals;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry toolbarPadding;
  final EdgeInsetsGeometry linesPadding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(color: cs.surface, padding: headerPadding, child: header),
        Divider(height: 1, color: Theme.of(context).dividerColor),
        Container(
          color: cs.surfaceContainerLowest,
          padding: toolbarPadding,
          child: toolbar,
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Padding(padding: linesPadding, child: lines),
              ),
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(top: BorderSide(color: cs.outlineVariant)),
                ),
                child: totals,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TransactionFormFieldLabel extends StatelessWidget {
  const TransactionFormFieldLabel({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 2, bottom: 4),
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(text: label),
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: cs.error),
                  ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

InputDecoration transactionCompactInputDecoration(
  ColorScheme cs, {
  String? hint,
  IconData? suffixIcon,
  IconData? prefixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
    filled: true,
    fillColor: cs.surface,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 16, color: cs.onSurfaceVariant),
    prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    suffixIcon: suffixIcon == null
        ? null
        : Icon(suffixIcon, size: 16, color: cs.onSurfaceVariant),
    suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
  );
}

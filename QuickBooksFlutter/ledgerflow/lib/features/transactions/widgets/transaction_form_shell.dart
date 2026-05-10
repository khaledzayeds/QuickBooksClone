import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransactionFormAction {
  const TransactionFormAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
    this.enabled = true,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;
  final bool enabled;
  final String? tooltip;
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

class TransactionFormShell extends StatelessWidget {
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
    this.showSidebarMinWidth = 1100,
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
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: _buildAppBar(context),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final showSidebar = sidebar != null && constraints.maxWidth >= showSidebarMinWidth;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: body),
                if (showSidebar) ...[
                  VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
                  sidebar!,
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
    final isCtrl = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;

    if (event.logicalKey == LogicalKeyboardKey.f2 && shortcuts.onSaveAndNew != null) {
      shortcuts.onSaveAndNew!.call();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.f4 && shortcuts.onSaveAndClose != null) {
      shortcuts.onSaveAndClose!.call();
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyP && shortcuts.onPrint != null) {
      shortcuts.onPrint!.call();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape && shortcuts.onClose != null) {
      shortcuts.onClose!.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: cs.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        children: [
          leading ??
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 20),
                tooltip: 'Back / Close (Esc)',
              ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(breadcrumb, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
      actions: [
        for (final action in actions) ...[
          if (action.filled)
            FilledButton.icon(
              onPressed: action.enabled ? action.onPressed : null,
              icon: Icon(action.icon, size: 16),
              label: Text(action.label),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: action.enabled ? action.onPressed : null,
              icon: Icon(action.icon, size: 16),
              label: Text(action.label),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                side: BorderSide(color: cs.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          const SizedBox(width: 8),
        ],
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onBack ?? shortcuts.onClose,
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
    this.linesPadding = const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
        Container(color: cs.surfaceContainerLowest, padding: toolbarPadding, child: toolbar),
        Expanded(
          child: Column(
            children: [
              Expanded(child: SingleChildScrollView(padding: linesPadding, child: lines)),
              Container(
                decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.outlineVariant))),
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
              style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
              children: [
                TextSpan(text: label),
                if (required) TextSpan(text: ' *', style: TextStyle(color: cs.error)),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 16, color: cs.onSurfaceVariant),
    suffixIcon: suffixIcon == null ? null : Icon(suffixIcon, size: 16, color: cs.onSurfaceVariant),
  );
}

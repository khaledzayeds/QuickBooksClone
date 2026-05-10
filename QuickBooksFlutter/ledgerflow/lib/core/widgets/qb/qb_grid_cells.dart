import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../features/purchase_orders/data/models/order_line_entry.dart';

class QbGridHeaderCell extends StatelessWidget {
  const QbGridHeaderCell({
    super.key,
    required this.label,
    required this.width,
    required this.compact,
    this.align = TextAlign.left,
    this.last = false,
  });

  final String label;
  final double width;
  final bool compact;
  final TextAlign align;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          border: Border(
            right: last
                ? BorderSide.none
                : BorderSide(color: cs.outlineVariant.withOpacity(0.7)),
            bottom: BorderSide(color: cs.outlineVariant),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: align,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QbGridCellFrame extends StatelessWidget {
  const QbGridCellFrame({
    super.key,
    required this.width,
    required this.child,
    required this.compact,
    this.alignment,
    this.last = false,
  });

  final double width;
  final Widget child;
  final bool compact;
  final AlignmentGeometry? alignment;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: last
                ? BorderSide.none
                : BorderSide(color: cs.outlineVariant.withOpacity(0.55)),
            bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.55)),
          ),
        ),
        child: alignment == null ? child : Align(alignment: alignment!, child: child),
      ),
    );
  }
}

class QbGridStatusBar extends StatelessWidget {
  const QbGridStatusBar({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onRetry,
      child: Container(
        height: 28,
        color: cs.errorContainer.withOpacity(0.55),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(Icons.refresh, size: 14, color: cs.onErrorContainer),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Items list failed to load. Click to retry.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QbGridTextCell extends StatefulWidget {
  const QbGridTextCell({
    super.key,
    required this.controller,
    required this.compact,
    this.hint,
    this.numeric = false,
    this.align = TextAlign.left,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool compact;
  final String? hint;
  final bool numeric;
  final TextAlign align;
  final VoidCallback? onChanged;
  final VoidCallback? onSubmitted;

  @override
  State<QbGridTextCell> createState() => _QbGridTextCellState();
}

class _QbGridTextCellState extends State<QbGridTextCell> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_repaintFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_repaintFocus);
    _focusNode.dispose();
    super.dispose();
  }

  void _repaintFocus() {
    if (mounted) setState(() {});
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      widget.onSubmitted?.call();
      return widget.onSubmitted == null ? KeyEventResult.ignored : KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab && widget.onSubmitted != null) {
      widget.onSubmitted?.call();
      return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: DecoratedBox(
        decoration: _focusNode.hasFocus
            ? BoxDecoration(border: Border.all(color: cs.primary, width: 1.2))
            : const BoxDecoration(),
        child: TextField(
          controller: widget.controller,
          textAlign: widget.align,
          keyboardType: widget.numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => widget.onSubmitted?.call(),
          onChanged: (_) => widget.onChanged?.call(),
          style: TextStyle(fontSize: widget.compact ? 11 : 12),
          decoration: InputDecoration(
            hintText: widget.hint,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 6 : 8,
              vertical: widget.compact ? 5 : 8,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: true,
            fillColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class QbLineAmountCell extends StatefulWidget {
  const QbLineAmountCell({super.key, required this.line, required this.compact});

  final TransactionLineEntry line;
  final bool compact;

  @override
  State<QbLineAmountCell> createState() => _QbLineAmountCellState();
}

class _QbLineAmountCellState extends State<QbLineAmountCell> {
  late double _amount;

  @override
  void initState() {
    super.initState();
    _amount = _syncAmount();
    _listen(widget.line);
  }

  @override
  void didUpdateWidget(covariant QbLineAmountCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line != widget.line) {
      _unlisten(oldWidget.line);
      _amount = _syncAmount();
      _listen(widget.line);
    }
  }

  @override
  void dispose() {
    _unlisten(widget.line);
    super.dispose();
  }

  void _listen(TransactionLineEntry line) {
    line.qtyCtrl.addListener(_changed);
    line.rateCtrl.addListener(_changed);
  }

  void _unlisten(TransactionLineEntry line) {
    line.qtyCtrl.removeListener(_changed);
    line.rateCtrl.removeListener(_changed);
  }

  double _syncAmount() {
    final qty = double.tryParse(widget.line.qtyCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(widget.line.rateCtrl.text.trim()) ?? 0;
    widget.line.qty = qty;
    widget.line.rate = rate;
    return qty * rate;
  }

  void _changed() {
    final next = _syncAmount();
    if (mounted && next != _amount) setState(() => _amount = next);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          _amount.toStringAsFixed(2),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: widget.compact ? 11 : 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

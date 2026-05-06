import 'package:flutter/material.dart';

import 'transaction_models.dart';

class TransactionLineGrid extends StatelessWidget {
  const TransactionLineGrid({
    super.key,
    required this.lines,
    this.onAddLine,
    this.onEditLine,
    this.onDuplicateLine,
    this.onClearLine,
    this.onItemLookup,
    this.onSubmittedBarcode,
  });

  final List<TransactionLineUiModel> lines;
  final VoidCallback? onAddLine;
  final ValueChanged<TransactionLineUiModel>? onEditLine;
  final ValueChanged<TransactionLineUiModel>? onDuplicateLine;
  final ValueChanged<TransactionLineUiModel>? onClearLine;
  final VoidCallback? onItemLookup;
  final ValueChanged<String>? onSubmittedBarcode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: cs.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(Icons.grid_on_outlined, color: cs.primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lines',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onItemLookup,
                  icon: const Icon(Icons.search, size: 18),
                  tooltip: 'Lookup',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onAddLine,
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'Add line',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: _BarcodeEntry(
              onSubmitted: onSubmittedBarcode,
              onLookup: onItemLookup,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 980),
              child: Column(
                children: [
                  _HeaderRow(),
                  if (lines.isEmpty)
                    const _EmptyGridMessage()
                  else
                    ...lines.map(
                      (line) => _LineRow(
                        line: line,
                        onEdit: onEditLine == null
                            ? null
                            : () => onEditLine!(line),
                        onDuplicate: onDuplicateLine == null
                            ? null
                            : () => onDuplicateLine!(line),
                        onClear: onClearLine == null
                            ? null
                            : () => onClearLine!(line),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: theme.dividerColor),
        ],
      ),
    );
  }
}

class _BarcodeEntry extends StatefulWidget {
  const _BarcodeEntry({required this.onSubmitted, required this.onLookup});
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onLookup;

  @override
  State<_BarcodeEntry> createState() => _BarcodeEntryState();
}

class _BarcodeEntryState extends State<_BarcodeEntry> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Item / Barcode / SKU',
          hintText: 'Scan or type item name',
          prefixIcon: const Icon(Icons.qr_code_scanner_outlined, size: 18),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: widget.onLookup,
                icon: const Icon(Icons.search, size: 18),
                tooltip: 'Lookup',
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: widget.onLookup,
                icon: const Icon(Icons.qr_code_2, size: 18),
                tooltip: 'Scan',
              ),
            ],
          ),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          isDense: true,
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) {
          final trimmed = value.trim();
          if (trimmed.isEmpty) return;
          widget.onSubmitted?.call(trimmed);
          _controller.clear();
        },
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Row(
        children: [
          _Cell(width: 48, child: Text('#')),
          _Cell(width: 220, child: Text('Item / Barcode')),
          _Cell(width: 260, child: Text('Description')),
          _Cell(width: 80, child: Text('Qty')),
          _Cell(width: 80, child: Text('Unit')),
          _Cell(width: 100, child: Text('Rate')),
          _Cell(width: 100, child: Text('Discount')),
          _Cell(width: 100, child: Text('Tax')),
          _Cell(width: 110, child: Text('Amount')),
          _Cell(width: 120, child: Text('Actions')),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    this.onEdit,
    this.onDuplicate,
    this.onClear,
  });

  final TransactionLineUiModel line;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: line.lineNumber.isEven
            ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
            : cs.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Cell(
            width: 48,
            child: Text(
              line.lineNumber.toString(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          _Cell(
            width: 220,
            child: _TwoLine(
              primary: line.itemName ?? line.barcode ?? '-',
              secondary: line.barcode,
            ),
          ),
          _Cell(
            width: 260,
            child: _WarningText(
              text: line.description ?? '-',
              warning: line.warning,
            ),
          ),
          _Cell(width: 80, child: Text(line.quantity.toStringAsFixed(2))),
          _Cell(width: 80, child: Text(line.unit ?? '-')),
          _Cell(width: 100, child: Text(line.rate.toStringAsFixed(2))),
          _Cell(width: 100, child: Text(line.discount.toStringAsFixed(2))),
          _Cell(width: 100, child: Text(line.taxAmount.toStringAsFixed(2))),
          _Cell(
            width: 110,
            child: Text(
              line.amount.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          _Cell(
            width: 120,
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  tooltip: 'Edit line',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onDuplicate,
                  icon: const Icon(Icons.copy_outlined, size: 17),
                  tooltip: 'Duplicate line',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onClear,
                  icon: Icon(Icons.clear, size: 17, color: cs.error),
                  tooltip: 'Clear line',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoLine extends StatelessWidget {
  const _TwoLine({required this.primary, this.secondary});
  final String primary;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          primary,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        if (secondary?.isNotEmpty == true)
          Text(
            secondary!,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
      ],
    );
  }
}

class _WarningText extends StatelessWidget {
  const _WarningText({required this.text, this.warning});
  final String text;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
        if (warning?.isNotEmpty == true)
          Tooltip(
            message: warning!,
            child: Icon(
              Icons.warning_amber_outlined,
              color: cs.error,
              size: 18,
            ),
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.width, required this.child});
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: child,
      ),
    );
  }
}

class _EmptyGridMessage extends StatelessWidget {
  const _EmptyGridMessage();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 96,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner_outlined,
              size: 28,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            const Text(
              'No lines yet',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              'Scan barcode or search an item to start.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../features/items/data/models/item_model.dart';
import '../../../features/items/providers/items_provider.dart';
import '../../../features/purchase_orders/data/models/order_line_entry.dart';
import 'qb_grid_cells.dart';
import 'qb_item_cell.dart';
import 'transaction_line_price_mode.dart';

class QbTransactionLineGrid extends ConsumerStatefulWidget {
  const QbTransactionLineGrid({
    super.key,
    required this.lines,
    required this.onChanged,
    required this.priceMode,
    required this.fillWidth,
    required this.compact,
    required this.showAddLineFooter,
  });

  final List<TransactionLineEntry> lines;
  final VoidCallback onChanged;
  final TransactionLinePriceMode priceMode;
  final bool fillWidth;
  final bool compact;
  final bool showAddLineFooter;

  @override
  ConsumerState<QbTransactionLineGrid> createState() => _QbTransactionLineGridState();
}

class _QbTransactionLineGridState extends ConsumerState<QbTransactionLineGrid> {
  List<ItemModel> _items = const [];
  bool _loadingItems = true;
  String? _itemsError;

  @override
  void initState() {
    super.initState();
    if (widget.lines.isEmpty) widget.lines.add(TransactionLineEntry());
    _loadItemsOnce();
  }

  Future<void> _loadItemsOnce() async {
    setState(() {
      _loadingItems = true;
      _itemsError = null;
    });
    try {
      final items = await ref.read(itemsProvider.future);
      if (!mounted) return;
      setState(() {
        _items = items.where((item) => item.isActive).toList();
        _loadingItems = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loadingItems = false;
        _itemsError = e.toString();
      });
    }
  }

  void _notifyNow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged();
    });
  }

  void _scheduleChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged();
    });
  }

  void _addLine({bool notify = true}) {
    setState(() => widget.lines.add(TransactionLineEntry()));
    if (notify) _notifyNow();
  }

  void _removeLine(int index) {
    setState(() {
      widget.lines.removeAt(index).dispose();
      if (widget.lines.isEmpty) widget.lines.add(TransactionLineEntry());
    });
    _notifyNow();
  }

  void _ensureTrailingBlankLine() {
    final last = widget.lines.last;
    final isBlank = last.itemId == null &&
        last.itemName.trim().isEmpty &&
        last.descCtrl.text.trim().isEmpty &&
        (double.tryParse(last.rateCtrl.text.trim()) ?? 0) == 0;
    if (!isBlank) _addLine(notify: false);
  }

  double _rateForItem(ItemModel item) {
    return switch (widget.priceMode) {
      TransactionLinePriceMode.purchase => item.purchasePrice,
      TransactionLinePriceMode.sales => item.salesPrice,
    };
  }

  void _pickItem(int index, ItemModel item) {
    setState(() {
      final line = widget.lines[index];
      final rate = _rateForItem(item);
      line.itemId = item.id;
      line.itemName = item.name;
      line.rate = rate;
      line.rateCtrl.text = rate.toStringAsFixed(2);
      if (line.descCtrl.text.trim().isEmpty) line.descCtrl.text = item.name;
      if (line.qty <= 0) {
        line.qty = 1;
        line.qtyCtrl.text = '1';
      }
      if (index == widget.lines.length - 1) {
        widget.lines.add(TransactionLineEntry());
      }
    });
    _notifyNow();
  }

  void _commitLastCell() {
    setState(_ensureTrailingBlankLine);
    _notifyNow();
  }

  @override
  Widget build(BuildContext context) {
    return _DesktopGrid(
      compact: widget.compact,
      lines: widget.lines,
      items: _items,
      loadingItems: _loadingItems,
      itemsError: _itemsError,
      showAddLineFooter: widget.showAddLineFooter,
      rateForItem: _rateForItem,
      onAddLine: _addLine,
      onRemoveLine: _removeLine,
      onPickItem: _pickItem,
      onLastCellCommit: _commitLastCell,
      onChanged: _scheduleChanged,
      onRetryItems: _loadItemsOnce,
    );
  }
}

class _DesktopGrid extends StatelessWidget {
  const _DesktopGrid({
    required this.compact,
    required this.lines,
    required this.items,
    required this.loadingItems,
    required this.itemsError,
    required this.showAddLineFooter,
    required this.rateForItem,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onPickItem,
    required this.onLastCellCommit,
    required this.onChanged,
    required this.onRetryItems,
  });

  final bool compact;
  final List<TransactionLineEntry> lines;
  final List<ItemModel> items;
  final bool loadingItems;
  final String? itemsError;
  final bool showAddLineFooter;
  final double Function(ItemModel item) rateForItem;
  final void Function({bool notify}) onAddLine;
  final void Function(int index) onRemoveLine;
  final void Function(int index, ItemModel item) onPickItem;
  final VoidCallback onLastCellCommit;
  final VoidCallback onChanged;
  final Future<void> Function() onRetryItems;

  double get _colAction => compact ? 28 : 34;
  double get _colQty => compact ? 52 : 66;
  double get _colRate => compact ? 72 : 94;
  double get _colTotal => compact ? 78 : 108;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final rowHeight = compact ? 30.0 : 36.0;
    final headerHeight = compact ? 26.0 : 30.0;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          SizedBox(
            height: headerHeight,
            child: Row(
              children: [
                QbGridHeaderCell(label: '#', width: _colAction, compact: compact, align: TextAlign.center),
                _FlexHeader(label: l10n.itemService.toUpperCase(), compact: compact, flex: 4),
                _FlexHeader(label: l10n.description.toUpperCase(), compact: compact, flex: 6),
                QbGridHeaderCell(label: l10n.qty.toUpperCase(), width: _colQty, compact: compact, align: TextAlign.center),
                QbGridHeaderCell(label: l10n.rate.toUpperCase(), width: _colRate, compact: compact, align: TextAlign.right),
                QbGridHeaderCell(label: l10n.amount.toUpperCase(), width: _colTotal, compact: compact, align: TextAlign.right, last: true),
              ],
            ),
          ),
          if (loadingItems)
            const LinearProgressIndicator(minHeight: 2)
          else if (itemsError != null)
            QbGridStatusBar(onRetry: onRetryItems),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemExtent: rowHeight,
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                final lastLine = index == lines.length - 1;
                final bg = index.isEven ? cs.surface : cs.primaryContainer.withValues(alpha: 0.14);

                return Container(
                  height: rowHeight,
                  color: bg,
                  child: Row(
                    children: [
                      QbGridCellFrame(
                        width: _colAction,
                        compact: compact,
                        alignment: Alignment.center,
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          tooltip: 'Remove line',
                          icon: Icon(
                            Icons.delete_outline,
                            size: compact ? 14 : 16,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                          ),
                          onPressed: () => onRemoveLine(index),
                        ),
                      ),
                      _FlexCell(
                        compact: compact,
                        flex: 4,
                        child: QbItemCell(
                          key: ValueKey('item_$index'),
                          initialValue: line.itemName,
                          items: items,
                          loadingItems: loadingItems,
                          rateForItem: rateForItem,
                          compact: compact,
                          onPicked: (item) => onPickItem(index, item),
                          onLastCellCommit: lastLine ? onLastCellCommit : null,
                        ),
                      ),
                      _FlexCell(
                        compact: compact,
                        flex: 6,
                        child: QbGridTextCell(
                          controller: line.descCtrl,
                          hint: l10n.description,
                          compact: compact,
                          onSubmitted: lastLine ? onLastCellCommit : null,
                          onChanged: onChanged,
                        ),
                      ),
                      QbGridCellFrame(
                        width: _colQty,
                        compact: compact,
                        child: QbGridTextCell(
                          controller: line.qtyCtrl,
                          numeric: true,
                          align: TextAlign.center,
                          compact: compact,
                          onSubmitted: lastLine ? onLastCellCommit : null,
                          onChanged: () {
                            line.qty = double.tryParse(line.qtyCtrl.text.trim()) ?? 0;
                            onChanged();
                          },
                        ),
                      ),
                      QbGridCellFrame(
                        width: _colRate,
                        compact: compact,
                        child: QbGridTextCell(
                          controller: line.rateCtrl,
                          numeric: true,
                          align: TextAlign.right,
                          compact: compact,
                          onSubmitted: lastLine ? onLastCellCommit : null,
                          onChanged: () {
                            line.rate = double.tryParse(line.rateCtrl.text.trim()) ?? 0;
                            onChanged();
                          },
                        ),
                      ),
                      QbGridCellFrame(
                        width: _colTotal,
                        compact: compact,
                        last: true,
                        child: QbLineAmountCell(line: line, compact: compact),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (showAddLineFooter)
            Container(
              height: compact ? 30 : 34,
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => onAddLine(notify: true),
                    icon: Icon(Icons.add, size: compact ? 14 : 16),
                    label: Text(l10n.addLine, style: TextStyle(fontSize: compact ? 11 : null)),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: Text(
                      'Tab moves cell • Enter adds line',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: compact ? 10 : 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FlexHeader extends StatelessWidget {
  const _FlexHeader({required this.label, required this.compact, required this.flex});

  final String label;
  final bool compact;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            border: Border(
              right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
              bottom: BorderSide(color: cs.outlineVariant),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                label,
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
      ),
    );
  }
}

class _FlexCell extends StatelessWidget {
  const _FlexCell({required this.child, required this.compact, required this.flex});

  final Widget child;
  final bool compact;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
              bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

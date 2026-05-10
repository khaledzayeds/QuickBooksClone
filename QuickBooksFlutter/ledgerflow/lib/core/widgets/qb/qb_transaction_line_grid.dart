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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = widget.compact;
        final available = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
        final minWidth = compact ? 760.0 : 920.0;
        final width = widget.fillWidth && available > minWidth ? available : minWidth;

        final colAction = compact ? 28.0 : 34.0;
        final colQty = compact ? 68.0 : 76.0;
        final colRate = compact ? 94.0 : 110.0;
        final colTotal = compact ? 108.0 : 124.0;
        final flexible = (width - colAction - colQty - colRate - colTotal).clamp(460.0, 9000.0);
        final colItem = flexible * (compact ? 0.42 : 0.48);
        final colDesc = flexible - colItem;

        return _DesktopGrid(
          width: width,
          compact: compact,
          lines: widget.lines,
          items: _items,
          loadingItems: _loadingItems,
          itemsError: _itemsError,
          showAddLineFooter: widget.showAddLineFooter,
          colAction: colAction,
          colItem: colItem,
          colDesc: colDesc,
          colQty: colQty,
          colRate: colRate,
          colTotal: colTotal,
          rateForItem: _rateForItem,
          onAddLine: _addLine,
          onRemoveLine: _removeLine,
          onPickItem: _pickItem,
          onLastCellCommit: _commitLastCell,
          onChanged: _scheduleChanged,
          onRetryItems: _loadItemsOnce,
        );
      },
    );
  }
}

class _DesktopGrid extends StatelessWidget {
  const _DesktopGrid({
    required this.width,
    required this.compact,
    required this.lines,
    required this.items,
    required this.loadingItems,
    required this.itemsError,
    required this.showAddLineFooter,
    required this.colAction,
    required this.colItem,
    required this.colDesc,
    required this.colQty,
    required this.colRate,
    required this.colTotal,
    required this.rateForItem,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onPickItem,
    required this.onLastCellCommit,
    required this.onChanged,
    required this.onRetryItems,
  });

  final double width;
  final bool compact;
  final List<TransactionLineEntry> lines;
  final List<ItemModel> items;
  final bool loadingItems;
  final String? itemsError;
  final bool showAddLineFooter;
  final double colAction;
  final double colItem;
  final double colDesc;
  final double colQty;
  final double colRate;
  final double colTotal;
  final double Function(ItemModel item) rateForItem;
  final void Function({bool notify}) onAddLine;
  final void Function(int index) onRemoveLine;
  final void Function(int index, ItemModel item) onPickItem;
  final VoidCallback onLastCellCommit;
  final VoidCallback onChanged;
  final Future<void> Function() onRetryItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final rowHeight = compact ? 30.0 : 36.0;
    final headerHeight = compact ? 26.0 : 30.0;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: headerHeight,
            child: Row(
              children: [
                QbGridHeaderCell(label: '#', width: colAction, compact: compact, align: TextAlign.center),
                QbGridHeaderCell(label: l10n.itemService.toUpperCase(), width: colItem, compact: compact),
                QbGridHeaderCell(label: l10n.description.toUpperCase(), width: colDesc, compact: compact),
                QbGridHeaderCell(label: l10n.qty.toUpperCase(), width: colQty, compact: compact, align: TextAlign.center),
                QbGridHeaderCell(label: l10n.rate.toUpperCase(), width: colRate, compact: compact, align: TextAlign.right),
                QbGridHeaderCell(label: l10n.amount.toUpperCase(), width: colTotal, compact: compact, align: TextAlign.right, last: true),
              ],
            ),
          ),
          if (loadingItems)
            const LinearProgressIndicator(minHeight: 2)
          else if (itemsError != null)
            QbGridStatusBar(onRetry: onRetryItems),
          ...lines.asMap().entries.map((entry) {
            final index = entry.key;
            final line = entry.value;
            final lastLine = index == lines.length - 1;
            final bg = index.isEven ? cs.surface : cs.primaryContainer.withOpacity(0.14);

            return Container(
              height: rowHeight,
              color: bg,
              child: Row(
                children: [
                  QbGridCellFrame(
                    width: colAction,
                    compact: compact,
                    alignment: Alignment.center,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      tooltip: 'Remove line',
                      icon: Icon(
                        Icons.delete_outline,
                        size: compact ? 14 : 16,
                        color: cs.onSurfaceVariant.withOpacity(0.65),
                      ),
                      onPressed: () => onRemoveLine(index),
                    ),
                  ),
                  QbGridCellFrame(
                    width: colItem,
                    compact: compact,
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
                  QbGridCellFrame(
                    width: colDesc,
                    compact: compact,
                    child: QbGridTextCell(
                      controller: line.descCtrl,
                      hint: l10n.description,
                      compact: compact,
                      onSubmitted: lastLine ? onLastCellCommit : null,
                      onChanged: onChanged,
                    ),
                  ),
                  QbGridCellFrame(
                    width: colQty,
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
                    width: colRate,
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
                    width: colTotal,
                    compact: compact,
                    last: true,
                    child: QbLineAmountCell(line: line, compact: compact),
                  ),
                ],
              ),
            );
          }),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.readOnly = false,
  });

  final List<TransactionLineEntry> lines;
  final VoidCallback onChanged;
  final TransactionLinePriceMode priceMode;
  final bool fillWidth;
  final bool compact;
  final bool showAddLineFooter;
  final bool readOnly;

  @override
  ConsumerState<QbTransactionLineGrid> createState() =>
      _QbTransactionLineGridState();
}

class _QbTransactionLineGridState extends ConsumerState<QbTransactionLineGrid> {
  final List<FocusNode> _itemFocusNodes = [];
  List<ItemModel> _items = const [];
  bool _loadingItems = true;
  String? _itemsError;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.lines.isEmpty) widget.lines.add(TransactionLineEntry());
    for (var i = 0; i < widget.lines.length; i++) {
      _itemFocusNodes.add(FocusNode());
    }
    _loadItemsOnce();
  }

  @override
  void dispose() {
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncFocusNodes() {
    while (_itemFocusNodes.length < widget.lines.length) {
      _itemFocusNodes.add(FocusNode());
    }
    while (_itemFocusNodes.length > widget.lines.length) {
      _itemFocusNodes.removeLast().dispose();
    }
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
    if (widget.readOnly) return;
    setState(() {
      widget.lines.add(TransactionLineEntry());
      _itemFocusNodes.add(FocusNode());
      _selectedIndex = widget.lines.length - 1;
    });
    if (notify) _notifyNow();
  }

  void _clearLine(int index) {
    if (widget.readOnly) return;
    if (index < 0 || index >= widget.lines.length) return;
    setState(() {
      widget.lines[index].dispose();
      widget.lines[index] = TransactionLineEntry();
      _selectedIndex = index;
    });
    _notifyNow();
  }

  void _removeLine(int index) {
    if (widget.readOnly) return;
    if (widget.lines.length <= 1 || index < 0 || index >= widget.lines.length) {
      _clearLine(index);
      return;
    }
    setState(() {
      widget.lines.removeAt(index).dispose();
      _itemFocusNodes.removeAt(index).dispose();
      _selectedIndex = _selectedIndex.clamp(0, widget.lines.length - 1);
    });
    _notifyNow();
  }

  void _deleteOrClearLine(int index) {
    if (widget.readOnly) return;
    if (index < 0 || index >= widget.lines.length) return;
    final line = widget.lines[index];
    final hasData =
        line.itemId != null ||
        line.itemName.trim().isNotEmpty ||
        line.descCtrl.text.trim().isNotEmpty ||
        (double.tryParse(line.qtyCtrl.text.trim()) ?? 1) != 1 ||
        (double.tryParse(line.rateCtrl.text.trim()) ?? 0) != 0;
    if (hasData) {
      _clearLine(index);
    } else {
      _removeLine(index);
    }
  }

  void _ensureTrailingBlankLine() {
    final last = widget.lines.last;
    final isBlank =
        last.itemId == null &&
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
    if (widget.readOnly) return;
    setState(() {
      _selectedIndex = index;
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
        _itemFocusNodes.add(FocusNode());
      }
      _syncFocusNodes();
    });
    _notifyNow();
  }

  void _commitLineAndMoveNext(int index) {
    if (widget.readOnly) return;
    if (index >= widget.lines.length - 1) {
      _addLine(notify: false);
    }
    final nextIndex = (index + 1).clamp(0, widget.lines.length - 1);
    setState(() => _selectedIndex = nextIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onChanged();
      if (nextIndex < _itemFocusNodes.length) {
        _itemFocusNodes[nextIndex].requestFocus();
      }
    });
  }

  void _commitLastCell() {
    if (widget.readOnly) return;
    setState(_ensureTrailingBlankLine);
    _notifyNow();
  }

  @override
  Widget build(BuildContext context) {
    _syncFocusNodes();
    return _DesktopGrid(
      compact: widget.compact,
      lines: widget.lines,
      itemFocusNodes: _itemFocusNodes,
      items: _items,
      loadingItems: _loadingItems,
      itemsError: _itemsError,
      showAddLineFooter: widget.showAddLineFooter,
      readOnly: widget.readOnly,
      selectedIndex: _selectedIndex,
      rateForItem: _rateForItem,
      onSelectLine: (index) => setState(() => _selectedIndex = index),
      onAddLine: _addLine,
      onDeleteOrClearLine: _deleteOrClearLine,
      onPickItem: _pickItem,
      onEnterCommit: _commitLineAndMoveNext,
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
    required this.itemFocusNodes,
    required this.items,
    required this.loadingItems,
    required this.itemsError,
    required this.showAddLineFooter,
    required this.readOnly,
    required this.selectedIndex,
    required this.rateForItem,
    required this.onSelectLine,
    required this.onAddLine,
    required this.onDeleteOrClearLine,
    required this.onPickItem,
    required this.onEnterCommit,
    required this.onLastCellCommit,
    required this.onChanged,
    required this.onRetryItems,
  });

  final bool compact;
  final List<TransactionLineEntry> lines;
  final List<FocusNode> itemFocusNodes;
  final List<ItemModel> items;
  final bool loadingItems;
  final String? itemsError;
  final bool showAddLineFooter;
  final bool readOnly;
  final int selectedIndex;
  final double Function(ItemModel item) rateForItem;
  final void Function(int index) onSelectLine;
  final void Function({bool notify}) onAddLine;
  final void Function(int index) onDeleteOrClearLine;
  final void Function(int index, ItemModel item) onPickItem;
  final void Function(int index) onEnterCommit;
  final VoidCallback onLastCellCommit;
  final VoidCallback onChanged;
  final Future<void> Function() onRetryItems;

  double get _colQty => compact ? 76 : 86;
  double get _colRate => compact ? 84 : 94;
  double get _colTotal => compact ? 96 : 108;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final rowHeight = compact ? 28.0 : 34.0;
    final headerHeight = compact ? 24.0 : 28.0;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: const Color(0xFF9FB0B9)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: headerHeight,
            child: Row(
              children: [
                _FlexHeader(
                  label: l10n.itemService.toUpperCase(),
                  compact: compact,
                  flex: 4,
                ),
                QbGridHeaderCell(
                  label: 'QUANTITY',
                  width: _colQty,
                  compact: compact,
                  align: TextAlign.center,
                ),
                _FlexHeader(
                  label: l10n.description.toUpperCase(),
                  compact: compact,
                  flex: 7,
                ),
                QbGridHeaderCell(
                  label: l10n.rate.toUpperCase(),
                  width: _colRate,
                  compact: compact,
                  align: TextAlign.right,
                ),
                QbGridHeaderCell(
                  label: l10n.amount.toUpperCase(),
                  width: _colTotal,
                  compact: compact,
                  align: TextAlign.right,
                  last: true,
                ),
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
                final selected = index == selectedIndex;
                final bg = selected
                    ? const Color(0xFFDDECF1)
                    : index.isEven
                    ? Colors.white
                    : const Color(0xFFF2F6F8);

                return Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.delete &&
                        HardwareKeyboard.instance.isControlPressed) {
                      onDeleteOrClearLine(index);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: readOnly ? null : () => onSelectLine(index),
                    child: Container(
                      height: rowHeight,
                      color: bg,
                      child: Row(
                        children: [
                          FocusTraversalOrder(
                            order: NumericFocusOrder(index * 10 + 1),
                            child: _FlexCell(
                              compact: compact,
                              flex: 4,
                              child: QbItemCell(
                                key: ValueKey('item_$index'),
                                initialValue: line.itemName,
                                items: items,
                                loadingItems: loadingItems,
                                rateForItem: rateForItem,
                                compact: compact,
                                focusNode: index < itemFocusNodes.length
                                    ? itemFocusNodes[index]
                                    : null,
                                onPicked: (item) => onPickItem(index, item),
                                onSubmittedPick: () => onEnterCommit(index),
                                onLastCellCommit: lastLine
                                    ? onLastCellCommit
                                    : null,
                                readOnly: readOnly,
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: NumericFocusOrder(index * 10 + 2),
                            child: QbGridCellFrame(
                              width: _colQty,
                              compact: compact,
                              child: QbGridTextCell(
                                controller: line.qtyCtrl,
                                numeric: true,
                                align: TextAlign.center,
                                compact: compact,
                                onSubmitted: lastLine ? onLastCellCommit : null,
                                onChanged: () {
                                  if (readOnly) return;
                                  line.qty =
                                      double.tryParse(
                                        line.qtyCtrl.text.trim(),
                                      ) ??
                                      0;
                                  onChanged();
                                },
                                readOnly: readOnly,
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: NumericFocusOrder(index * 10 + 3),
                            child: _FlexCell(
                              compact: compact,
                              flex: 7,
                              child: QbGridTextCell(
                                controller: line.descCtrl,
                                hint: l10n.description,
                                compact: compact,
                                onSubmitted: lastLine ? onLastCellCommit : null,
                                onChanged: onChanged,
                                readOnly: readOnly,
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: NumericFocusOrder(index * 10 + 4),
                            child: QbGridCellFrame(
                              width: _colRate,
                              compact: compact,
                              child: QbGridTextCell(
                                controller: line.rateCtrl,
                                numeric: true,
                                align: TextAlign.right,
                                compact: compact,
                                onSubmitted: lastLine ? onLastCellCommit : null,
                                onChanged: () {
                                  if (readOnly) return;
                                  line.rate =
                                      double.tryParse(
                                        line.rateCtrl.text.trim(),
                                      ) ??
                                      0;
                                  onChanged();
                                },
                                readOnly: readOnly,
                              ),
                            ),
                          ),
                          QbGridCellFrame(
                            width: _colTotal,
                            compact: compact,
                            last: true,
                            child: QbLineAmountCell(
                              line: line,
                              compact: compact,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    onPressed: readOnly ? null : () => onAddLine(notify: true),
                    icon: Icon(Icons.add, size: compact ? 14 : 16),
                    label: Text(
                      l10n.addLine,
                      style: TextStyle(fontSize: compact ? 11 : null),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: readOnly || lines.isEmpty
                        ? null
                        : () => onDeleteOrClearLine(
                            selectedIndex.clamp(0, lines.length - 1),
                          ),
                    icon: Icon(
                      Icons.cleaning_services_outlined,
                      size: compact ? 14 : 16,
                    ),
                    label: Text(
                      'Clear/Delete',
                      style: TextStyle(fontSize: compact ? 11 : null),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: Text(
                      'Enter: next item • Tab: qty • Ctrl+Delete: clear/delete',
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
  const _FlexHeader({
    required this.label,
    required this.compact,
    required this.flex,
  });

  final String label;
  final bool compact;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFDCE6EA),
            border: Border(
              right: BorderSide(color: Color(0xFF9FB0B9)),
              bottom: BorderSide(color: Color(0xFF9FB0B9)),
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
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  color: const Color(0xFF314A56),
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
  const _FlexCell({
    required this.child,
    required this.compact,
    required this.flex,
  });

  final Widget child;
  final bool compact;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(color: Color(0xFFC9D3D8)),
              bottom: BorderSide(color: Color(0xFFC9D3D8)),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// transaction_line_table_v2.dart
//
// WHY THIS DOESN'T HANG vs the old version:
//
//  1. TransactionLineTable  → plain StatefulWidget (no providers watched)
//  2. Each _LineRow         → independent StatefulWidget with ObjectKey
//                             only THAT row rebuilds on change
//  3. _ItemPickerCell       → ConsumerStatefulWidget that reads itemsProvider
//                             ONCE in initState → stored in _allItems
//                             TypeAheadField filters _allItems locally — zero
//                             provider watches during typing
//  4. onChanged debounced 300ms inside row — parent gets ONE notification
//     after the user stops, not on every keystroke

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../features/items/data/models/item_model.dart';
import '../../features/items/providers/items_provider.dart';
import '../../features/purchase_orders/data/models/order_line_entry.dart';

export 'package:ledgerflow/features/purchase_orders/data/models/order_line_entry.dart'
    show TransactionLineEntry;

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

enum TransactionLinePriceMode { purchase, sales }

class TransactionLineTable extends StatefulWidget {
  const TransactionLineTable({
    super.key,
    required this.lines,
    required this.onChanged,
    this.priceMode = TransactionLinePriceMode.purchase,
    this.fillWidth = false,
    this.compact = false,
    this.showAddLineFooter = true,
  });

  final List<TransactionLineEntry> lines;
  final VoidCallback onChanged;
  final TransactionLinePriceMode priceMode;
  final bool fillWidth;
  final bool compact;
  final bool showAddLineFooter;

  @override
  State<TransactionLineTable> createState() => _TransactionLineTableState();
}

class _TransactionLineTableState extends State<TransactionLineTable> {
  @override
  void initState() {
    super.initState();
    if (widget.lines.isEmpty) _addLine(notify: false);
  }

  // ── Mutators ──────────────────────────────────────────────────────────────

  void _addLine({bool notify = true}) {
    setState(() => widget.lines.add(TransactionLineEntry()));
    if (notify) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged());
    }
  }

  void _removeLine(int index) {
    setState(() {
      widget.lines.removeAt(index).dispose();
      if (widget.lines.isEmpty) widget.lines.add(TransactionLineEntry());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged());
  }

  void _onItemPicked(int index, ItemModel item) {
    final line = widget.lines[index];
    final rate = widget.priceMode == TransactionLinePriceMode.sales
        ? item.salesPrice
        : item.purchasePrice;

    line.itemId = item.id;
    line.itemName = item.name;
    line.rate = rate;
    line.rateCtrl.text = rate.toStringAsFixed(2);

    if (line.descCtrl.text.trim().isEmpty) {
      line.descCtrl.text = item.name;
    }
    if (line.qty == 0 || line.qty == 1) {
      line.qty = 1;
      line.qtyCtrl.text = '1';
    }

    // Auto-add trailing blank row when last line gets filled
    if (index == widget.lines.length - 1) {
      setState(() => widget.lines.add(TransactionLineEntry()));
    }

    widget.onChanged();
  }

  void _onLastCellTab() {
    final last = widget.lines.last;
    final blank =
        last.itemId == null &&
        last.itemName.trim().isEmpty &&
        (double.tryParse(last.rateCtrl.text) ?? 0) == 0;
    if (!blank) _addLine();
  }

  // ── Layout ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final avail = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
        final c = widget.compact;
        final minW = c ? 720.0 : 880.0;
        final totalW = widget.fillWidth && avail > minW ? avail : minW;

        final colDel = c ? 26.0 : 34.0;
        final colQty = c ? 64.0 : 72.0;
        final colRate = c ? 90.0 : 108.0;
        final colTotal = c ? 100.0 : 116.0;
        final flex = (totalW - colDel - colQty - colRate - colTotal - 2).clamp(
          440.0,
          9000.0,
        );
        final colItem = flex * (c ? 0.40 : 0.46);
        final colDesc = flex - colItem;

        final cols = _ColWidths(
          del: colDel,
          item: colItem,
          desc: colDesc,
          qty: colQty,
          rate: colRate,
          total: colTotal,
        );

        final cs = Theme.of(context).colorScheme;
        final hH = c ? 26.0 : 30.0;
        final l10n = AppLocalizations.of(context)!;

        return SizedBox(
          width: totalW,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _TableHeader(cols: cols, compact: c, height: hH, l10n: l10n),

                // Rows — each has its own ObjectKey so only CHANGED row rebuilds
                ...List.generate(widget.lines.length, (i) {
                  final line = widget.lines[i];
                  final isLast = i == widget.lines.length - 1;
                  return _LineRow(
                    key: ObjectKey(line),
                    index: i,
                    line: line,
                    cols: cols,
                    compact: c,
                    priceMode: widget.priceMode,
                    isEven: i.isEven,
                    onDelete: () => _removeLine(i),
                    onItemPicked: (item) => _onItemPicked(i, item),
                    onLastTab: isLast ? _onLastCellTab : null,
                    onChanged: widget.onChanged,
                  );
                }),

                // Add-line footer
                if (widget.showAddLineFooter)
                  _AddLineFooter(compact: c, onAdd: () => _addLine()),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Column widths value object
// ─────────────────────────────────────────────────────────────────────────────

class _ColWidths {
  const _ColWidths({
    required this.del,
    required this.item,
    required this.desc,
    required this.qty,
    required this.rate,
    required this.total,
  });
  final double del, item, desc, qty, rate, total;
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.cols,
    required this.compact,
    required this.height,
    required this.l10n,
  });
  final _ColWidths cols;
  final bool compact;
  final double height;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      color: cs.surfaceContainerHigh,
      child: Row(
        children: [
          SizedBox(width: cols.del),
          _h(l10n.itemService.toUpperCase(), cols.item),
          _h(l10n.description.toUpperCase(), cols.desc),
          _h(l10n.qty.toUpperCase(), cols.qty, align: TextAlign.center),
          _h(l10n.rate.toUpperCase(), cols.rate, align: TextAlign.right),
          _h(l10n.amount.toUpperCase(), cols.total, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _h(String label, double w, {TextAlign align = TextAlign.left}) =>
      SizedBox(
        width: w,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
          child: Text(
            label,
            textAlign: align,
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey,
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Line Row — fully independent StatefulWidget
// ─────────────────────────────────────────────────────────────────────────────

class _LineRow extends StatefulWidget {
  const _LineRow({
    super.key,
    required this.index,
    required this.line,
    required this.cols,
    required this.compact,
    required this.priceMode,
    required this.isEven,
    required this.onDelete,
    required this.onItemPicked,
    required this.onLastTab,
    required this.onChanged,
  });

  final int index;
  final TransactionLineEntry line;
  final _ColWidths cols;
  final bool compact;
  final TransactionLinePriceMode priceMode;
  final bool isEven;
  final VoidCallback onDelete;
  final void Function(ItemModel) onItemPicked;
  final VoidCallback? onLastTab;
  final VoidCallback onChanged;

  @override
  State<_LineRow> createState() => _LineRowState();
}

class _LineRowState extends State<_LineRow> {
  Timer? _debounce;

  void _notify() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) widget.onChanged();
    });
  }

  void _onQtyChanged(String v) {
    widget.line.qty = double.tryParse(v) ?? 0;
    setState(() {}); // only this row repaints (total column)
    _notify();
  }

  void _onRateChanged(String v) {
    widget.line.rate = double.tryParse(v) ?? 0;
    setState(() {});
    _notify();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = widget.compact;
    final rH = c ? 30.0 : 36.0;
    final l = widget.line;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: rH,
      decoration: BoxDecoration(
        color: widget.isEven
            ? cs.surface
            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          // Delete
          SizedBox(
            width: widget.cols.del,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.delete_outline,
                size: c ? 14 : 16,
                color: Colors.grey,
              ),
              onPressed: widget.onDelete,
            ),
          ),

          // Item picker — TypeAheadField, items loaded once in initState
          SizedBox(
            width: widget.cols.item,
            child: _ItemPickerCell(
              key: ValueKey('ip_${widget.index}_${l.itemId}'),
              line: l,
              priceMode: widget.priceMode,
              compact: c,
              rowHeight: rH,
              onPicked: widget.onItemPicked,
              onTabOut: widget.onLastTab,
            ),
          ),

          // Description
          SizedBox(
            width: widget.cols.desc,
            child: _BareTextField(
              controller: l.descCtrl,
              hint: l10n.description,
              compact: c,
              onSubmitted: widget.onLastTab,
              onChanged: (_) => _notify(),
            ),
          ),

          // Qty
          SizedBox(
            width: widget.cols.qty,
            child: _BareTextField(
              controller: l.qtyCtrl,
              numeric: true,
              align: TextAlign.center,
              compact: c,
              onSubmitted: widget.onLastTab,
              onChanged: _onQtyChanged,
            ),
          ),

          // Rate
          SizedBox(
            width: widget.cols.rate,
            child: _BareTextField(
              controller: l.rateCtrl,
              numeric: true,
              align: TextAlign.right,
              compact: c,
              onSubmitted: widget.onLastTab,
              onChanged: _onRateChanged,
            ),
          ),

          // Total (read-only)
          SizedBox(
            width: widget.cols.total,
            child: Padding(
              padding: EdgeInsets.only(right: c ? 8 : 10),
              child: Text(
                (l.qty * l.rate).toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: c ? 11 : 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item Picker — TypeAheadField, items fetched ONCE from provider in initState
// ─────────────────────────────────────────────────────────────────────────────

class _ItemPickerCell extends ConsumerStatefulWidget {
  const _ItemPickerCell({
    super.key,
    required this.line,
    required this.priceMode,
    required this.compact,
    required this.rowHeight,
    required this.onPicked,
    this.onTabOut,
  });

  final TransactionLineEntry line;
  final TransactionLinePriceMode priceMode;
  final bool compact;
  final double rowHeight;
  final void Function(ItemModel) onPicked;
  final VoidCallback? onTabOut;

  @override
  ConsumerState<_ItemPickerCell> createState() => _ItemPickerCellState();
}

class _ItemPickerCellState extends ConsumerState<_ItemPickerCell> {
  late final TextEditingController _ctrl;
  final _suggestionsBoxController = SuggestionsBoxController();

  // Items fetched ONCE — no provider watch, no rebuild on item changes
  List<ItemModel> _allItems = [];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.line.itemName);
    // ref.read → snapshot, not a live subscription
    _allItems =
        ref.read(itemsProvider).value?.where((i) => i.isActive).toList() ?? [];
  }

  @override
  void didUpdateWidget(covariant _ItemPickerCell old) {
    super.didUpdateWidget(old);
    // Only sync text if externally changed (e.g. form reset)
    if (widget.line.itemName != old.line.itemName &&
        widget.line.itemName != _ctrl.text) {
      _ctrl.text = widget.line.itemName;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<ItemModel> _filter(String pattern) {
    final q = pattern.toLowerCase().trim();
    if (q.isEmpty) return _allItems.take(20).toList();
    return _allItems
        .where(
          (i) =>
              i.name.toLowerCase().contains(q) ||
              (i.sku?.toLowerCase().contains(q) ?? false) ||
              (i.barcode?.toLowerCase().contains(q) ?? false),
        )
        .take(25)
        .toList();
  }

  void _onSelected(ItemModel item) {
    _ctrl.text = item.name;
    _suggestionsBoxController.close();
    widget.onPicked(item);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = widget.compact;
    final l10n = AppLocalizations.of(context)!;

    return TypeAheadField<ItemModel>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: _ctrl,
        style: TextStyle(fontSize: c ? 11 : 12, fontWeight: FontWeight.w600),
        textInputAction: TextInputAction.next,
        onSubmitted: (value) {
          final results = _filter(value);
          if (results.isNotEmpty) {
            _onSelected(results.first);
          } else {
            widget.onTabOut?.call();
          }
        },
        decoration: InputDecoration(
          hintText: l10n.selectItem,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: c ? 6 : 8,
            vertical: c ? 6 : 9,
          ),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cs.primary, width: 1),
            borderRadius: BorderRadius.zero,
          ),
          suffixIcon: Icon(Icons.search, size: c ? 12 : 14, color: Colors.grey),
        ),
      ),
      suggestionsBoxController: _suggestionsBoxController,
      suggestionsCallback: _filter, // purely local, zero network/provider call
      itemBuilder: (context, item) {
        final rate = widget.priceMode == TransactionLinePriceMode.sales
            ? item.salesPrice
            : item.purchasePrice;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.sku != null)
                      Text(
                        'SKU: ${item.sku}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rate.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Qty: ${item.quantityOnHand.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: item.quantityOnHand <= 0
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      onSuggestionSelected: _onSelected,
      noItemsFoundBuilder: (context) => const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No items found',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
      // Suggestions box appears BELOW the cell, same width
      suggestionsBoxDecoration: SuggestionsBoxDecoration(
        elevation: 6,
        borderRadius: BorderRadius.circular(6),
        constraints: const BoxConstraints(maxHeight: 280),
      ),
      hideOnEmpty: false,
      hideOnLoading: true,
      keepSuggestionsOnSuggestionSelected: false,
      animationDuration: Duration.zero, // no animation = no jank
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bare text field (description / qty / rate)
// ─────────────────────────────────────────────────────────────────────────────

class _BareTextField extends StatefulWidget {
  const _BareTextField({
    required this.controller,
    this.hint,
    this.numeric = false,
    this.align = TextAlign.left,
    this.compact = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? hint;
  final bool numeric;
  final TextAlign align;
  final bool compact;
  final void Function(String)? onChanged;
  final VoidCallback? onSubmitted;

  @override
  State<_BareTextField> createState() => _BareTextFieldState();
}

class _BareTextFieldState extends State<_BareTextField> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if ((e.logicalKey == LogicalKeyboardKey.enter ||
            e.logicalKey == LogicalKeyboardKey.numpadEnter) &&
        widget.onSubmitted != null) {
      widget.onSubmitted!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = widget.compact;
    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: TextField(
        controller: widget.controller,
        textAlign: widget.align,
        keyboardType: widget.numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        inputFormatters: widget.numeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
            : null,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => widget.onSubmitted?.call(),
        onChanged: widget.onChanged,
        style: TextStyle(fontSize: c ? 11 : 12),
        decoration: InputDecoration(
          hintText: widget.hint,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: c ? 6 : 8,
            vertical: c ? 6 : 9,
          ),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cs.primary, width: 1),
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add-line footer
// ─────────────────────────────────────────────────────────────────────────────

class _AddLineFooter extends StatelessWidget {
  const _AddLineFooter({required this.compact, required this.onAdd});
  final bool compact;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = compact;
    return SizedBox(
      height: c ? 28 : 32,
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add, size: c ? 14 : 16),
            label: Text(
              AppLocalizations.of(context)!.addLine,
              style: TextStyle(fontSize: c ? 11 : null),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: Text(
              'Enter / Tab  \u2192  next line',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: c ? 10 : 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// transaction_line_table.dart
// Optimized QuickBooks-style editable grid with inline searchable item picker.
// Enhanced for scanner support and reusable purchase/sales pricing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import '../../features/items/data/models/item_model.dart';
import '../../features/items/providers/items_provider.dart';
import '../../features/purchase_orders/data/models/order_line_entry.dart';

enum TransactionLinePriceMode { purchase, sales }

class TransactionLineTable extends ConsumerStatefulWidget {
  const TransactionLineTable({
    super.key,
    required this.lines,
    required this.onChanged,
    this.priceMode = TransactionLinePriceMode.purchase,
  });

  final List<TransactionLineEntry> lines;
  final VoidCallback onChanged;
  final TransactionLinePriceMode priceMode;

  @override
  ConsumerState<TransactionLineTable> createState() =>
      _TransactionLineTableState();
}

class _TransactionLineTableState extends ConsumerState<TransactionLineTable> {
  @override
  void initState() {
    super.initState();
    if (widget.lines.isEmpty) {
      _addLine();
    }
  }

  void _addLine() {
    setState(() {
      widget.lines.add(TransactionLineEntry());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged());
  }

  void _removeLine(int index) {
    setState(() {
      final line = widget.lines.removeAt(index);
      line.dispose();
    });
    if (widget.lines.isEmpty) _addLine();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged());
  }

  double _defaultRateFor(ItemModel item) {
    return switch (widget.priceMode) {
      TransactionLinePriceMode.purchase => item.purchasePrice,
      TransactionLinePriceMode.sales => item.salesPrice,
    };
  }

  void _onItemPicked(int index, ItemModel item) {
    setState(() {
      final line = widget.lines[index];
      final rate = _defaultRateFor(item);
      line.itemId = item.id;
      line.itemName = item.name;
      line.rate = rate;
      line.rateCtrl.text = rate.toStringAsFixed(2);
      if (line.descCtrl.text.trim().isEmpty) {
        line.descCtrl.text = item.name;
      }
      if (line.qty == 0) {
        line.qty = 1;
        line.qtyCtrl.text = '1';
      }

      // QuickBooks/scanner behavior: picking an item on the last line creates the next line.
      if (index == widget.lines.length - 1) {
        _addLine();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    const double colAction = 34;
    const double colItem = 280;
    const double colDesc = 300;
    const double colQty = 74;
    const double colRate = 110;
    const double colTotal = 120;
    const double totalWidth =
        colAction + colItem + colDesc + colQty + colRate + colTotal + 2;

    return Container(
      width: totalWidth,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: cs.surfaceContainerHigh,
            height: 30,
            child: Row(
              children: [
                const SizedBox(width: colAction),
                _headerCell(l10n.itemService.toUpperCase(), colItem),
                _headerCell(l10n.description.toUpperCase(), colDesc),
                _headerCell(
                  l10n.qty.toUpperCase(),
                  colQty,
                  align: TextAlign.center,
                ),
                _headerCell(
                  l10n.rate.toUpperCase(),
                  colRate,
                  align: TextAlign.right,
                ),
                _headerCell(
                  l10n.amount.toUpperCase(),
                  colTotal,
                  align: TextAlign.right,
                ),
              ],
            ),
          ),
          ...widget.lines.asMap().entries.map((entry) {
            final i = entry.key;
            final line = entry.value;

            return Container(
              height: 36,
              decoration: BoxDecoration(
                color: i.isEven
                    ? cs.surface
                    : cs.surfaceContainerHighest.withValues(alpha: 0.42),
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: colAction,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onPressed: () => _removeLine(i),
                    ),
                  ),
                  SizedBox(
                    width: colItem,
                    child: _InlineItemPicker(
                      key: ValueKey('item_$i'),
                      initialValue: line.itemName,
                      priceMode: widget.priceMode,
                      onPicked: (item) => _onItemPicked(i, item),
                    ),
                  ),
                  SizedBox(
                    width: colDesc,
                    child: _InlineTextField(
                      controller: line.descCtrl,
                      hint: l10n.description,
                    ),
                  ),
                  SizedBox(
                    width: colQty,
                    child: _InlineTextField(
                      controller: line.qtyCtrl,
                      numeric: true,
                      align: TextAlign.center,
                      onChanged: () {
                        line.qty = double.tryParse(line.qtyCtrl.text) ?? 0;
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => widget.onChanged(),
                        );
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(
                    width: colRate,
                    child: _InlineTextField(
                      controller: line.rateCtrl,
                      numeric: true,
                      align: TextAlign.right,
                      onChanged: () {
                        line.rate = double.tryParse(line.rateCtrl.text) ?? 0;
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => widget.onChanged(),
                        );
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(
                    width: colTotal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        line.amount.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l10n.addLine),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(
    String label,
    double width, {
    TextAlign align = TextAlign.left,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          label,
          textAlign: align,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey,
          ),
        ),
      ),
    );
  }
}

class _InlineTextField extends StatelessWidget {
  const _InlineTextField({
    required this.controller,
    this.hint,
    this.numeric = false,
    this.align = TextAlign.left,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final bool numeric;
  final TextAlign align;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: align,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      textInputAction: TextInputAction.next,
      onChanged: (_) => onChanged?.call(),
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        border: InputBorder.none,
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 1),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

class _InlineItemPicker extends ConsumerStatefulWidget {
  const _InlineItemPicker({
    super.key,
    required this.initialValue,
    required this.onPicked,
    required this.priceMode,
  });

  final String initialValue;
  final Function(ItemModel) onPicked;
  final TransactionLinePriceMode priceMode;

  @override
  ConsumerState<_InlineItemPicker> createState() => _InlineItemPickerState();
}

class _InlineItemPickerState extends ConsumerState<_InlineItemPicker> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _InlineItemPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double _displayRate(ItemModel item) {
    return switch (widget.priceMode) {
      TransactionLinePriceMode.purchase => item.purchasePrice,
      TransactionLinePriceMode.sales => item.salesPrice,
    };
  }

  Iterable<ItemModel> _matches(List<ItemModel> items, String pattern) {
    final text = pattern.toLowerCase().trim();
    if (text.isEmpty) return const Iterable<ItemModel>.empty();
    return items.where(
      (item) =>
          item.name.toLowerCase().contains(text) ||
          (item.sku?.toLowerCase().contains(text) ?? false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);
    final l10n = AppLocalizations.of(context)!;

    return itemsAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) =>
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
      data: (items) => TypeAheadField<ItemModel>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          onSubmitted: (value) {
            final exact = _matches(items, value)
                .where(
                  (item) =>
                      item.name.toLowerCase() == value.toLowerCase().trim() ||
                      item.sku?.toLowerCase() == value.toLowerCase().trim(),
                )
                .toList();
            if (exact.isNotEmpty) {
              widget.onPicked(exact.first);
              return;
            }

            final partial = _matches(items, value).toList();
            if (partial.isNotEmpty) widget.onPicked(partial.first);
          },
          decoration: InputDecoration(
            hintText: l10n.selectItem,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 9,
            ),
            border: InputBorder.none,
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 1),
              borderRadius: BorderRadius.zero,
            ),
            suffixIcon: const Icon(Icons.search, size: 14, color: Colors.grey),
          ),
        ),
        suggestionsCallback: (pattern) => _matches(items, pattern).toList(),
        itemBuilder: (context, item) {
          return ListTile(
            dense: true,
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${_displayRate(item).toStringAsFixed(2)} ${l10n.egp} | ${l10n.stock}: ${item.quantityOnHand}',
            ),
          );
        },
        onSuggestionSelected: (item) {
          _controller.text = item.name;
          widget.onPicked(item);
        },
        noItemsFoundBuilder: (_) => const SizedBox.shrink(),
        suggestionsBoxDecoration: const SuggestionsBoxDecoration(
          elevation: 4,
          constraints: BoxConstraints(maxHeight: 300),
        ),
      ),
    );
  }
}

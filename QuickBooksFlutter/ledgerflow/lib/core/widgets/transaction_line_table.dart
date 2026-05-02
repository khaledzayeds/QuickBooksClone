// transaction_line_table.dart
// Optimized QuickBooks-style editable grid with inline searchable item picker.
// Enhanced for scanner support and reusable purchase/sales pricing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import '../../features/items/data/models/item_model.dart';
import '../../features/items/providers/items_provider.dart';
import '../../features/purchase_orders/data/models/order_line_entry.dart';

enum TransactionLinePriceMode {
  purchase,
  sales,
}

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
  ConsumerState<TransactionLineTable> createState() => _TransactionLineTableState();
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

    const double colAction = 40;
    const double colItem = 280;
    const double colDesc = 300;
    const double colQty = 80;
    const double colRate = 120;
    const double colTotal = 120;
    const double totalWidth = colAction + colItem + colDesc + colQty + colRate + colTotal + 2;

    return Container(
      width: totalWidth,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: cs.surfaceContainerHigh,
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: colAction),
                _HeaderCell(l10n.itemService.toUpperCase(), colItem),
                _HeaderCell(l10n.description.toUpperCase(), colDesc),
                _HeaderCell(l10n.qty.toUpperCase(), colQty, align: TextAlign.center),
                _HeaderCell(l10n.rate.toUpperCase(), colRate, align: TextAlign.right),
                _HeaderCell(l10n.amount.toUpperCase(), colTotal, align: TextAlign.right),
              ],
            ),
          ),
          ...widget.lines.asMap().entries.map((entry) {
            final i = entry.key;
            final line = entry.value;

            return Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: colAction,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
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
                        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged());
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
                        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged());
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
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add, size: 18),
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

  Widget _HeaderCell(String label, double width, {TextAlign align = TextAlign.left}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          textAlign: align,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.blueGrey),
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
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
      textInputAction: TextInputAction.next,
      onChanged: (_) => onChanged?.call(),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: InputBorder.none,
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 1), borderRadius: BorderRadius.zero),
      ),
    );
  }
}

class _InlineItemPicker extends ConsumerWidget {
  const _InlineItemPicker({
    super.key,
    required this.initialValue,
    required this.onPicked,
    required this.priceMode,
  });

  final String initialValue;
  final Function(ItemModel) onPicked;
  final TransactionLinePriceMode priceMode;

  double _displayRate(ItemModel item) {
    return switch (priceMode) {
      TransactionLinePriceMode.purchase => item.purchasePrice,
      TransactionLinePriceMode.sales => item.salesPrice,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);
    final l10n = AppLocalizations.of(context)!;

    return itemsAsync.when(
      loading: () => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      error: (e, _) => const Icon(Icons.error_outline, color: Colors.red, size: 16),
      data: (items) => RawAutocomplete<ItemModel>(
        initialValue: TextEditingValue(text: initialValue),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) return const Iterable<ItemModel>.empty();
          final text = textEditingValue.text.toLowerCase();
          return items.where((item) =>
              item.name.toLowerCase().contains(text) ||
              (item.sku?.toLowerCase().contains(text) ?? false));
        },
        displayStringForOption: (item) => item.name,
        onSelected: onPicked,
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            onSubmitted: (_) {
              final text = controller.text.toLowerCase().trim();
              if (text.isEmpty) return;

              final exact = items.where((i) =>
                (i.sku?.toLowerCase() == text) ||
                (i.name.toLowerCase() == text)
              ).toList();

              if (exact.isNotEmpty) {
                onPicked(exact.first);
              } else {
                final partial = items.where((i) => i.name.toLowerCase().contains(text)).toList();
                if (partial.isNotEmpty) onPicked(partial.first);
              }
            },
            decoration: InputDecoration(
              hintText: l10n.selectItem,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: InputBorder.none,
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 1), borderRadius: BorderRadius.zero),
              suffixIcon: const Icon(Icons.search, size: 14, color: Colors.grey),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: Container(
                width: 280,
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final item = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${_displayRate(item).toStringAsFixed(2)} ${l10n.egp} | ${l10n.stock}: ${item.quantityOnHand}'),
                      onTap: () => onSelected(item),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

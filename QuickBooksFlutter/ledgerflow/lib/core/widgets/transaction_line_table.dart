import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  ConsumerState<TransactionLineTable> createState() => _TransactionLineTableState();
}

class _TransactionLineTableState extends ConsumerState<TransactionLineTable> {
  @override
  void initState() {
    super.initState();
    if (widget.lines.isEmpty) {
      _addLine(notify: false);
    }
  }

  void _addLine({bool notify = true}) {
    setState(() => widget.lines.add(TransactionLineEntry()));
    if (notify) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged());
    }
  }

  void _ensureTrailingBlankLine() {
    if (widget.lines.isEmpty) {
      _addLine();
      return;
    }

    final last = widget.lines.last;
    final hasBlankTrailingLine = last.itemId == null &&
        last.itemName.trim().isEmpty &&
        last.descCtrl.text.trim().isEmpty &&
        (double.tryParse(last.rateCtrl.text) ?? 0) == 0;

    if (!hasBlankTrailingLine) _addLine();
  }

  void _removeLine(int index) {
    setState(() {
      final line = widget.lines.removeAt(index);
      line.dispose();
    });

    if (widget.lines.isEmpty) _addLine(notify: false);
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
      if (index == widget.lines.length - 1) {
        widget.lines.add(TransactionLineEntry());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged());
  }

  void _onLastCellCommit() {
    _ensureTrailingBlankLine();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
        final compact = widget.compact;
        final minWidth = compact ? 760.0 : 920.0;
        final totalWidth = widget.fillWidth && availableWidth > minWidth ? availableWidth : minWidth;

        final colAction = compact ? 26.0 : 34.0;
        final colQty = compact ? 66.0 : 74.0;
        final colRate = compact ? 92.0 : 110.0;
        final colTotal = compact ? 106.0 : 120.0;
        final fixed = colAction + colQty + colRate + colTotal + 2;
        final flexible = (totalWidth - fixed).clamp(460.0, 9000.0);
        final colItem = flexible * (compact ? 0.42 : 0.48);
        final colDesc = flexible - colItem;

        return _GridShell(
          width: totalWidth,
          colAction: colAction,
          colItem: colItem,
          colDesc: colDesc,
          colQty: colQty,
          colRate: colRate,
          colTotal: colTotal,
          compact: compact,
          showAddLineFooter: widget.showAddLineFooter,
          lines: widget.lines,
          priceMode: widget.priceMode,
          onAddLine: _addLine,
          onRemoveLine: _removeLine,
          onItemPicked: _onItemPicked,
          onLastCellCommit: _onLastCellCommit,
          onChanged: widget.onChanged,
        );
      },
    );
  }
}

class _GridShell extends StatelessWidget {
  const _GridShell({
    required this.width,
    required this.colAction,
    required this.colItem,
    required this.colDesc,
    required this.colQty,
    required this.colRate,
    required this.colTotal,
    required this.compact,
    required this.showAddLineFooter,
    required this.lines,
    required this.priceMode,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onItemPicked,
    required this.onLastCellCommit,
    required this.onChanged,
  });

  final double width;
  final double colAction;
  final double colItem;
  final double colDesc;
  final double colQty;
  final double colRate;
  final double colTotal;
  final bool compact;
  final bool showAddLineFooter;
  final List<TransactionLineEntry> lines;
  final TransactionLinePriceMode priceMode;
  final void Function({bool notify}) onAddLine;
  final void Function(int index) onRemoveLine;
  final void Function(int index, ItemModel item) onItemPicked;
  final VoidCallback onLastCellCommit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final rowHeight = compact ? 30.0 : 36.0;
    final headerHeight = compact ? 26.0 : 30.0;

    return Container(
      width: width,
      decoration: BoxDecoration(color: cs.surface, border: Border.all(color: cs.outlineVariant)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: cs.surfaceContainerHigh,
            height: headerHeight,
            child: Row(
              children: [
                SizedBox(width: colAction),
                _headerCell(l10n.itemService.toUpperCase(), colItem, compact: compact),
                _headerCell(l10n.description.toUpperCase(), colDesc, compact: compact),
                _headerCell(l10n.qty.toUpperCase(), colQty, align: TextAlign.center, compact: compact),
                _headerCell(l10n.rate.toUpperCase(), colRate, align: TextAlign.right, compact: compact),
                _headerCell(l10n.amount.toUpperCase(), colTotal, align: TextAlign.right, compact: compact),
              ],
            ),
          ),
          ...lines.asMap().entries.map((entry) {
            final i = entry.key;
            final line = entry.value;
            final isLast = i == lines.length - 1;

            return Container(
              height: rowHeight,
              decoration: BoxDecoration(
                color: i.isEven ? cs.surface : cs.surfaceContainerHighest.withOpacity(0.42),
                border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.5))),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: colAction,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.delete_outline, size: compact ? 14 : 16, color: Colors.grey),
                      onPressed: () => onRemoveLine(i),
                    ),
                  ),
                  SizedBox(
                    width: colItem,
                    child: _InlineItemPicker(
                      key: ValueKey('item_$i'),
                      initialValue: line.itemName,
                      priceMode: priceMode,
                      compact: compact,
                      onPicked: (item) => onItemPicked(i, item),
                      onKeyboardCommit: isLast ? onLastCellCommit : null,
                    ),
                  ),
                  SizedBox(
                    width: colDesc,
                    child: _InlineTextField(
                      controller: line.descCtrl,
                      hint: l10n.description,
                      compact: compact,
                      onSubmitted: isLast ? onLastCellCommit : null,
                    ),
                  ),
                  SizedBox(
                    width: colQty,
                    child: _InlineTextField(
                      controller: line.qtyCtrl,
                      numeric: true,
                      align: TextAlign.center,
                      compact: compact,
                      onSubmitted: isLast ? onLastCellCommit : null,
                      onChanged: () {
                        line.qty = double.tryParse(line.qtyCtrl.text) ?? 0;
                        WidgetsBinding.instance.addPostFrameCallback((_) => onChanged());
                      },
                    ),
                  ),
                  SizedBox(
                    width: colRate,
                    child: _InlineTextField(
                      controller: line.rateCtrl,
                      numeric: true,
                      align: TextAlign.right,
                      compact: compact,
                      onSubmitted: isLast ? onLastCellCommit : null,
                      onChanged: () {
                        line.rate = double.tryParse(line.rateCtrl.text) ?? 0;
                        WidgetsBinding.instance.addPostFrameCallback((_) => onChanged());
                      },
                    ),
                  ),
                  SizedBox(
                    width: colTotal,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          line.amount.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: compact ? 11 : 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (showAddLineFooter)
            SizedBox(
              height: compact ? 28 : 32,
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
                      'Enter/Tab adds the next line',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: compact ? 10 : 11, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerCell(String label, double width, {TextAlign align = TextAlign.left, required bool compact}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
        child: Text(
          label,
          textAlign: align,
          style: TextStyle(fontSize: compact ? 9 : 10, fontWeight: FontWeight.w800, color: Colors.blueGrey),
        ),
      ),
    );
  }
}

class _InlineTextField extends StatefulWidget {
  const _InlineTextField({
    required this.controller,
    this.hint,
    this.numeric = false,
    this.align = TextAlign.left,
    this.onChanged,
    this.onSubmitted,
    this.compact = false,
  });

  final TextEditingController controller;
  final String? hint;
  final bool numeric;
  final TextAlign align;
  final VoidCallback? onChanged;
  final VoidCallback? onSubmitted;
  final bool compact;

  @override
  State<_InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<_InlineTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
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
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: TextField(
        controller: widget.controller,
        textAlign: widget.align,
        keyboardType: widget.numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => widget.onSubmitted?.call(),
        onChanged: (_) => widget.onChanged?.call(),
        style: TextStyle(fontSize: widget.compact ? 11 : 12),
        decoration: InputDecoration(
          hintText: widget.hint,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: widget.compact ? 6 : 8, vertical: widget.compact ? 6 : 9),
          border: InputBorder.none,
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 1), borderRadius: BorderRadius.zero),
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
    this.onKeyboardCommit,
    this.compact = false,
  });

  final String initialValue;
  final void Function(ItemModel) onPicked;
  final TransactionLinePriceMode priceMode;
  final VoidCallback? onKeyboardCommit;
  final bool compact;

  @override
  ConsumerState<_InlineItemPicker> createState() => _InlineItemPickerState();
}

class _InlineItemPickerState extends ConsumerState<_InlineItemPicker> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  List<ItemModel>? _defaultItems;
  String? _lastQuery;
  List<ItemModel>? _lastResults;

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

  Future<List<ItemModel>> _fetchSuggestions(String pattern) async {
    final query = pattern.trim();
    if (query.isEmpty && _defaultItems != null) return _defaultItems!;
    if (query == _lastQuery && _lastResults != null) return _lastResults!;

    final result = await ref.read(itemsRepositoryProvider).getItems(
          search: query.isEmpty ? null : query,
          includeInactive: false,
          page: 1,
          pageSize: query.isEmpty ? 20 : 25,
        );

    final rows = result.when(success: (data) => data, failure: (_) => const <ItemModel>[]);
    if (query.isEmpty) _defaultItems = rows;
    _lastQuery = query;
    _lastResults = rows;
    return rows;
  }

  Future<void> _submitValue(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      widget.onKeyboardCommit?.call();
      return;
    }

    final items = await _fetchSuggestions(query);
    if (!mounted) return;

    final lower = query.toLowerCase();
    final exact = items.where((item) => item.name.toLowerCase() == lower || item.sku?.toLowerCase() == lower);
    if (exact.isNotEmpty) {
      widget.onPicked(exact.first);
      return;
    }
    if (items.isNotEmpty) {
      widget.onPicked(items.first);
      return;
    }
    widget.onKeyboardCommit?.call();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _submitValue(_controller.text);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab && widget.onKeyboardCommit != null) {
      widget.onKeyboardCommit?.call();
      return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: TypeAheadField<ItemModel>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.next,
          style: TextStyle(fontSize: widget.compact ? 11 : 12, fontWeight: FontWeight.w600),
          onSubmitted: _submitValue,
          decoration: InputDecoration(
            hintText: l10n.selectItem,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: widget.compact ? 6 : 8, vertical: widget.compact ? 6 : 9),
            border: InputBorder.none,
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 1), borderRadius: BorderRadius.zero),
            suffixIcon: Icon(Icons.search, size: widget.compact ? 12 : 14, color: Colors.grey),
          ),
        ),
        suggestionsCallback: _fetchSuggestions,
        itemBuilder: (context, item) {
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${_displayRate(item).toStringAsFixed(2)} ${l10n.egp} | ${l10n.stock}: ${item.quantityOnHand}'),
          );
        },
        onSuggestionSelected: (item) {
          _controller.text = item.name;
          widget.onPicked(item);
        },
        noItemsFoundBuilder: (_) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text('No items found', style: TextStyle(fontSize: widget.compact ? 11 : 12)),
        ),
        suggestionsBoxDecoration: const SuggestionsBoxDecoration(elevation: 4, constraints: BoxConstraints(maxHeight: 300)),
      ),
    );
  }
}

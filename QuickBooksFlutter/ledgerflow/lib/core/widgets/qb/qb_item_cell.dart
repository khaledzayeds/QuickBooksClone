import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../features/items/data/models/item_model.dart';

class QbItemCell extends StatefulWidget {
  const QbItemCell({
    super.key,
    required this.initialValue,
    required this.items,
    required this.loadingItems,
    required this.compact,
    required this.rateForItem,
    required this.onPicked,
    this.onLastCellCommit,
  });

  final String initialValue;
  final List<ItemModel> items;
  final bool loadingItems;
  final bool compact;
  final double Function(ItemModel item) rateForItem;
  final void Function(ItemModel item) onPicked;
  final VoidCallback? onLastCellCommit;

  @override
  State<QbItemCell> createState() => _QbItemCellState();
}

class _QbItemCellState extends State<QbItemCell> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode()..addListener(_repaintFocus);
  }

  @override
  void didUpdateWidget(covariant QbItemCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_repaintFocus);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _repaintFocus() {
    if (mounted) setState(() {});
  }

  Iterable<ItemModel> _matches(String pattern) {
    final text = pattern.toLowerCase().trim();
    if (text.isEmpty) return widget.items.take(20);

    return widget.items.where((item) {
      return item.name.toLowerCase().contains(text) ||
          (item.sku?.toLowerCase().contains(text) ?? false) ||
          (item.barcode?.toLowerCase().contains(text) ?? false);
    }).take(25);
  }

  void _pick(ItemModel item) {
    _controller.text = item.name;
    widget.onPicked(item);
  }

  void _submit(String value) {
    final normalized = value.toLowerCase().trim();
    final matches = _matches(value).toList();
    final exact = matches.where((item) {
      return item.name.toLowerCase() == normalized ||
          item.sku?.toLowerCase() == normalized ||
          item.barcode?.toLowerCase() == normalized;
    }).toList();

    if (exact.isNotEmpty) {
      _pick(exact.first);
      return;
    }
    if (matches.isNotEmpty && value.trim().isNotEmpty) {
      _pick(matches.first);
      return;
    }
    widget.onLastCellCommit?.call();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _submit(_controller.text);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.tab &&
        widget.onLastCellCommit != null) {
      widget.onLastCellCommit?.call();
      return KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (widget.loadingItems) return const SizedBox.expand();

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: DecoratedBox(
        decoration: _focusNode.hasFocus
            ? BoxDecoration(border: Border.all(color: cs.primary, width: 1.2))
            : const BoxDecoration(),
        child: TypeAheadField<ItemModel>(
          textFieldConfiguration: TextFieldConfiguration(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: _submit,
            style: TextStyle(
              fontSize: widget.compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: l10n.selectItem,
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
              suffixIcon: Icon(
                Icons.search,
                size: widget.compact ? 12 : 14,
                color: cs.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ),
          suggestionsCallback: (pattern) => _matches(pattern).toList(),
          itemBuilder: (context, item) => ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${widget.rateForItem(item).toStringAsFixed(2)} ${l10n.egp} | ${l10n.stock}: ${item.quantityOnHand}',
            ),
          ),
          onSuggestionSelected: _pick,
          noItemsFoundBuilder: (_) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'No items found',
              style: TextStyle(fontSize: widget.compact ? 11 : 12),
            ),
          ),
          suggestionsBoxDecoration: const SuggestionsBoxDecoration(
            elevation: 4,
            constraints: BoxConstraints(maxHeight: 300),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';

import '../../items/data/models/item_model.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_models.dart';

enum SalesReceiptTemplateMode { standard, cashier }

class SalesReceiptCashierTemplate extends StatefulWidget {
  const SalesReceiptCashierTemplate({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.customerField,
    required this.depositAccountField,
    required this.paymentMethodField,
    required this.dateField,
    required this.referenceField,
    required this.items,
    required this.lines,
    required this.totals,
    required this.saving,
    required this.readOnly,
    required this.onItemSelected,
    required this.onLineQtyChanged,
    required this.onLineRateChanged,
    required this.onRemoveLine,
    required this.onSaveAndClose,
    required this.onSaveAndNew,
    required this.onPrint,
    required this.onClear,
    required this.onClose,
    this.onQuickAddCustomer,
    this.onQuickAddItem,
    this.warning,
  });

  final SalesReceiptTemplateMode mode;
  final ValueChanged<SalesReceiptTemplateMode> onModeChanged;
  final Widget customerField;
  final Widget depositAccountField;
  final Widget paymentMethodField;
  final Widget dateField;
  final Widget referenceField;
  final List<ItemModel> items;
  final List<TransactionLineEntry> lines;
  final TransactionTotalsUiModel totals;
  final bool saving;
  final bool readOnly;
  final ValueChanged<ItemModel> onItemSelected;
  final void Function(TransactionLineEntry line, double qty) onLineQtyChanged;
  final void Function(TransactionLineEntry line, double rate) onLineRateChanged;
  final ValueChanged<TransactionLineEntry> onRemoveLine;
  final VoidCallback? onSaveAndClose;
  final VoidCallback? onSaveAndNew;
  final VoidCallback onPrint;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final VoidCallback? onQuickAddCustomer;
  final VoidCallback? onQuickAddItem;
  final String? warning;

  @override
  State<SalesReceiptCashierTemplate> createState() =>
      _SalesReceiptCashierTemplateState();
}

class _SalesReceiptCashierTemplateState
    extends State<SalesReceiptCashierTemplate> {
  final _scanCtrl = TextEditingController();
  final _scanFocus = FocusNode();

  @override
  void dispose() {
    _scanCtrl.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  Iterable<ItemModel> _matches(String pattern) {
    final value = pattern.trim().toLowerCase();
    final activeItems = widget.items.where((item) => item.isActive);
    if (value.isEmpty) return activeItems.take(30);
    return activeItems
        .where((item) {
          return item.name.toLowerCase().contains(value) ||
              (item.sku?.toLowerCase().contains(value) ?? false) ||
              (item.barcode?.toLowerCase().contains(value) ?? false);
        })
        .take(30);
  }

  void _pick(ItemModel item) {
    widget.onItemSelected(item);
    _scanCtrl.clear();
    _scanFocus.requestFocus();
  }

  void _submit(String value) {
    if (widget.readOnly) return;
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return;
    final exact = widget.items.where((item) {
      return item.barcode?.toLowerCase() == trimmed ||
          item.sku?.toLowerCase() == trimmed ||
          item.name.toLowerCase() == trimmed;
    }).toList();
    if (exact.isNotEmpty) {
      _pick(exact.first);
      return;
    }
    final fuzzy = _matches(value).toList();
    if (fuzzy.isNotEmpty) _pick(fuzzy.first);
  }

  @override
  Widget build(BuildContext context) {
    final activeLines = widget.lines
        .where((line) => line.itemId != null)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: SafeArea(
        child: Column(
          children: [
            _CashierCommandBar(
              saving: widget.saving,
              readOnly: widget.readOnly,
              onSaveAndClose: widget.onSaveAndClose,
              onSaveAndNew: widget.onSaveAndNew,
              onPrint: widget.onPrint,
              onClear: widget.onClear,
              onClose: widget.onClose,
            ),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
              ),
              child: Row(
                children: [
                  const Text(
                    'Template',
                    style: TextStyle(
                      color: Color(0xFF42545D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SalesReceiptTemplateSwitcher(
                    mode: widget.mode,
                    enabled: !widget.readOnly,
                    onChanged: widget.onModeChanged,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: widget.readOnly
                        ? null
                        : widget.onQuickAddCustomer,
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 17),
                    label: const Text('New Customer'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Scan Cashier',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF203C49),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          _HeaderFields(
                            customerField: widget.customerField,
                            depositAccountField: widget.depositAccountField,
                            paymentMethodField: widget.paymentMethodField,
                            dateField: widget.dateField,
                          ),
                          const SizedBox(height: 10),
                          _ScanBox(
                            controller: _scanCtrl,
                            focusNode: _scanFocus,
                            enabled: !widget.readOnly,
                            matches: _matches,
                            onSelected: _pick,
                            onSubmitted: _submit,
                            onQuickAddItem: widget.onQuickAddItem,
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: activeLines.isEmpty
                                ? const _EmptyCart()
                                : ListView.separated(
                                    itemCount: activeLines.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final line = activeLines[index];
                                      return _CartLineTile(
                                        line: line,
                                        readOnly: widget.readOnly,
                                        onQtyChanged: (qty) =>
                                            widget.onLineQtyChanged(line, qty),
                                        onRateChanged: (rate) => widget
                                            .onLineRateChanged(line, rate),
                                        onRemove: () =>
                                            widget.onRemoveLine(line),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 340,
                    child: _CashierSummary(
                      totals: widget.totals,
                      referenceField: widget.referenceField,
                      warning: widget.warning,
                      saving: widget.saving,
                      readOnly: widget.readOnly,
                      onSaveAndClose: widget.onSaveAndClose,
                      onSaveAndNew: widget.onSaveAndNew,
                      onPrint: widget.onPrint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SalesReceiptTemplateSwitcher extends StatelessWidget {
  const SalesReceiptTemplateSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
    this.enabled = true,
  });

  final SalesReceiptTemplateMode mode;
  final ValueChanged<SalesReceiptTemplateMode> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SalesReceiptTemplateMode>(
      segments: const [
        ButtonSegment(
          value: SalesReceiptTemplateMode.standard,
          icon: Icon(Icons.table_rows_outlined, size: 16),
          label: Text('Standard'),
        ),
        ButtonSegment(
          value: SalesReceiptTemplateMode.cashier,
          icon: Icon(Icons.qr_code_scanner_outlined, size: 16),
          label: Text('Cashier'),
        ),
      ],
      selected: {mode},
      onSelectionChanged: enabled ? (values) => onChanged(values.first) : null,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }
}

class _HeaderFields extends StatelessWidget {
  const _HeaderFields({
    required this.customerField,
    required this.depositAccountField,
    required this.paymentMethodField,
    required this.dateField,
  });

  final Widget customerField;
  final Widget depositAccountField;
  final Widget paymentMethodField;
  final Widget dateField;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7C3CB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: customerField),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: depositAccountField),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: paymentMethodField),
          const SizedBox(width: 10),
          SizedBox(width: 190, child: dateField),
        ],
      ),
    );
  }
}

class _ScanBox extends StatelessWidget {
  const _ScanBox({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.matches,
    required this.onSelected,
    required this.onSubmitted,
    this.onQuickAddItem,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final Iterable<ItemModel> Function(String pattern) matches;
  final ValueChanged<ItemModel> onSelected;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onQuickAddItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF203C49),
        border: Border.all(color: const Color(0xFF102E3A)),
      ),
      child: TypeAheadField<ItemModel>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          onSubmitted: onSubmitted,
          autofocus: true,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: 'Scan barcode, SKU, or search item',
            prefixIcon: const Icon(Icons.qr_code_scanner_outlined),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'New item',
                  onPressed: enabled ? onQuickAddItem : null,
                  icon: const Icon(Icons.add_box_outlined),
                ),
                const Icon(Icons.search),
                const SizedBox(width: 8),
              ],
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        suggestionsCallback: (pattern) =>
            enabled ? matches(pattern).toList() : const <ItemModel>[],
        itemBuilder: (context, item) => ListTile(
          dense: true,
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            [
              if ((item.barcode ?? '').isNotEmpty) 'Barcode ${item.barcode}',
              if ((item.sku ?? '').isNotEmpty) 'SKU ${item.sku}',
              'Stock ${item.quantityOnHand.toStringAsFixed(2)}',
            ].join(' | '),
          ),
          trailing: Text(
            item.salesPrice.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        onSuggestionSelected: onSelected,
        noItemsFoundBuilder: (_) => const Padding(
          padding: EdgeInsets.all(12),
          child: Text('No matching items'),
        ),
        suggestionsBoxDecoration: const SuggestionsBoxDecoration(
          elevation: 6,
          constraints: BoxConstraints(maxHeight: 320),
        ),
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.line,
    required this.readOnly,
    required this.onQtyChanged,
    required this.onRateChanged,
    required this.onRemove,
  });

  final TransactionLineEntry line;
  final bool readOnly;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<double> onRateChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7C3CB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFE8F3E5)),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF1C9B16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF26373F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  line.descCtrl.text.trim().isEmpty
                      ? 'Ready to sell'
                      : line.descCtrl.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF60717A),
                  ),
                ),
              ],
            ),
          ),
          _StepperValue(
            value: line.qty,
            readOnly: readOnly,
            onChanged: onQtyChanged,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: TextField(
              controller: line.rateCtrl,
              enabled: !readOnly,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  onRateChanged(double.tryParse(value.trim()) ?? 0),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Line total',
                  style: TextStyle(
                    color: Color(0xFF687980),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  fmt.format(line.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF21343D),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove line',
            onPressed: readOnly ? null : onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _StepperValue extends StatelessWidget {
  const _StepperValue({
    required this.value,
    required this.readOnly,
    required this.onChanged,
  });

  final double value;
  final bool readOnly;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB7C3CB)),
        color: const Color(0xFFF8FAFB),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease',
            visualDensity: VisualDensity.compact,
            onPressed: readOnly ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove, size: 17),
          ),
          SizedBox(
            width: 46,
            child: Text(
              value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            tooltip: 'Increase',
            visualDensity: VisualDensity.compact,
            onPressed: readOnly ? null : () => onChanged(value + 1),
            icon: const Icon(Icons.add, size: 17),
          ),
        ],
      ),
    );
  }
}

class _CashierSummary extends StatelessWidget {
  const _CashierSummary({
    required this.totals,
    required this.referenceField,
    required this.saving,
    required this.readOnly,
    required this.onSaveAndClose,
    required this.onSaveAndNew,
    required this.onPrint,
    this.warning,
  });

  final TransactionTotalsUiModel totals;
  final Widget referenceField;
  final bool saving;
  final bool readOnly;
  final VoidCallback? onSaveAndClose;
  final VoidCallback? onSaveAndNew;
  final VoidCallback onPrint;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 10, 10, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7C3CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Receipt Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF203C49),
            ),
          ),
          const SizedBox(height: 12),
          _TotalLine(
            label: 'Subtotal',
            value: totals.subtotal,
            currency: totals.currency,
          ),
          _TotalLine(
            label: 'Tax',
            value: totals.taxTotal,
            currency: totals.currency,
          ),
          _TotalLine(
            label: 'Discount',
            value: totals.discountTotal,
            currency: totals.currency,
          ),
          const Divider(height: 24),
          _TotalLine(
            label: 'Total',
            value: totals.total,
            currency: totals.currency,
            strong: true,
          ),
          _TotalLine(
            label: 'Paid',
            value: totals.paid,
            currency: totals.currency,
          ),
          _TotalLine(
            label: 'Balance due',
            value: totals.balanceDue,
            currency: totals.currency,
            strong: true,
          ),
          const SizedBox(height: 14),
          referenceField,
          if (warning != null && warning!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                border: Border.all(color: const Color(0xFFE0A33A)),
              ),
              child: Text(
                warning!,
                style: const TextStyle(
                  color: Color(0xFF754500),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          FilledButton.icon(
            onPressed: saving || readOnly ? null : onSaveAndClose,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(saving ? 'Saving...' : 'Save & Close'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: saving || readOnly ? null : onSaveAndNew,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Save & New'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: saving ? null : onPrint,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print / Preview'),
          ),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    required this.currency,
    this.strong = false,
  });

  final String label;
  final double value;
  final String currency;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: strong ? 18 : 13,
      fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
      color: const Color(0xFF21343D),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: style.copyWith(color: const Color(0xFF596B74)),
            ),
          ),
          Text(
            '${NumberFormat('#,##0.00').format(value)} $currency',
            style: style,
          ),
        ],
      ),
    );
  }
}

class _CashierCommandBar extends StatelessWidget {
  const _CashierCommandBar({
    required this.saving,
    required this.readOnly,
    required this.onSaveAndClose,
    required this.onSaveAndNew,
    required this.onPrint,
    required this.onClear,
    required this.onClose,
  });

  final bool saving;
  final bool readOnly;
  final VoidCallback? onSaveAndClose;
  final VoidCallback? onSaveAndNew;
  final VoidCallback onPrint;
  final VoidCallback onClear;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final canEdit = !saving && !readOnly;
    return Container(
      height: 54,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F6F7),
        border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: canEdit ? onSaveAndClose : null,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: canEdit ? onSaveAndNew : null,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Save & New'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: saving ? null : onPrint,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: saving ? null : onClear,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Clear'),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            onPressed: saving ? null : onClose,
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7C3CB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 10),
          const Text(
            'Scan or search an item to start',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

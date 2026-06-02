import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';

import '../../items/data/models/item_model.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_models.dart';

enum InvoiceTemplateMode { standard, quickScan }

class InvoiceTemplateSwitcher extends StatelessWidget {
  const InvoiceTemplateSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
    this.enabled = true,
  });

  final InvoiceTemplateMode mode;
  final ValueChanged<InvoiceTemplateMode> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<InvoiceTemplateMode>(
      segments: const [
        ButtonSegment(
          value: InvoiceTemplateMode.standard,
          icon: Icon(Icons.table_rows_outlined, size: 16),
          label: Text('Standard'),
        ),
        ButtonSegment(
          value: InvoiceTemplateMode.quickScan,
          icon: Icon(Icons.qr_code_scanner_outlined, size: 16),
          label: Text('Quick Scan'),
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

class InvoiceTemplateStrip extends StatelessWidget {
  const InvoiceTemplateStrip({
    super.key,
    required this.mode,
    required this.onChanged,
    this.enabled = true,
    this.trailing,
  });

  final InvoiceTemplateMode mode;
  final ValueChanged<InvoiceTemplateMode> onChanged;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAFB),
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
          InvoiceTemplateSwitcher(
            mode: mode,
            enabled: enabled,
            onChanged: onChanged,
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class InvoiceQuickScanTemplate extends StatefulWidget {
  const InvoiceQuickScanTemplate({
    super.key,
    required this.customerField,
    required this.invoiceDateField,
    required this.dueDateField,
    required this.billingTermsField,
    required this.memoField,
    required this.items,
    required this.lines,
    required this.totals,
    required this.saving,
    required this.posting,
    required this.readOnly,
    required this.onItemSelected,
    required this.onLineQtyChanged,
    required this.onLineRateChanged,
    required this.onRemoveLine,
    required this.onSave,
    required this.onSaveAndNew,
    required this.onPrint,
    this.onQuickAddCustomer,
    this.onQuickAddItem,
    this.warning,
  });

  final Widget customerField;
  final Widget invoiceDateField;
  final Widget dueDateField;
  final Widget billingTermsField;
  final Widget memoField;
  final List<ItemModel> items;
  final List<TransactionLineEntry> lines;
  final TransactionTotalsUiModel totals;
  final bool saving;
  final bool posting;
  final bool readOnly;
  final ValueChanged<ItemModel> onItemSelected;
  final void Function(TransactionLineEntry line, double qty) onLineQtyChanged;
  final void Function(TransactionLineEntry line, double rate) onLineRateChanged;
  final ValueChanged<TransactionLineEntry> onRemoveLine;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndNew;
  final VoidCallback? onPrint;
  final VoidCallback? onQuickAddCustomer;
  final VoidCallback? onQuickAddItem;
  final String? warning;

  @override
  State<InvoiceQuickScanTemplate> createState() =>
      _InvoiceQuickScanTemplateState();
}

class _InvoiceQuickScanTemplateState extends State<InvoiceQuickScanTemplate> {
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _HeaderFields(
                        customerField: widget.customerField,
                        invoiceDateField: widget.invoiceDateField,
                        dueDateField: widget.dueDateField,
                        billingTermsField: widget.billingTermsField,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: widget.readOnly
                          ? null
                          : widget.onQuickAddCustomer,
                      icon: const Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 17,
                      ),
                      label: const Text('New Customer'),
                    ),
                  ],
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
                              onRateChanged: (rate) =>
                                  widget.onLineRateChanged(line, rate),
                              onRemove: () => widget.onRemoveLine(line),
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
          child: _InvoiceSummary(
            totals: widget.totals,
            memoField: widget.memoField,
            warning: widget.warning,
            saving: widget.saving,
            posting: widget.posting,
            readOnly: widget.readOnly,
            onSave: widget.onSave,
            onSaveAndNew: widget.onSaveAndNew,
            onPrint: widget.onPrint,
          ),
        ),
      ],
    );
  }
}

class _HeaderFields extends StatelessWidget {
  const _HeaderFields({
    required this.customerField,
    required this.invoiceDateField,
    required this.dueDateField,
    required this.billingTermsField,
  });

  final Widget customerField;
  final Widget invoiceDateField;
  final Widget dueDateField;
  final Widget billingTermsField;

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
          SizedBox(width: 155, child: invoiceDateField),
          const SizedBox(width: 10),
          SizedBox(width: 155, child: dueDateField),
          const SizedBox(width: 10),
          SizedBox(width: 150, child: billingTermsField),
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
            child: Text(
              line.itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF26373F),
              ),
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
            child: Text(
              fmt.format(line.amount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF21343D),
              ),
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

class _InvoiceSummary extends StatelessWidget {
  const _InvoiceSummary({
    required this.totals,
    required this.memoField,
    required this.saving,
    required this.posting,
    required this.readOnly,
    required this.onSave,
    required this.onSaveAndNew,
    required this.onPrint,
    this.warning,
  });

  final TransactionTotalsUiModel totals;
  final Widget memoField;
  final bool saving;
  final bool posting;
  final bool readOnly;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndNew;
  final VoidCallback? onPrint;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final busy = saving || posting;
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
            'Invoice Summary',
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
          memoField,
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
            onPressed: busy || readOnly ? null : onSave,
            icon: posting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(posting ? 'Posting...' : 'Save / Post'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy || readOnly ? null : onSaveAndNew,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Save & New'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : onPrint,
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
            Icons.description_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 10),
          const Text(
            'Scan or search an item to build the invoice',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// sales_order_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../items/data/models/item_model.dart';
import '../../items/providers/items_provider.dart';
import '../data/models/sales_order_model.dart';
import '../providers/sales_orders_provider.dart';

class SalesOrderLineState {
  String? itemId;
  String description = '';
  double quantity = 1;
  double unitPrice = 0;

  double get draftAmount => quantity * unitPrice;
}

class SalesOrderFormScreen extends ConsumerStatefulWidget {
  const SalesOrderFormScreen({super.key});

  @override
  ConsumerState<SalesOrderFormScreen> createState() => _SalesOrderFormScreenState();
}

class _SalesOrderFormScreenState extends ConsumerState<SalesOrderFormScreen> {
  String? _customerId;
  DateTime _orderDate = DateTime.now();
  DateTime _expectedDate = DateTime.now().add(const Duration(days: 7));
  final List<SalesOrderLineState> _lines = [SalesOrderLineState()];
  bool _saving = false;

  double get _draftSubtotal => _lines.fold(0, (sum, line) => sum + line.draftAmount);

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    if (_customerId == null || _customerId!.isEmpty) {
      _error(l10n.selectCustomerFirst);
      return;
    }

    final validLines = _lines
        .where((line) => line.itemId != null && line.itemId!.isNotEmpty && line.quantity > 0)
        .toList();
    if (validLines.isEmpty) {
      _error(l10n.selectAtLeastOneLine);
      return;
    }

    final dto = CreateSalesOrderDto(
      customerId: _customerId!,
      orderDate: _orderDate,
      expectedDate: _expectedDate,
      saveMode: 1,
      lines: validLines
          .map(
            (line) => CreateSalesOrderLineDto(
              itemId: line.itemId!,
              description: line.description,
              quantity: line.quantity,
              unitPrice: line.unitPrice,
            ),
          )
          .toList(),
    );

    setState(() => _saving = true);
    final result = await ref.read(salesOrdersProvider.notifier).create(dto);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.poCreatedSuccess)));
        context.go('/sales/orders');
      },
      failure: (error) => _error(error.message),
    );
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _addLine() => setState(() => _lines.add(SalesOrderLineState()));

  void _removeLine(int index) {
    if (_lines.length <= 1) return;
    setState(() => _lines.removeAt(index));
  }

  void _updateLine(int index, void Function(SalesOrderLineState line) update) {
    setState(() => update(_lines[index]));
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.newText} ${l10n.salesOrders}'),
        actions: [
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.secondary,
            onPressed: _saving
                ? null
                : () => context.canPop() ? context.pop() : context.go('/sales/orders'),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.save,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _HeaderCard(
            customerId: _customerId,
            orderDate: _orderDate,
            expectedDate: _expectedDate,
            onCustomerChanged: (value) => setState(() => _customerId = value),
          ),
          const SizedBox(height: 24),
          _LinesCard(
            lines: _lines,
            onAddLine: _addLine,
            onRemoveLine: _removeLine,
            onUpdateLine: _updateLine,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _DraftTotalsCard(total: _draftSubtotal),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({
    required this.customerId,
    required this.orderDate,
    required this.expectedDate,
    required this.onCustomerChanged,
  });

  final String? customerId;
  final DateTime orderDate;
  final DateTime expectedDate;
  final ValueChanged<String?> onCustomerChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(customersProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: customerId,
              decoration: InputDecoration(
                labelText: '${l10n.customer} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              items: customersAsync.maybeWhen(
                data: (customers) => customers
                    .map<DropdownMenuItem<String>>(
                      (CustomerModel customer) => DropdownMenuItem<String>(
                        value: customer.id,
                        child: Text(customer.displayName),
                      ),
                    )
                    .toList(),
                orElse: () => const <DropdownMenuItem<String>>[],
              ),
              onChanged: onCustomerChanged,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: l10n.billDate,
                    readOnly: true,
                    initialValue: _SalesOrderFormScreenState._dateOnly(orderDate),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: l10n.expectedDate,
                    readOnly: true,
                    initialValue: _SalesOrderFormScreenState._dateOnly(expectedDate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinesCard extends ConsumerWidget {
  const _LinesCard({
    required this.lines,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onUpdateLine,
  });

  final List<SalesOrderLineState> lines;
  final VoidCallback onAddLine;
  final ValueChanged<int> onRemoveLine;
  final void Function(int index, void Function(SalesOrderLineState line) update) onUpdateLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(flex: 3, child: Text(l10n.itemService)),
                Expanded(child: Text(l10n.qty)),
                Expanded(child: Text(l10n.rate)),
                Expanded(child: Text('${l10n.amount} (draft)')),
                const SizedBox(width: 40),
              ],
            ),
            const Divider(),
            ...lines.asMap().entries.map(
                  (entry) => _SalesOrderLineRow(
                    index: entry.key,
                    line: entry.value,
                    canRemove: lines.length > 1,
                    onRemove: () => onRemoveLine(entry.key),
                    onUpdate: (update) => onUpdateLine(entry.key, update),
                  ),
                ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onAddLine,
                icon: const Icon(Icons.add),
                label: Text(l10n.addLine),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesOrderLineRow extends ConsumerWidget {
  const _SalesOrderLineRow({
    required this.index,
    required this.line,
    required this.canRemove,
    required this.onRemove,
    required this.onUpdate,
  });

  final int index;
  final SalesOrderLineState line;
  final bool canRemove;
  final VoidCallback onRemove;
  final void Function(void Function(SalesOrderLineState line) update) onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: DropdownButtonFormField<String>(
                initialValue: line.itemId,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: itemsAsync.maybeWhen(
                  data: (items) => items
                      .where((item) => item.isActive)
                      .map<DropdownMenuItem<String>>(
                        (ItemModel item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  orElse: () => const <DropdownMenuItem<String>>[],
                ),
                onChanged: (value) {
                  final item = (itemsAsync.value ?? [])
                      .where((item) => item.id == value)
                      .firstOrNull;
                  onUpdate((line) {
                    line.itemId = value;
                    line.description = item?.name ?? '';
                    line.unitPrice = item?.salesPrice ?? line.unitPrice;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: AppTextField(
                label: '',
                initialValue: line.quantity.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => onUpdate((line) => line.quantity = double.tryParse(value) ?? 0),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: AppTextField(
                label: '',
                initialValue: line.unitPrice == 0 ? '' : line.unitPrice.toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => onUpdate((line) => line.unitPrice = double.tryParse(value) ?? 0),
              ),
            ),
          ),
          Expanded(child: Text(line.draftAmount.toStringAsFixed(2), textAlign: TextAlign.end)),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: canRemove ? onRemove : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftTotalsCard extends StatelessWidget {
  const _DraftTotalsCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: SizedBox(
        width: 360,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Draft total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${total.toStringAsFixed(2)} ${l10n.egp}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'The backend recalculates official totals, taxes, and accounting impact after save.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// receive_inventory_form_screen.dart
// Item Receipt style: PO can fill lines, but the receipt remains editable.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/app/router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../core/widgets/transaction_sidebar.dart';
import '../../items/data/models/item_model.dart';
import '../../items/providers/items_provider.dart';
import '../../purchase_orders/data/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../vendors/data/models/vendor_model.dart';
import '../../vendors/providers/vendors_provider.dart';
import '../data/models/create_receive_inventory_dto.dart';
import '../data/models/receiving_plan_model.dart';
import '../providers/receive_inventory_provider.dart';

class ReceiveInventoryFormScreen extends ConsumerStatefulWidget {
  const ReceiveInventoryFormScreen({super.key, this.purchaseOrderId});
  final String? purchaseOrderId;

  @override
  ConsumerState<ReceiveInventoryFormScreen> createState() =>
      _ReceiveInventoryFormScreenState();
}

class _ReceiveInventoryFormScreenState
    extends ConsumerState<ReceiveInventoryFormScreen> {
  VendorModel? _selectedVendor;
  PurchaseOrderModel? _selectedOrder;
  ReceivingPlanModel? _activePlan;
  bool _loadingPlan = false;

  DateTime _receiptDate = DateTime.now();
  final _notesCtrl = TextEditingController();
  final List<_ManualReceiveLine> _manualLines = [_ManualReceiveLine()];
  bool _saving = false;
  bool _initialised = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final line in _manualLines) {
      line.dispose();
    }
    super.dispose();
  }

  void _tryPreselect(List<PurchaseOrderModel> orders) {
    if (_initialised) return;
    _initialised = true;
    final preId = widget.purchaseOrderId;
    if (preId == null || preId.isEmpty) return;
    final match = orders.where((o) => o.id == preId).firstOrNull;
    if (match != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectOrder(match);
      });
    }
  }

  Future<void> _selectOrder(PurchaseOrderModel? order) async {
    setState(() {
      _selectedOrder = order;
      _activePlan = null;
      if (order != null) {
        _selectedVendor = VendorModel(
          id: order.vendorId,
          displayName: order.vendorName,
          isActive: true,
          balance: 0,
          creditBalance: 0,
        );
      }
    });

    if (order == null) {
      _clearPoLinkedLines();
      return;
    }

    setState(() => _loadingPlan = true);
    try {
      final result = await ref
          .read(receiveInventoryRepoProvider)
          .getReceivingPlan(order.id);
      result.when(
        success: (plan) {
          if (mounted) {
            setState(() {
              _activePlan = plan;
              _fillLinesFromPlan(plan);
            });
          }
        },
        failure: (error) => _showError(error.message),
      );
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  void _fillLinesFromPlan(ReceivingPlanModel plan) {
    for (final existing
        in _manualLines
            .where((line) => line.purchaseOrderLineId != null)
            .toList()) {
      _manualLines.remove(existing);
      existing.dispose();
    }

    final poLines = plan.lines.map((line) {
      final entry = _ManualReceiveLine(
        itemId: line.itemId,
        itemName: line.description,
        purchaseOrderLineId: line.purchaseOrderLineId,
        orderedQuantity: line.orderedQuantity,
        previouslyReceivedQuantity: line.receivedQuantity,
        remainingQuantity: line.remainingQuantity,
      );
      entry.descriptionCtrl.text = line.description;
      entry.qtyCtrl.text = line.suggestedReceiveQuantity.toStringAsFixed(2);
      entry.costCtrl.text = line.unitCost.toStringAsFixed(2);
      return entry;
    }).toList();

    final hasOnlyBlankLine =
        _manualLines.length == 1 && _manualLines.first.isBlank;
    if (hasOnlyBlankLine) {
      final blank = _manualLines.removeAt(0);
      blank.dispose();
    }
    _manualLines.insertAll(0, poLines);
    if (_manualLines.isEmpty) _manualLines.add(_ManualReceiveLine());
  }

  void _clearPoLinkedLines() {
    setState(() {
      for (final existing
          in _manualLines
              .where((line) => line.purchaseOrderLineId != null)
              .toList()) {
        _manualLines.remove(existing);
        existing.dispose();
      }
      if (_manualLines.isEmpty) _manualLines.add(_ManualReceiveLine());
    });
  }

  Future<void> _selectVendor() async {
    final vendorsAsync = ref.read(vendorsProvider);
    final vendors = vendorsAsync.maybeWhen(
      data: (items) => items.where((vendor) => vendor.isActive).toList(),
      orElse: () => const <VendorModel>[],
    );

    final selected = await showDialog<VendorModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Vendor'),
        content: SizedBox(
          width: 520,
          child: vendors.isEmpty
              ? const Text('No active vendors loaded yet.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: vendors.length,
                  itemBuilder: (context, index) {
                    final vendor = vendors[index];
                    return ListTile(
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(vendor.displayName),
                      subtitle: Text(
                        'Balance: ${vendor.balance.toStringAsFixed(2)} ${vendor.currency}',
                      ),
                      onTap: () => Navigator.of(context).pop(vendor),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected == null) return;
    setState(() {
      _selectedVendor = selected;
      _selectedOrder = null;
      _activePlan = null;
    });
    _clearPoLinkedLines();
  }

  Future<void> _selectManualItem(_ManualReceiveLine line) async {
    final itemsAsync = ref.read(itemsProvider);
    final items = itemsAsync.maybeWhen(
      data: (items) =>
          items.where((item) => item.isActive && item.isInventory).toList(),
      orElse: () => const <ItemModel>[],
    );

    final selected = await showDialog<ItemModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Inventory Item'),
        content: SizedBox(
          width: 560,
          child: items.isEmpty
              ? const Text('No active inventory items loaded yet.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(item.name),
                      subtitle: Text(
                        'On hand: ${item.quantityOnHand.toStringAsFixed(2)} • Cost: ${item.purchasePrice.toStringAsFixed(2)}',
                      ),
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected == null) return;
    setState(() {
      line.itemId = selected.id;
      line.itemName = selected.name;
      line.purchaseOrderLineId = null;
      line.orderedQuantity = null;
      line.previouslyReceivedQuantity = null;
      line.remainingQuantity = null;
      line.descriptionCtrl.text = selected.name;
      if ((double.tryParse(line.costCtrl.text.trim()) ?? 0) <= 0) {
        line.costCtrl.text = selected.purchasePrice.toStringAsFixed(2);
      }
    });
  }

  void _addManualLine() =>
      setState(() => _manualLines.add(_ManualReceiveLine()));

  void _removeManualLine(_ManualReceiveLine line) {
    if (_manualLines.length == 1) return;
    setState(() {
      _manualLines.remove(line);
      line.dispose();
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedVendor == null) {
      _showError('Select a vendor first.');
      return;
    }

    final lines = _buildEditableLines();
    if (lines == null) return;
    if (lines.isEmpty) {
      _showError(l10n.minOneQty);
      return;
    }

    setState(() => _saving = true);
    try {
      final dto = CreateReceiveInventoryDto(
        vendorId: _selectedVendor!.id,
        purchaseOrderId: _selectedOrder?.id,
        receiptDate: _receiptDate,
        saveMode: 2,
        lines: lines,
      );

      final result = await ref.read(receiveInventoryRepoProvider).create(dto);
      result.when(
        success: (_) {
          ref.invalidate(receiveInventoryListProvider);
          ref.invalidate(openPurchaseOrdersProvider);
          ref.read(purchaseOrdersProvider.notifier).refresh();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('${l10n.riSavedSuccess} ✅')));
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.receiveInventory);
            }
          }
        },
        failure: (error) => _showError(error.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<CreateReceiveInventoryLineDto>? _buildEditableLines() {
    final lines = <CreateReceiveInventoryLineDto>[];
    for (final line in _manualLines) {
      final qty = double.tryParse(line.qtyCtrl.text.trim()) ?? 0;
      final cost = double.tryParse(line.costCtrl.text.trim()) ?? 0;
      if (line.itemId == null && qty <= 0 && cost <= 0) continue;
      if (line.itemId == null) {
        _showError('Select item for every receive line.');
        return null;
      }
      if (qty <= 0) {
        _showError('Quantity must be greater than zero.');
        return null;
      }
      if (cost <= 0) {
        _showError('Unit cost must be greater than zero.');
        return null;
      }
      if (line.purchaseOrderLineId != null &&
          line.remainingQuantity != null &&
          qty > line.remainingQuantity!) {
        _showError(
          '${line.descriptionCtrl.text}: quantity exceeds remaining PO quantity ${line.remainingQuantity!.toStringAsFixed(2)}',
        );
        return null;
      }
      lines.add(
        CreateReceiveInventoryLineDto(
          itemId: line.itemId!,
          quantity: qty,
          unitCost: cost,
          description: line.descriptionCtrl.text.trim().isEmpty
              ? line.itemName
              : line.descriptionCtrl.text.trim(),
          purchaseOrderLineId: line.purchaseOrderLineId,
        ),
      );
    }
    return lines;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(openPurchaseOrdersProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.newReceipt} | ${l10n.inventoryReceipts}'),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (orders) {
          _tryPreselect(orders);
          final vendorOrders = _selectedVendor == null
              ? orders
              : orders.where((o) => o.vendorId == _selectedVendor!.id).toList();
          final uniqueVendorOrders = <PurchaseOrderModel>[];
          final seenOrderIds = <String>{};
          for (final order in vendorOrders) {
            if (seenOrderIds.add(order.id)) {
              uniqueVendorOrders.add(order);
            }
          }
          final selectedOrderId =
              _selectedOrder != null &&
                  seenOrderIds.contains(_selectedOrder!.id)
              ? _selectedOrder!.id
              : null;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _VendorCard(
                      vendor: _selectedVendor,
                      onSelect: _selectVendor,
                      onClear: () {
                        setState(() {
                          _selectedVendor = null;
                          _selectedOrder = null;
                          _activePlan = null;
                        });
                        _clearPoLinkedLines();
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedOrderId,
                      decoration: InputDecoration(
                        labelText: 'Optional Purchase Order',
                        prefixIcon: const Icon(Icons.receipt_long_outlined),
                        border: const OutlineInputBorder(),
                        helperText:
                            'Select PO to fill lines. You can still edit/add manual lines.',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Standalone receive — no PO'),
                        ),
                        ...uniqueVendorOrders.map(
                          (o) => DropdownMenuItem<String?>(
                            value: o.id,
                            child: Text('${o.orderNumber} — ${o.vendorName}'),
                          ),
                        ),
                      ],
                      onChanged: (id) {
                        final order = id == null
                            ? null
                            : uniqueVendorOrders
                                  .where((order) => order.id == id)
                                  .firstOrNull;
                        _selectOrder(order);
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _receiptDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) setState(() => _receiptDate = d);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.receiptDate,
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_receiptDate.day}/${_receiptDate.month}/${_receiptDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loadingPlan)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      _buildEditableReceiveLines(context),
                    const SizedBox(height: 16),
                    _ReceiveDraftTotalsCard(lines: _manualLines),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.notes,
                        hintText: '${l10n.notes}...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              TransactionSidebar(vendorId: _selectedVendor?.id),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? l10n.saving : l10n.saveReceipt),
            onPressed: _saving || _loadingPlan ? null : _save,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableReceiveLines(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Receive Lines',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (_selectedOrder != null) ...[
              const SizedBox(width: 8),
              Chip(label: Text('Filled from ${_selectedOrder!.orderNumber}')),
            ],
            const Spacer(),
            TextButton.icon(
              onPressed: _addManualLine,
              icon: const Icon(Icons.add),
              label: const Text('Add line'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._manualLines.map(
          (line) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            line.purchaseOrderLineId == null
                                ? Icons.inventory_2_outlined
                                : Icons.receipt_long_outlined,
                          ),
                          title: Text(
                            line.itemName.isEmpty
                                ? 'Select item'
                                : line.itemName,
                          ),
                          subtitle: Text(
                            line.purchaseOrderLineId == null
                                ? 'Manual receive line'
                                : 'PO linked • Remaining ${line.remainingQuantity?.toStringAsFixed(2) ?? '-'}',
                          ),
                          onTap: () => _selectManualItem(line),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove line',
                        onPressed: _manualLines.length == 1
                            ? null
                            : () => _removeManualLine(line),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  if (line.purchaseOrderLineId != null) ...[
                    Row(
                      children: [
                        _QtyChip(
                          label: l10n.ordered,
                          value: line.orderedQuantity ?? 0,
                        ),
                        const SizedBox(width: 8),
                        _QtyChip(
                          label: '${l10n.received} (Prev)',
                          value: line.previouslyReceivedQuantity ?? 0,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        _QtyChip(
                          label: 'Rem.',
                          value: line.remainingQuantity ?? 0,
                          color: Colors.orange.shade900,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: line.descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: line.qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.qty,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: line.costCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Unit Cost',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 130,
                        child: Text(
                          line.draftAmount.toStringAsFixed(2),
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({
    required this.vendor,
    required this.onSelect,
    required this.onClear,
  });
  final VendorModel? vendor;
  final VoidCallback onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor?.displayName ?? 'No vendor selected',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    vendor == null
                        ? 'Vendor is required for standalone or PO receiving.'
                        : 'Balance: ${vendor!.balance.toStringAsFixed(2)} ${vendor!.currency}',
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.search),
              label: const Text('Select Vendor'),
            ),
            if (vendor != null)
              IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
          ],
        ),
      ),
    );
  }
}

class _ReceiveDraftTotalsCard extends StatelessWidget {
  const _ReceiveDraftTotalsCard({required this.lines});

  final List<_ManualReceiveLine> lines;

  @override
  Widget build(BuildContext context) {
    final total = lines.fold<double>(0, (sum, line) => sum + line.draftAmount);
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Card(
        child: SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Draft receipt value', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      total.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Official inventory value, PO receiving impact, and posting amounts are recalculated by the backend after save.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyChip extends StatelessWidget {
  const _QtyChip({required this.label, required this.value, this.color});
  final String label;
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      Text(
        value.toStringAsFixed(2),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    ],
  );
}

class _ManualReceiveLine {
  _ManualReceiveLine({
    this.itemId,
    this.itemName = '',
    this.purchaseOrderLineId,
    this.orderedQuantity,
    this.previouslyReceivedQuantity,
    this.remainingQuantity,
  });

  String? itemId;
  String itemName;
  String? purchaseOrderLineId;
  double? orderedQuantity;
  double? previouslyReceivedQuantity;
  double? remainingQuantity;
  final descriptionCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final costCtrl = TextEditingController();

  double get quantity => double.tryParse(qtyCtrl.text.trim()) ?? 0;
  double get unitCost => double.tryParse(costCtrl.text.trim()) ?? 0;
  double get draftAmount => quantity * unitCost;

  bool get isBlank =>
      itemId == null &&
      descriptionCtrl.text.trim().isEmpty &&
      (double.tryParse(qtyCtrl.text.trim()) ?? 0) <= 1 &&
      costCtrl.text.trim().isEmpty;

  void dispose() {
    descriptionCtrl.dispose();
    qtyCtrl.dispose();
    costCtrl.dispose();
  }
}

// receive_inventory_form_screen.dart
// Item Receipt style: PO can fill lines, but the receipt remains editable.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerflow/app/router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../invoices/widgets/notes_edit_dialog.dart';
import '../../items/data/models/item_model.dart';
import '../../items/providers/items_provider.dart';
import '../../purchase_orders/data/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../transactions/widgets/transaction_context_sidebar.dart';
import '../../transactions/widgets/transaction_models.dart';
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
  bool _loadingPlan = false;

  DateTime _receiptDate = DateTime.now();
  final _notesCtrl = TextEditingController();
  final List<_ManualReceiveLine> _manualLines = List.generate(
    5,
    (_) => _ManualReceiveLine(),
  );
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

  void _clear() {
    for (final line in _manualLines) {
      line.dispose();
    }
    setState(() {
      _selectedVendor = null;
      _selectedOrder = null;
      _receiptDate = DateTime.now();
      _notesCtrl.clear();
      _manualLines
        ..clear()
        ..addAll(List.generate(5, (_) => _ManualReceiveLine()));
    });
  }

  Future<void> _openNotesDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => NotesEditDialog(
        title: 'Notes',
        initialNotes: _notesCtrl.text,
        onSave: (notes) async {
          setState(() => _notesCtrl.text = notes);
        },
      ),
    );
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
      if (line.isBlank) continue;
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
    final vendors = ref
        .watch(vendorsProvider)
        .maybeWhen(
          data: (items) => items.where((vendor) => vendor.isActive).toList(),
          orElse: () => const <VendorModel>[],
        );
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
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
          return SafeArea(
            child: Column(
              children: [
                _ReceiveCommandBar(
                  saving: _saving,
                  onFind: () => context.go(AppRoutes.receiveInventory),
                  onNew: () => context.go(AppRoutes.receiveInventoryNew),
                  onSave: _saving || _loadingPlan ? null : _save,
                  onClear: _clear,
                  onClose: () => context.go(AppRoutes.receiveInventory),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(10, 8, 0, 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFB9C3CA)),
                          ),
                          child: Column(
                            children: [
                              _ReceiveHeader(
                                l10n: l10n,
                                fmt: fmt,
                                vendors: vendors,
                                selectedVendor: _selectedVendor,
                                selectedOrderId: selectedOrderId,
                                orders: uniqueVendorOrders,
                                receiptDate: _receiptDate,
                                onVendorSelected: (vendor) {
                                  setState(() {
                                    _selectedVendor = vendor;
                                    _selectedOrder = null;
                                  });
                                  _clearPoLinkedLines();
                                },
                                onOrderChanged: (id) {
                                  final order = id == null
                                      ? null
                                      : uniqueVendorOrders
                                            .where((order) => order.id == id)
                                            .firstOrNull;
                                  _selectOrder(order);
                                },
                                onDateTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _receiptDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (d != null) {
                                    setState(() => _receiptDate = d);
                                  }
                                },
                              ),
                              _ReceiveLinesHeader(
                                loading: _loadingPlan,
                                onAddLine: _addManualLine,
                              ),
                              Expanded(
                                child: _loadingPlan
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : _ReceiveLinesTable(
                                        lines: _manualLines,
                                        onSelectItem: _selectManualItem,
                                        onChanged: () => setState(() {}),
                                      ),
                              ),
                              _ReceiveFooter(
                                l10n: l10n,
                                lines: _manualLines,
                                notesCtrl: _notesCtrl,
                                saving: _saving,
                                onSave: _saving || _loadingPlan ? null : _save,
                                onClear: _clear,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _CollapsibleReceivePanel(
                        child: _ReceiveContextPanel(
                          vendor: _selectedVendor,
                          order: _selectedOrder,
                          total: _manualLines.fold<double>(
                            0,
                            (sum, line) => sum + line.draftAmount,
                          ),
                          notes: _notesCtrl.text,
                          onViewAll: _selectedVendor == null
                              ? null
                              : () => context.go(AppRoutes.receiveInventory),
                          onEditNotes: _openNotesDialog,
                        ),
                      ),
                    ],
                  ),
                ),
                const _ReceiveShortcutStrip(),
              ],
            ),
          );
        },
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

class _ReceiveCommandBar extends StatelessWidget {
  const _ReceiveCommandBar({
    required this.saving,
    required this.onFind,
    required this.onNew,
    required this.onClear,
    required this.onClose,
    this.onSave,
  });

  final bool saving;
  final VoidCallback onFind;
  final VoidCallback onNew;
  final VoidCallback? onSave;
  final VoidCallback onClear;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F6F7),
        border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _Tool(icon: Icons.arrow_back, label: 'Prev'),
          _Tool(icon: Icons.arrow_forward, label: 'Next'),
          _Tool(
            icon: Icons.search,
            label: 'Find',
            onTap: saving ? null : onFind,
          ),
          _Tool(
            icon: Icons.note_add_outlined,
            label: 'New',
            onTap: saving ? null : onNew,
          ),
          _SaveTool(saving: saving, onSave: onSave),
          _Tool(
            icon: Icons.delete_outline,
            label: 'Clear',
            onTap: saving ? null : onClear,
          ),
          const _Separator(),
          const _Tool(icon: Icons.print_outlined, label: 'Print'),
          const _Tool(icon: Icons.mail_outline, label: 'Email'),
          const Spacer(),
          _Tool(
            icon: Icons.close,
            label: 'Close',
            onTap: saving ? null : onClose,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ReceiveHeader extends StatelessWidget {
  const _ReceiveHeader({
    required this.l10n,
    required this.fmt,
    required this.vendors,
    required this.selectedVendor,
    required this.selectedOrderId,
    required this.orders,
    required this.receiptDate,
    required this.onVendorSelected,
    required this.onOrderChanged,
    required this.onDateTap,
  });

  final AppLocalizations l10n;
  final DateFormat fmt;
  final List<VendorModel> vendors;
  final VendorModel? selectedVendor;
  final String? selectedOrderId;
  final List<PurchaseOrderModel> orders;
  final DateTime receiptDate;
  final ValueChanged<VendorModel?> onVendorSelected;
  final ValueChanged<String?> onOrderChanged;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF264D5B),
              border: Border(bottom: BorderSide(color: Color(0xFF183642))),
            ),
            child: Row(
              children: [
                const _StripLabel('VENDOR'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: _InlineVendorField(
                    vendors: vendors,
                    selected: selectedVendor,
                    onSelected: onVendorSelected,
                  ),
                ),
                const SizedBox(width: 16),
                const _StripLabel('P.O.'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _PoDropdown(
                    selectedOrderId: selectedOrderId,
                    orders: orders,
                    onChanged: onOrderChanged,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 146,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 260,
                    child: Text(
                      'Receive Inventory',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF243E4A),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: Column(
                      children: [
                        _HorizontalField(
                          label: 'DATE',
                          child: _DateBox(
                            text: fmt.format(receiptDate),
                            onTap: onDateTap,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _HorizontalField(
                          label: 'RECEIPT #',
                          child: _StaticBox(text: 'AUTO'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('VENDOR / SHIP FROM'),
                        const SizedBox(height: 4),
                        Container(
                          height: 96,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFB7C3CB)),
                          ),
                          child: Text(
                            selectedVendor?.displayName ?? 'Select a vendor',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: selectedVendor == null
                                  ? const Color(0xFF7B8B93)
                                  : const Color(0xFF253C47),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineVendorField extends StatelessWidget {
  const _InlineVendorField({
    required this.vendors,
    required this.selected,
    required this.onSelected,
  });

  final List<VendorModel> vendors;
  final VendorModel? selected;
  final ValueChanged<VendorModel?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<VendorModel>(
      key: ValueKey(selected?.id ?? 'receive-vendor'),
      displayStringForOption: (vendor) => vendor.displayName,
      initialValue: TextEditingValue(text: selected?.displayName ?? ''),
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return vendors.take(20);
        return vendors
            .where((vendor) => vendor.displayName.toLowerCase().contains(query))
            .take(20);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return SizedBox(
          height: 30,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: (value) {
              if (value.trim().isEmpty && selected != null) onSelected(null);
            },
            decoration: const InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.search, size: 16),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              border: OutlineInputBorder(),
              hintText: 'Select vendor',
            ),
          ),
        );
      },
    );
  }
}

class _PoDropdown extends StatelessWidget {
  const _PoDropdown({
    required this.selectedOrderId,
    required this.orders,
    required this.onChanged,
  });

  final String? selectedOrderId;
  final List<PurchaseOrderModel> orders;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: selectedOrderId,
      isDense: true,
      decoration: const InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Standalone receive'),
        ),
        ...orders.map(
          (order) => DropdownMenuItem<String?>(
            value: order.id,
            child: Text(order.orderNumber),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _ReceiveLinesHeader extends StatelessWidget {
  const _ReceiveLinesHeader({required this.loading, required this.onAddLine});

  final bool loading;
  final VoidCallback onAddLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFE9EFF2),
        border: Border(
          top: BorderSide(color: Color(0xFFB7C3CB)),
          bottom: BorderSide(color: Color(0xFFB7C3CB)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Products and Services',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF233F4C),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Tab moves across cells • Enter commits row',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF596B74),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: loading ? null : onAddLine,
            icon: const Icon(Icons.add, size: 15),
            label: const Text('Add Line'),
          ),
        ],
      ),
    );
  }
}

class _ReceiveLinesTable extends StatelessWidget {
  const _ReceiveLinesTable({
    required this.lines,
    required this.onSelectItem,
    required this.onChanged,
  });

  final List<_ManualReceiveLine> lines;
  final ValueChanged<_ManualReceiveLine> onSelectItem;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF9EADB6)),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: const Color(0xFFDDE8ED),
            child: const Row(
              children: [
                _HeaderCell('ITEM / SERVICE', flex: 3),
                _HeaderCell('QUANTITY', flex: 1),
                _HeaderCell('DESCRIPTION', flex: 4),
                _HeaderCell('RATE', flex: 1),
                _HeaderCell('AMOUNT', flex: 1, right: true),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                final shaded = index.isEven;
                return Container(
                  height: 28,
                  color: shaded ? const Color(0xFFDDEFF4) : Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () => onSelectItem(line),
                          child: Container(
                            height: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFFB8C6CE)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    line.itemName.isEmpty
                                        ? 'Select an item...'
                                        : line.itemName,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                const Icon(Icons.search, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _CellTextField(
                        controller: line.qtyCtrl,
                        flex: 1,
                        textAlign: TextAlign.center,
                        onChanged: onChanged,
                      ),
                      _CellTextField(
                        controller: line.descriptionCtrl,
                        flex: 4,
                        onChanged: onChanged,
                      ),
                      _CellTextField(
                        controller: line.costCtrl,
                        flex: 1,
                        textAlign: TextAlign.end,
                        onChanged: onChanged,
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: double.infinity,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            line.draftAmount.toStringAsFixed(2),
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CellTextField extends StatelessWidget {
  const _CellTextField({
    required this.controller,
    required this.flex,
    required this.onChanged,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final int flex;
  final VoidCallback onChanged;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Color(0xFFB8C6CE))),
        ),
        child: TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          textAlign: textAlign,
          cursorHeight: 14,
          decoration: const InputDecoration(
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _ReceiveFooter extends StatelessWidget {
  const _ReceiveFooter({
    required this.l10n,
    required this.lines,
    required this.notesCtrl,
    required this.saving,
    required this.onClear,
    this.onSave,
  });

  final AppLocalizations l10n;
  final List<_ManualReceiveLine> lines;
  final TextEditingController notesCtrl;
  final bool saving;
  final VoidCallback? onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final total = lines.fold<double>(0, (sum, line) => sum + line.draftAmount);
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F9),
        border: Border(top: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('MEMO'),
                const SizedBox(height: 4),
                TextField(
                  controller: notesCtrl,
                  minLines: 1,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Optional',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 310,
            child: Column(
              children: [
                _TotalRow(label: 'TOTAL', value: total, currency: l10n.egp),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F1F4),
                    border: Border.all(color: const Color(0xFF9DB2BC)),
                  ),
                  child: _TotalRow(
                    label: 'RECEIPT VALUE',
                    value: total,
                    currency: l10n.egp,
                    strong: true,
                    noPadding: true,
                  ),
                ),
                const Spacer(),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    OutlinedButton(
                      onPressed: onSave,
                      style: _smallButton(),
                      child: Text(saving ? 'Saving...' : 'Save & Close'),
                    ),
                    OutlinedButton(
                      onPressed: saving ? null : onClear,
                      style: _smallButton(),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _smallButton() => OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    side: const BorderSide(color: Color(0xFF8FA1AB)),
  );
}

class _CollapsibleReceivePanel extends StatefulWidget {
  const _CollapsibleReceivePanel({required this.child});

  final Widget child;

  @override
  State<_CollapsibleReceivePanel> createState() =>
      _CollapsibleReceivePanelState();
}

class _CollapsibleReceivePanelState extends State<_CollapsibleReceivePanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: _expanded ? 258 : 38,
      margin: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: const Color(0xFFB9C3CA)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (_expanded) Positioned.fill(child: widget.child),
          Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: const Color(0xFFE6EEF2),
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Tooltip(
                  message: _expanded ? 'Hide side panel' : 'Show side panel',
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      _expanded ? Icons.chevron_right : Icons.chevron_left,
                      size: 22,
                      color: const Color(0xFF2B4A56),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiveContextPanel extends StatelessWidget {
  const _ReceiveContextPanel({
    required this.vendor,
    required this.order,
    required this.total,
    required this.notes,
    this.onViewAll,
    this.onEditNotes,
  });

  final VendorModel? vendor;
  final PurchaseOrderModel? order;
  final double total;
  final String notes;
  final VoidCallback? onViewAll;
  final VoidCallback? onEditNotes;

  @override
  Widget build(BuildContext context) {
    final v = vendor;
    return TransactionContextSidebar(
      title: v?.displayName ?? '',
      subtitle: v?.companyName,
      initials: v == null ? null : _initials(v.displayName),
      emptyTitle: 'Select a vendor',
      emptyMessage:
          'Choose a vendor to see open purchase orders and receiving status.',
      partyTabLabel: 'Vendor',
      warning: v == null
          ? null
          : order == null
          ? 'Standalone inventory receipt.'
          : 'Receiving against ${order!.orderNumber}.',
      metrics: [
        TransactionContextMetric(
          label: 'Receipt value',
          value: '${total.toStringAsFixed(2)} EGP',
          icon: Icons.receipt_long_outlined,
        ),
        TransactionContextMetric(
          label: 'Purchase order',
          value: order?.orderNumber ?? 'Standalone',
          icon: Icons.inventory_2_outlined,
        ),
        TransactionContextMetric(
          label: 'Can receive',
          value: order?.canReceive == true ? 'Yes' : 'Manual',
          icon: Icons.check_circle_outline,
        ),
      ],
      activities: [
        if (order != null)
          TransactionContextActivity(
            title: order!.orderNumber,
            subtitle: 'Linked purchase order',
            amount: '${order!.totalAmount.toStringAsFixed(2)} EGP',
          ),
      ],
      notes: notes,
      totals: TransactionTotalsUiModel(
        subtotal: total,
        total: total,
        paid: 0,
        balanceDue: total,
        currency: 'EGP',
      ),
      onViewAll: onViewAll,
      onEditNotes: onEditNotes,
    );
  }

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'V';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _ReceiveShortcutStrip extends StatelessWidget {
  const _ReceiveShortcutStrip();

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    alignment: Alignment.centerLeft,
    decoration: const BoxDecoration(
      color: Color(0xFFD4DDE3),
      border: Border(top: BorderSide(color: Color(0xFFAFBBC4))),
    ),
    child: Text(
      'Receive inventory workspace  •  Save & Close  •  Ctrl+P Print  •  Esc Close',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: const Color(0xFF33434C),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _SaveTool extends StatelessWidget {
  const _SaveTool({required this.saving, this.onSave});

  final bool saving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final enabled = !saving && onSave != null;
    return _Tool(
      icon: saving ? Icons.hourglass_top : Icons.save_outlined,
      label: saving ? 'Saving' : 'Save',
      onTap: enabled ? onSave : null,
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? const Color(0xFF234C5D) : const Color(0xFF7D8B93);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 74,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: enabled ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 52,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: const Color(0xFFC7D0D6),
  );
}

class _StripLabel extends StatelessWidget {
  const _StripLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.4,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: const Color(0xFF53656E),
      fontWeight: FontWeight.w900,
    ),
  );
}

class _StaticBox extends StatelessWidget {
  const _StaticBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFB7C3CB)),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 34,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7C3CB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
          const Icon(Icons.calendar_today_outlined, size: 15),
        ],
      ),
    ),
  );
}

class _HorizontalField extends StatelessWidget {
  const _HorizontalField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 82, child: _FieldLabel(label)),
      Expanded(child: child),
    ],
  );
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex, this.right = false});

  final String text;
  final int flex;
  final bool right;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        text,
        textAlign: right ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF53656E),
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.currency,
    this.strong = false,
    this.noPadding = false,
  });

  final String label;
  final double value;
  final String currency;
  final bool strong;
  final bool noPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: noPadding ? 0 : 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          '${value.toStringAsFixed(2)} $currency',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _SideTabBar extends StatelessWidget {
  const _SideTabBar();

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    decoration: const BoxDecoration(
      color: Color(0xFFE1E9ED),
      border: Border(
        top: BorderSide(color: Color(0xFFB8C6CE)),
        bottom: BorderSide(color: Color(0xFFB8C6CE)),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF21A229), width: 2),
              ),
            ),
            child: Text(
              'Vendor',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF21A229),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Transaction',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF53646D),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SideSection extends StatelessWidget {
  const _SideSection({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFB8C6CE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: const Color(0xFFE7EEF1),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2D4854),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF667A84),
      fontWeight: FontWeight.w600,
    ),
  );
}

class _EmptySidePanel extends StatelessWidget {
  const _EmptySidePanel();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.storefront_outlined,
          size: 38,
          color: Color(0xFF8CA0AA),
        ),
        const SizedBox(height: 12),
        Text(
          'Select a vendor',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF2D4854),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose a vendor to see open purchase orders and receiving status.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667A84)),
        ),
      ],
    ),
  );
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
                    const Text(
                      'Draft receipt value',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      total.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
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

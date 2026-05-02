// receive_inventory_form_screen.dart
// Fully localized and aligned with backend receiving-plan flow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../purchase_orders/data/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../data/models/create_receive_inventory_dto.dart';
import '../data/models/receiving_plan_model.dart';
import '../providers/receive_inventory_provider.dart';
import '../../../../core/widgets/transaction_sidebar.dart';

class ReceiveInventoryFormScreen extends ConsumerStatefulWidget {
  /// Optional — if coming from PO Details, pre-select the order.
  const ReceiveInventoryFormScreen({super.key, this.purchaseOrderId});
  final String? purchaseOrderId;

  @override
  ConsumerState<ReceiveInventoryFormScreen> createState() =>
      _ReceiveInventoryFormScreenState();
}

class _ReceiveInventoryFormScreenState
    extends ConsumerState<ReceiveInventoryFormScreen> {
  PurchaseOrderModel? _selectedOrder;
  ReceivingPlanModel? _activePlan;
  bool _loadingPlan = false;

  DateTime _receiptDate = DateTime.now();
  final _notesCtrl = TextEditingController();
  final Map<String, TextEditingController> _qtyControllers = {};
  bool _saving = false;
  bool _initialised = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Pre-select order when purchaseOrderId is passed
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
      for (final c in _qtyControllers.values) {
        c.dispose();
      }
      _qtyControllers.clear();
    });

    if (order == null) return;

    setState(() => _loadingPlan = true);
    try {
      final result = await ref.read(receiveInventoryRepoProvider).getReceivingPlan(order.id);
      result.when(
        success: (plan) {
          if (mounted) {
            setState(() {
              _activePlan = plan;
              for (final line in plan.lines) {
                // Use suggested quantity as default
                _qtyControllers[line.purchaseOrderLineId] = TextEditingController(
                  text: line.suggestedReceiveQuantity.toStringAsFixed(2),
                );
              }
            });
          }
        },
        failure: (error) => _showError(error.message),
      );
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final order = _selectedOrder;
    final plan = _activePlan;
    
    if (order == null || plan == null) {
      _showError(l10n.selectOpenPO);
      return;
    }

    final lines = <CreateReceiveInventoryLineDto>[];
    for (final line in plan.lines) {
      final qty = double.tryParse(
              _qtyControllers[line.purchaseOrderLineId]?.text.trim() ?? '') ??
          0;
      if (qty <= 0) continue;
      
      // Strict validation: cannot exceed remaining quantity
      if (qty > line.remainingQuantity) {
        _showError(
            '${line.description}: ${l10n.qty} > ${line.remainingQuantity.toStringAsFixed(2)}');
        return;
      }
      
      lines.add(CreateReceiveInventoryLineDto(
        itemId:              line.itemId,
        quantity:            qty, // Backend expects 'quantity'
        unitCost:            line.unitCost,
        description:         line.description,
        purchaseOrderLineId: line.purchaseOrderLineId,
      ));
    }

    if (lines.isEmpty) {
      _showError(l10n.minOneQty);
      return;
    }

    setState(() => _saving = true);
    try {
      final dto = CreateReceiveInventoryDto(
        vendorId:        plan.vendorId, // Using vendor from plan
        purchaseOrderId: plan.purchaseOrderId,
        receiptDate:     _receiptDate,
        saveMode:        2, // Always SaveAndPost as requested
        lines:           lines,
      );
      
      final result = await ref.read(receiveInventoryRepoProvider).create(dto);
      result.when(
        success: (_) {
          ref.invalidate(receiveInventoryListProvider);
          ref.invalidate(openPurchaseOrdersProvider);
          ref.read(purchaseOrdersProvider.notifier).refresh();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.riSavedSuccess} ✅')),
            );
            context.pop();
          }
        },
        failure: (error) => _showError(error.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    final l10n        = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.newReceipt} | ${l10n.inventoryReceipts}'),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (orders) {
          _tryPreselect(orders);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
              // PO Dropdown
              DropdownButtonFormField<PurchaseOrderModel>(
                initialValue: _selectedOrder,
                decoration: InputDecoration(
                  labelText: l10n.openPO,
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                  border: const OutlineInputBorder(),
                ),
                items: orders
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child:
                              Text('${o.orderNumber} — ${o.vendorName}'),
                        ))
                    .toList(),
                onChanged: (v) => _selectOrder(v),
              ),
              const SizedBox(height: 16),

              // Receipt Date
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
                      '${_receiptDate.day}/${_receiptDate.month}/${_receiptDate.year}'),
                ),
              ),
              const SizedBox(height: 16),

              // Lines
              if (_selectedOrder == null)
                _HintCard()
              else if (_loadingPlan)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ))
              else if (_activePlan != null)
                ..._buildPlanLines(context, _activePlan!)
              else
                _HintCard(),
              
              const SizedBox(height: 16),

              // Notes
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
              TransactionSidebar(vendorId: _selectedOrder?.vendorId),
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
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? l10n.saving : l10n.saveReceipt),
            onPressed: _saving || _loadingPlan ? null : _save,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlanLines(BuildContext context, ReceivingPlanModel plan) {
    final l10n  = AppLocalizations.of(context)!;
    final lines = plan.lines;

    if (lines.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(l10n.noInventoryReceipts)),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      Text(l10n.items,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      ...lines.map((line) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  Row(children: [
                    _QtyChip(
                        label: l10n.ordered, value: line.orderedQuantity),
                    const SizedBox(width: 8),
                    _QtyChip(
                        label: '${l10n.received} (Prev)', value: line.receivedQuantity, color: Colors.grey),
                    const SizedBox(width: 8),
                    _QtyChip(
                        label: 'Rem.', value: line.remainingQuantity, color: Colors.orange.shade900),
                  ]),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _qtyControllers[line.purchaseOrderLineId],
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.qtyToReceive,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixText:
                          '${l10n.from} ${line.remainingQuantity.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
            ),
          )),
    ];
  }
}

class _HintCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
                child: Text(l10n.selectOpenPOHint)),
          ],
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
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value.toStringAsFixed(2),
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color ?? Theme.of(context).colorScheme.primary)),
        ],
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../purchase_orders/data/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../data/models/create_receive_inventory_dto.dart';
import '../providers/receive_inventory_provider.dart';

class ReceiveInventoryFormScreen extends ConsumerStatefulWidget {
  const ReceiveInventoryFormScreen({super.key});

  @override
  ConsumerState<ReceiveInventoryFormScreen> createState() =>
      _ReceiveInventoryFormScreenState();
}

class _ReceiveInventoryFormScreenState
    extends ConsumerState<ReceiveInventoryFormScreen> {
  PurchaseOrderModel? _selectedOrder;
  final _notesCtrl = TextEditingController();
  final Map<String, TextEditingController> _qtyControllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(purchaseOrdersProvider.notifier).setStatus('Open');
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectOrder(PurchaseOrderModel? order) {
    setState(() {
      _selectedOrder = order;
      for (final controller in _qtyControllers.values) {
        controller.dispose();
      }
      _qtyControllers.clear();

      for (final line in order?.lines ?? <PurchaseOrderLine>[]) {
        if (line.remainingQuantity > 0) {
          _qtyControllers[line.id] = TextEditingController(
            text: line.remainingQuantity.toStringAsFixed(2),
          );
        }
      }
    });
  }

  Future<void> _save() async {
    final order = _selectedOrder;
    if (order == null) {
      _showError('اختر أمر شراء مفتوح أولاً');
      return;
    }

    final lines = <CreateReceiveInventoryLineDto>[];
    for (final line in order.lines) {
      final text = _qtyControllers[line.id]?.text.trim() ?? '';
      final qty = double.tryParse(text) ?? 0;
      if (qty <= 0) continue;
      if (qty > line.remainingQuantity) {
        _showError('كمية ${line.itemName} أكبر من المتبقي');
        return;
      }
      lines.add(
        CreateReceiveInventoryLineDto(
          purchaseOrderLineId: line.id,
          itemId: line.itemId,
          quantityReceived: qty,
        ),
      );
    }

    if (lines.isEmpty) {
      _showError('أدخل كمية استلام واحدة على الأقل');
      return;
    }

    setState(() => _saving = true);
    try {
      final dto = CreateReceiveInventoryDto(
        purchaseOrderId: order.id,
        receiptDate: DateTime.now(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        lines: lines,
      );

      final result = await ref.read(receiveInventoryRepoProvider).create(dto);
      result.when(
        success: (_) {
          ref.invalidate(receiveInventoryListProvider);
          ref.read(purchaseOrdersProvider.notifier).refresh();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تسجيل استلام المخزون ✅')),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(purchaseOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('استلام مخزون جديد')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (orders) {
          final openOrders = orders.where((order) => order.canReceive).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<PurchaseOrderModel>(
                value: _selectedOrder,
                decoration: const InputDecoration(
                  labelText: 'أمر الشراء المفتوح',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
                items: openOrders
                    .map(
                      (order) => DropdownMenuItem(
                        value: order,
                        child: Text('${order.orderNumber} - ${order.vendorName}'),
                      ),
                    )
                    .toList(),
                onChanged: _selectOrder,
              ),
              const SizedBox(height: 16),
              if (_selectedOrder == null)
                const _HintCard()
              else
                ..._buildLines(context, _selectedOrder!),
              const SizedBox(height: 16),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  hintText: 'ملاحظات اختيارية...',
                ),
              ),
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('حفظ الاستلام'),
            onPressed: _saving ? null : _save,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLines(BuildContext context, PurchaseOrderModel order) {
    final lines = order.lines.where((line) => line.remainingQuantity > 0).toList();
    if (lines.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('لا توجد كميات متبقية للاستلام في أمر الشراء المحدد.'),
          ),
        ),
      ];
    }

    return [
      Text('الأصناف المتبقية', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ...lines.map(
        (line) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.itemName, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('المطلوب: ${line.quantity.toStringAsFixed(2)} | المستلم: ${line.receivedQuantity.toStringAsFixed(2)} | المتبقي: ${line.remainingQuantity.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                TextField(
                  controller: _qtyControllers[line.id],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'كمية الاستلام'),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            Icon(Icons.info_outline),
            SizedBox(width: 12),
            Expanded(child: Text('اختر أمر شراء مفتوح لعرض الكميات المتبقية للاستلام.')),
          ],
        ),
      ),
    );
  }
}

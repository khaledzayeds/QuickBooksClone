// receive_inventory_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../purchase_orders/data/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../data/models/create_receive_inventory_dto.dart';
import '../providers/receive_inventory_provider.dart';

class ReceiveInventoryFormScreen extends ConsumerStatefulWidget {
  /// اختياري — لو جاي من PO Details يتحدد الأمر تلقائياً
  const ReceiveInventoryFormScreen({super.key, this.purchaseOrderId});
  final String? purchaseOrderId;

  @override
  ConsumerState<ReceiveInventoryFormScreen> createState() =>
      _ReceiveInventoryFormScreenState();
}

class _ReceiveInventoryFormScreenState
    extends ConsumerState<ReceiveInventoryFormScreen> {
  PurchaseOrderModel? _selectedOrder;
  DateTime _receiptDate = DateTime.now();
  final _notesCtrl = TextEditingController();
  final Map<String, TextEditingController> _qtyControllers = {};
  bool _saving = false;
  bool _initialised = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final c in _qtyControllers.values) c.dispose();
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

  void _selectOrder(PurchaseOrderModel? order) {
    setState(() {
      _selectedOrder = order;
      for (final c in _qtyControllers.values) c.dispose();
      _qtyControllers.clear();
      for (final line in order?.lines ?? <PurchaseOrderLine>[]) {
        if (line.quantity > 0) {
          _qtyControllers[line.id] = TextEditingController(
            text: line.quantity.toStringAsFixed(2),
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
      final qty = double.tryParse(
              _qtyControllers[line.id]?.text.trim() ?? '') ??
          0;
      if (qty <= 0) continue;
      if (qty > line.quantity) {
        _showError(
            'كمية "${line.description}" أكبر من المطلوب (${line.quantity.toStringAsFixed(2)})');
        return;
      }
      lines.add(CreateReceiveInventoryLineDto(
        itemId: line.itemId,
        quantity: qty,
        unitCost: line.unitCost,
        description: line.description,
        purchaseOrderLineId: line.id,
      ));
    }

    if (lines.isEmpty) {
      _showError('أدخل كمية استلام واحدة على الأقل');
      return;
    }

    setState(() => _saving = true);
    try {
      final dto = CreateReceiveInventoryDto(
        vendorId: order.vendorId,
        purchaseOrderId: order.id,
        receiptDate: _receiptDate,
        lines: lines,
      );
      final result = await ref.read(receiveInventoryRepoProvider).create(dto);
      result.when(
        success: (_) {
          ref.invalidate(receiveInventoryListProvider);
          ref.invalidate(openPurchaseOrdersProvider);
          ref.read(purchaseOrdersProvider.notifier).refresh();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('تم تسجيل استلام المخزون بنجاح ✅')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('استلام مخزون جديد | New Receipt'),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (orders) {
          _tryPreselect(orders);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // PO Dropdown
              DropdownButtonFormField<PurchaseOrderModel>(
                value: _selectedOrder,
                decoration: const InputDecoration(
                  labelText: 'أمر الشراء المفتوح | Open Purchase Order',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                  border: OutlineInputBorder(),
                ),
                items: orders
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child:
                              Text('${o.orderNumber} — ${o.vendorName}'),
                        ))
                    .toList(),
                onChanged: _selectOrder,
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
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الاستلام | Receipt Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                      '${_receiptDate.day}/${_receiptDate.month}/${_receiptDate.year}'),
                ),
              ),
              const SizedBox(height: 16),

              // Lines
              if (_selectedOrder == null)
                _HintCard()
              else
                ..._buildLines(context, _selectedOrder!),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات | Notes',
                  hintText: 'ملاحظات اختيارية...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 80),
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
            label: Text(_saving ? 'جاري الحفظ...' : 'حفظ الاستلام | Save'),
            onPressed: _saving ? null : _save,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLines(BuildContext context, PurchaseOrderModel order) {
    final lines = order.lines.where((l) => l.quantity > 0).toList();

    if (lines.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'لا توجد أصناف في هذا الأمر.\nNo items in this order.')),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      Text('الأصناف | Items',
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
                        label: 'مطلوب | Ordered', value: line.quantity),
                    const SizedBox(width: 8),
                    _QtyChip(
                        label: 'سعر الوحدة | Unit Cost',
                        value: line.unitCost,
                        color: Colors.blue),
                  ]),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _qtyControllers[line.id],
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'كمية الاستلام | Qty to Receive',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixText:
                          'من ${line.quantity.toStringAsFixed(2)}',
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
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'اختر أمر شراء مفتوح لعرض الكميات.\nSelect an open PO to see remaining quantities.')),
            ],
          ),
        ),
      );
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

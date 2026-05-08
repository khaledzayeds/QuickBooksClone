// purchase_return_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../purchase_bills/data/models/purchase_bill_model.dart';
import '../../purchase_bills/providers/purchase_bills_provider.dart';
import '../data/models/purchase_return_model.dart';
import '../providers/purchase_returns_provider.dart';

class PurchaseReturnLineState {
  PurchaseReturnLineState({
    required this.purchaseBillLineId,
    required this.description,
    required this.originalQuantity,
    required this.unitCost,
    this.quantity = 0,
  });

  final String purchaseBillLineId;
  final String description;
  final double originalQuantity;
  final double unitCost;
  double quantity;

  double get draftAmount => quantity * unitCost;
}

class PurchaseReturnFormScreen extends ConsumerStatefulWidget {
  const PurchaseReturnFormScreen({super.key, this.billId});

  final String? billId;

  @override
  ConsumerState<PurchaseReturnFormScreen> createState() => _PurchaseReturnFormScreenState();
}

class _PurchaseReturnFormScreenState extends ConsumerState<PurchaseReturnFormScreen> {
  String? _purchaseBillId;
  final DateTime _returnDate = DateTime.now();
  List<PurchaseReturnLineState> _lines = [];
  bool _saving = false;
  bool _preselected = false;

  double get _draftTotal => _lines.fold(0, (sum, line) => sum + line.draftAmount);

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(purchaseBillsProvider);
    _tryPreselectBill(billsAsync);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مرتجع شراء جديد'),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.purchaseReturns),
            child: const Text('إلغاء'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('حفظ المرتجع'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _BillCard(
            purchaseBillId: _purchaseBillId,
            returnDate: _returnDate,
            billsAsync: billsAsync,
            onBillChanged: _selectBill,
          ),
          const SizedBox(height: 24),
          _LinesCard(
            lines: _lines,
            onQuantityChanged: (index, quantity) => setState(() => _lines[index].quantity = quantity),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _DraftTotalCard(total: _draftTotal),
          ),
        ],
      ),
    );
  }

  void _tryPreselectBill(AsyncValue<List<PurchaseBillModel>> billsAsync) {
    if (_preselected) return;
    final billId = widget.billId;
    if (billId == null || billId.isEmpty) {
      _preselected = true;
      return;
    }

    billsAsync.whenData((bills) {
      final bill = bills.where((item) => item.id == billId).firstOrNull;
      if (bill == null) return;
      _preselected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _selectBill(bill);
      });
    });
  }

  void _selectBill(PurchaseBillModel? bill) {
    setState(() {
      if (bill == null) {
        _purchaseBillId = null;
        _lines = [];
        return;
      }
      _purchaseBillId = bill.id;
      _lines = _linesFromBill(bill);
    });
  }

  Future<void> _save() async {
    if (_purchaseBillId == null || _purchaseBillId!.isEmpty) {
      _error('اختر فاتورة الشراء أولاً');
      return;
    }

    final validLines = _lines.where((line) => line.quantity > 0).toList();
    if (validLines.isEmpty) {
      _error('حدد كمية مرتجعة لسطر واحد على الأقل');
      return;
    }

    for (final line in validLines) {
      if (line.quantity > line.originalQuantity) {
        _error('كمية المرتجع لا يمكن أن تتجاوز كمية فاتورة الشراء');
        return;
      }
    }

    final dto = CreatePurchaseReturnDto(
      purchaseBillId: _purchaseBillId!,
      returnDate: _returnDate,
      lines: validLines
          .map(
            (line) => CreatePurchaseReturnLineDto(
              purchaseBillLineId: line.purchaseBillLineId,
              quantity: line.quantity,
              unitCost: line.unitCost,
            ),
          )
          .toList(),
    );

    setState(() => _saving = true);
    final result = await ref.read(purchaseReturnsProvider.notifier).create(dto);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        ref.read(purchaseBillsProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ مرتجع الشراء وترحيله بنجاح')),
        );
        context.go(AppRoutes.purchaseReturns);
      },
      failure: (error) => _error(error.message),
    );
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

List<PurchaseReturnLineState> _linesFromBill(PurchaseBillModel bill) => bill.lines
    .map(
      (line) => PurchaseReturnLineState(
        purchaseBillLineId: line.id,
        description: line.description.isEmpty ? line.itemName : line.description,
        originalQuantity: line.quantity,
        unitCost: line.unitCost,
      ),
    )
    .toList();

class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.purchaseBillId,
    required this.returnDate,
    required this.billsAsync,
    required this.onBillChanged,
  });

  final String? purchaseBillId;
  final DateTime returnDate;
  final AsyncValue<List<PurchaseBillModel>> billsAsync;
  final ValueChanged<PurchaseBillModel?> onBillChanged;

  @override
  Widget build(BuildContext context) {
    final bills = billsAsync.maybeWhen(
      data: (data) => data
          .where((bill) => bill.status != 1 && bill.status != 3 && bill.lines.isNotEmpty)
          .toList(),
      orElse: () => <PurchaseBillModel>[],
    );
    final selected = bills.where((bill) => bill.id == purchaseBillId).firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selected?.id,
              decoration: const InputDecoration(
                labelText: 'فاتورة الشراء *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long_outlined),
              ),
              items: bills
                  .map<DropdownMenuItem<String>>(
                    (PurchaseBillModel bill) => DropdownMenuItem<String>(
                      value: bill.id,
                      child: Text('${bill.billNumber} - ${bill.vendorName} - ${bill.totalAmount.toStringAsFixed(2)}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final bill = bills.where((item) => item.id == value).firstOrNull;
                onBillChanged(bill);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              initialValue: _PurchaseReturnFormScreenState._dateOnly(returnDate),
              decoration: const InputDecoration(
                labelText: 'تاريخ المرتجع',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinesCard extends StatelessWidget {
  const _LinesCard({required this.lines, required this.onQuantityChanged});

  final List<PurchaseReturnLineState> lines;
  final void Function(int index, double quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('اختر فاتورة شراء لعرض سطورها.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: const [
                Expanded(flex: 3, child: Text('الصنف / الوصف')),
                Expanded(child: Text('كمية الفاتورة')),
                Expanded(child: Text('كمية المرتجع')),
                Expanded(child: Text('التكلفة')),
                Expanded(child: Text('Draft amount')),
              ],
            ),
            const Divider(),
            ...lines.asMap().entries.map(
                  (entry) => _LineRow(
                    index: entry.key,
                    line: entry.value,
                    onQuantityChanged: onQuantityChanged,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.index,
    required this.line,
    required this.onQuantityChanged,
  });

  final int index;
  final PurchaseReturnLineState line;
  final void Function(int index, double quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(line.description)),
          Expanded(child: Text(line.originalQuantity.toStringAsFixed(2))),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: TextFormField(
                initialValue: line.quantity == 0 ? '' : line.quantity.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                onChanged: (value) => onQuantityChanged(index, double.tryParse(value) ?? 0),
              ),
            ),
          ),
          Expanded(child: Text(line.unitCost.toStringAsFixed(2))),
          Expanded(child: Text(line.draftAmount.toStringAsFixed(2))),
        ],
      ),
    );
  }
}

class _DraftTotalCard extends StatelessWidget {
  const _DraftTotalCard({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: SizedBox(
        width: 360,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Draft return total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    total.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Official return totals, stock impact, and vendor credit posting are recalculated by the backend after save.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

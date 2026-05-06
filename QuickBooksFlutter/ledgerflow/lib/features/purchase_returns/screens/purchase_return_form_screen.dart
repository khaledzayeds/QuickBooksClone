// purchase_return_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

  double get total => quantity * unitCost;
}

class PurchaseReturnFormState {
  String? purchaseBillId;
  DateTime returnDate = DateTime.now();
  List<PurchaseReturnLineState> lines = [];

  double get total => lines.fold(0, (sum, line) => sum + line.total);
}

final purchaseReturnFormProvider =
    StateProvider.autoDispose<PurchaseReturnFormState>(
      (ref) => PurchaseReturnFormState(),
    );
final purchaseReturnSavingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class PurchaseReturnFormScreen extends ConsumerWidget {
  const PurchaseReturnFormScreen({super.key, this.billId});

  final String? billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(purchaseReturnFormProvider);
    final saving = ref.watch(purchaseReturnSavingProvider);
    final billsAsync = ref.watch(purchaseBillsProvider);

    if (billId != null && billId!.isNotEmpty && form.purchaseBillId == null) {
      billsAsync.whenData((bills) {
        final bill = bills.where((item) => item.id == billId).firstOrNull;
        if (bill == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(purchaseReturnFormProvider.notifier).state = _formFromBill(
            bill,
            form.returnDate,
          );
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('مرتجع شراء جديد'),
        actions: [
          TextButton(
            onPressed: saving
                ? null
                : () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.purchaseReturns),
            child: const Text('إلغاء'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: saving ? null : () => _save(context, ref),
            icon: saving
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
          _BillCard(form: form, billsAsync: billsAsync),
          const SizedBox(height: 24),
          _LinesCard(form: form),
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _TotalCard(total: form.total),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final form = ref.read(purchaseReturnFormProvider);
    if (form.purchaseBillId == null || form.purchaseBillId!.isEmpty) {
      _error(context, 'اختر فاتورة الشراء أولاً');
      return;
    }

    final validLines = form.lines.where((line) => line.quantity > 0).toList();
    if (validLines.isEmpty) {
      _error(context, 'حدد كمية مرتجعة لسطر واحد على الأقل');
      return;
    }

    for (final line in validLines) {
      if (line.quantity > line.originalQuantity) {
        _error(context, 'كمية المرتجع لا يمكن أن تتجاوز كمية فاتورة الشراء');
        return;
      }
    }

    final dto = CreatePurchaseReturnDto(
      purchaseBillId: form.purchaseBillId!,
      returnDate: form.returnDate,
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

    ref.read(purchaseReturnSavingProvider.notifier).state = true;
    final result = await ref.read(purchaseReturnsProvider.notifier).create(dto);
    ref.read(purchaseReturnSavingProvider.notifier).state = false;

    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.read(purchaseBillsProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ مرتجع الشراء وترحيله بنجاح')),
        );
        context.go(AppRoutes.purchaseReturns);
      },
      failure: (error) => _error(context, error.message),
    );
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static void _error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

PurchaseReturnFormState _formFromBill(
  PurchaseBillModel bill,
  DateTime returnDate,
) => PurchaseReturnFormState()
  ..purchaseBillId = bill.id
  ..returnDate = returnDate
  ..lines = bill.lines
      .map(
        (line) => PurchaseReturnLineState(
          purchaseBillLineId: line.id,
          description: line.description.isEmpty
              ? line.itemName
              : line.description,
          originalQuantity: line.quantity,
          unitCost: line.unitCost,
        ),
      )
      .toList();

class _BillCard extends ConsumerWidget {
  const _BillCard({required this.form, required this.billsAsync});

  final PurchaseReturnFormState form;
  final AsyncValue<List<PurchaseBillModel>> billsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = billsAsync.maybeWhen(
      data: (data) => data
          .where(
            (bill) =>
                bill.status != 1 && bill.status != 3 && bill.lines.isNotEmpty,
          )
          .toList(),
      orElse: () => <PurchaseBillModel>[],
    );
    final selected = bills
        .where((bill) => bill.id == form.purchaseBillId)
        .firstOrNull;

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
                      child: Text(
                        '${bill.billNumber} - ${bill.vendorName} - ${bill.totalAmount.toStringAsFixed(2)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final bill = bills
                    .where((item) => item.id == value)
                    .firstOrNull;
                ref
                    .read(purchaseReturnFormProvider.notifier)
                    .state = bill == null
                    ? (PurchaseReturnFormState()..returnDate = form.returnDate)
                    : _formFromBill(bill, form.returnDate);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              initialValue: PurchaseReturnFormScreen._dateOnly(form.returnDate),
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

class _LinesCard extends ConsumerWidget {
  const _LinesCard({required this.form});
  final PurchaseReturnFormState form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (form.lines.isEmpty) {
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
                Expanded(child: Text('الإجمالي')),
              ],
            ),
            const Divider(),
            ...form.lines.asMap().entries.map(
              (entry) =>
                  _LineRow(index: entry.key, line: entry.value, form: form),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineRow extends ConsumerWidget {
  const _LineRow({required this.index, required this.line, required this.form});

  final int index;
  final PurchaseReturnLineState line;
  final PurchaseReturnFormState form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                initialValue: line.quantity == 0
                    ? ''
                    : line.quantity.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  form.lines[index].quantity = double.tryParse(value) ?? 0;
                  _update(ref, form);
                },
              ),
            ),
          ),
          Expanded(child: Text(line.unitCost.toStringAsFixed(2))),
          Expanded(child: Text(line.total.toStringAsFixed(2))),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 320,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي المرتجع',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                total.toStringAsFixed(2),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _update(WidgetRef ref, PurchaseReturnFormState old) {
  ref
      .read(purchaseReturnFormProvider.notifier)
      .state = PurchaseReturnFormState()
    ..purchaseBillId = old.purchaseBillId
    ..returnDate = old.returnDate
    ..lines = List.from(old.lines);
}

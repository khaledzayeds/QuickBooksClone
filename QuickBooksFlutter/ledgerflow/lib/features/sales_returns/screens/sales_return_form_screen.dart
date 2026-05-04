// sales_return_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../invoices/data/models/invoice_model.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../data/models/sales_return_model.dart';
import '../providers/sales_returns_provider.dart';

class SalesReturnLineState {
  SalesReturnLineState({
    required this.invoiceLineId,
    required this.description,
    required this.originalQuantity,
    required this.unitPrice,
    this.quantity = 0,
    this.discountPercent = 0,
  });

  final String invoiceLineId;
  final String description;
  final double originalQuantity;
  final double unitPrice;
  double quantity;
  double discountPercent;

  double get total => quantity * unitPrice * (1 - (discountPercent / 100));
}

class SalesReturnFormState {
  String? invoiceId;
  DateTime returnDate = DateTime.now();
  List<SalesReturnLineState> lines = [];

  double get total => lines.fold(0, (sum, line) => sum + line.total);
}

final salesReturnFormProvider = StateProvider.autoDispose<SalesReturnFormState>((ref) => SalesReturnFormState());
final salesReturnSavingProvider = StateProvider.autoDispose<bool>((ref) => false);

class SalesReturnFormScreen extends ConsumerWidget {
  const SalesReturnFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(salesReturnFormProvider);
    final saving = ref.watch(salesReturnSavingProvider);
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مرتجع بيع جديد'),
        actions: [
          TextButton(
            onPressed: saving ? null : () => context.canPop() ? context.pop() : context.go(AppRoutes.salesReturns),
            child: const Text('إلغاء'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: saving ? null : () => _save(context, ref),
            icon: saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: const Text('حفظ المرتجع'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _InvoiceCard(form: form, invoicesAsync: invoicesAsync),
          const SizedBox(height: 24),
          _LinesCard(form: form),
          const SizedBox(height: 24),
          Align(alignment: AlignmentDirectional.centerEnd, child: _TotalCard(total: form.total)),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final form = ref.read(salesReturnFormProvider);
    if (form.invoiceId == null || form.invoiceId!.isEmpty) {
      _error(context, 'اختر الفاتورة أولاً');
      return;
    }

    final validLines = form.lines.where((line) => line.quantity > 0).toList();
    if (validLines.isEmpty) {
      _error(context, 'حدد كمية مرتجعة لسطر واحد على الأقل');
      return;
    }

    for (final line in validLines) {
      if (line.quantity > line.originalQuantity) {
        _error(context, 'كمية المرتجع لا يمكن أن تتجاوز كمية الفاتورة');
        return;
      }
    }

    final dto = CreateSalesReturnDto(
      invoiceId: form.invoiceId!,
      returnDate: form.returnDate,
      lines: validLines
          .map(
            (line) => CreateSalesReturnLineDto(
              invoiceLineId: line.invoiceLineId,
              quantity: line.quantity,
              unitPrice: line.unitPrice,
              discountPercent: line.discountPercent,
            ),
          )
          .toList(),
    );

    ref.read(salesReturnSavingProvider.notifier).state = true;
    final result = await ref.read(salesReturnsProvider.notifier).create(dto);
    ref.read(salesReturnSavingProvider.notifier).state = false;

    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.read(invoicesProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ مرتجع البيع وترحيله بنجاح')));
        context.go(AppRoutes.salesReturns);
      },
      failure: (error) => _error(context, error.message),
    );
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static void _error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
}

class _InvoiceCard extends ConsumerWidget {
  const _InvoiceCard({required this.form, required this.invoicesAsync});

  final SalesReturnFormState form;
  final AsyncValue<List<InvoiceModel>> invoicesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = invoicesAsync.maybeWhen(
      data: (data) => data.where((invoice) => !invoice.isVoid && invoice.lines.isNotEmpty).toList(),
      orElse: () => <InvoiceModel>[],
    );
    final selected = invoices.where((invoice) => invoice.id == form.invoiceId).firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selected?.id,
              decoration: const InputDecoration(
                labelText: 'الفاتورة *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long_outlined),
              ),
              items: invoices
                  .map(
                    (invoice) => DropdownMenuItem(
                      value: invoice.id,
                      child: Text('${invoice.invoiceNumber} - ${invoice.customerName ?? ''} - ${invoice.totalAmount.toStringAsFixed(2)}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final invoice = invoices.where((item) => item.id == value).firstOrNull;
                final newState = SalesReturnFormState()
                  ..invoiceId = value
                  ..returnDate = form.returnDate
                  ..lines = (invoice?.lines ?? const [])
                      .map(
                        (line) => SalesReturnLineState(
                          invoiceLineId: line.id,
                          description: line.description.isEmpty ? line.itemId : line.description,
                          originalQuantity: line.quantity,
                          unitPrice: line.unitPrice,
                          discountPercent: line.discountPercent,
                        ),
                      )
                      .toList();
                ref.read(salesReturnFormProvider.notifier).state = newState;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              initialValue: SalesReturnFormScreen._dateOnly(form.returnDate),
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
  final SalesReturnFormState form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (form.lines.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('اختر فاتورة لعرض سطورها.'),
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
                Expanded(child: Text('السعر')),
                Expanded(child: Text('الإجمالي')),
              ],
            ),
            const Divider(),
            ...form.lines.asMap().entries.map((entry) => _LineRow(index: entry.key, line: entry.value, form: form)),
          ],
        ),
      ),
    );
  }
}

class _LineRow extends ConsumerWidget {
  const _LineRow({required this.index, required this.line, required this.form});

  final int index;
  final SalesReturnLineState line;
  final SalesReturnFormState form;

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
                initialValue: line.quantity == 0 ? '' : line.quantity.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                onChanged: (value) {
                  form.lines[index].quantity = double.tryParse(value) ?? 0;
                  _update(ref, form);
                },
              ),
            ),
          ),
          Expanded(child: Text(line.unitPrice.toStringAsFixed(2))),
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
              const Text('إجمالي المرتجع', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(total.toStringAsFixed(2), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

void _update(WidgetRef ref, SalesReturnFormState old) {
  ref.read(salesReturnFormProvider.notifier).state = SalesReturnFormState()
    ..invoiceId = old.invoiceId
    ..returnDate = old.returnDate
    ..lines = List.from(old.lines);
}

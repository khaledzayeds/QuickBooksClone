// sales_return_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  double get draftAmount =>
      quantity * unitPrice * (1 - (discountPercent / 100));
}

class SalesReturnFormScreen extends ConsumerStatefulWidget {
  const SalesReturnFormScreen({super.key, this.invoiceId});

  final String? invoiceId;

  @override
  ConsumerState<SalesReturnFormScreen> createState() =>
      _SalesReturnFormScreenState();
}

class _SalesReturnFormScreenState extends ConsumerState<SalesReturnFormScreen> {
  String? _invoiceId;
  final DateTime _returnDate = DateTime.now();
  List<SalesReturnLineState> _lines = [];
  bool _saving = false;
  bool _prefillApplied = false;

  double get _draftTotal =>
      _lines.fold(0, (sum, line) => sum + line.draftAmount);

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final invoices = invoicesAsync.maybeWhen(
      data: _returnableInvoices,
      orElse: () => <InvoiceModel>[],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyInvoicePrefill(invoices);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('مرتجع بيع جديد'),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.salesReturns),
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
          _InvoiceCard(
            invoiceId: _invoiceId,
            returnDate: _returnDate,
            invoices: invoices,
            onInvoiceChanged: _selectInvoice,
          ),
          const SizedBox(height: 24),
          _LinesCard(
            lines: _lines,
            onQuantityChanged: (index, quantity) =>
                setState(() => _lines[index].quantity = quantity),
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

  void _selectInvoice(InvoiceModel? invoice) {
    setState(() {
      if (invoice == null) {
        _invoiceId = null;
        _lines = [];
        return;
      }

      _invoiceId = invoice.id;
      _lines = invoice.lines
          .map(
            (line) => SalesReturnLineState(
              invoiceLineId: line.id,
              description: line.description.isEmpty
                  ? line.itemId
                  : line.description,
              originalQuantity: line.quantity,
              unitPrice: line.unitPrice,
              discountPercent: line.discountPercent,
            ),
          )
          .toList();
    });
  }

  List<InvoiceModel> _returnableInvoices(List<InvoiceModel> invoices) {
    return invoices
        .where(
          (invoice) =>
              invoice.isCreditInvoice &&
              !invoice.isVoid &&
              invoice.lines.isNotEmpty &&
              invoice.postedTransactionId != null,
        )
        .toList();
  }

  void _applyInvoicePrefill(List<InvoiceModel> invoices) {
    if (_prefillApplied || (widget.invoiceId ?? '').isEmpty) return;
    final invoice = invoices
        .where((item) => item.id == widget.invoiceId)
        .firstOrNull;
    if (invoice == null) return;
    _prefillApplied = true;
    _selectInvoice(invoice);
  }

  Future<void> _save() async {
    if (_invoiceId == null || _invoiceId!.isEmpty) {
      _error(context, 'اختر الفاتورة أولاً');
      return;
    }

    final validLines = _lines.where((line) => line.quantity > 0).toList();
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
      invoiceId: _invoiceId!,
      returnDate: _returnDate,
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

    setState(() => _saving = true);
    final result = await ref.read(salesReturnsProvider.notifier).create(dto);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        ref.read(invoicesProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ مرتجع البيع وترحيله بنجاح')),
        );
        context.go(AppRoutes.salesReturns);
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

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoiceId,
    required this.returnDate,
    required this.invoices,
    required this.onInvoiceChanged,
  });

  final String? invoiceId;
  final DateTime returnDate;
  final List<InvoiceModel> invoices;
  final ValueChanged<InvoiceModel?> onInvoiceChanged;

  @override
  Widget build(BuildContext context) {
    final selected = invoices
        .where((invoice) => invoice.id == invoiceId)
        .firstOrNull;

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
                  .map<DropdownMenuItem<String>>(
                    (InvoiceModel invoice) => DropdownMenuItem<String>(
                      value: invoice.id,
                      child: Text(
                        '${invoice.invoiceNumber} - ${invoice.customerName ?? ''} - ${invoice.totalAmount.toStringAsFixed(2)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final invoice = invoices
                    .where((item) => item.id == value)
                    .firstOrNull;
                onInvoiceChanged(invoice);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              initialValue: _SalesReturnFormScreenState._dateOnly(returnDate),
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

  final List<SalesReturnLineState> lines;
  final void Function(int index, double quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
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
  final SalesReturnLineState line;
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
                onChanged: (value) =>
                    onQuantityChanged(index, double.tryParse(value) ?? 0),
              ),
            ),
          ),
          Expanded(child: Text(line.unitPrice.toStringAsFixed(2))),
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
                  const Text(
                    'Draft return total',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                'Official return totals, stock impact, customer credit, and accounting posting are recalculated by the backend after save.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

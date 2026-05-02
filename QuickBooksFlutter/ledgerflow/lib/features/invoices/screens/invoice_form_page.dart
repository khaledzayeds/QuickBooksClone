// invoice_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../core/widgets/transaction_line_table.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../data/models/invoice_contracts.dart';
import '../providers/invoices_state.dart';

class InvoiceFormPage extends ConsumerStatefulWidget {
  const InvoiceFormPage({super.key});

  @override
  ConsumerState<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends ConsumerState<InvoiceFormPage> {
  CustomerModel? _selectedCustomer;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  bool _saving = false;

  final List<TransactionLineEntry> _lines = [TransactionLineEntry()];

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double get _subtotal => _lines.fold(0, (sum, line) => sum + line.amount);

  Future<void> _save({required bool post}) async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedCustomer == null) {
      _showError(l10n.selectCustomer);
      return;
    }
    if (_dueDate.isBefore(_invoiceDate)) {
      _showError('${l10n.dueDate} < ${l10n.billDate}');
      return;
    }

    final validLines = _lines
        .where((line) => line.itemId != null && line.qty > 0 && line.rate >= 0)
        .toList();
    if (validLines.isEmpty) {
      _showError(l10n.minOneQty);
      return;
    }

    final dto = CreateInvoiceDto(
      customerId: _selectedCustomer!.id,
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      saveMode: post ? 2 : 1,
      lines: validLines
          .map(
            (line) => CreateInvoiceLineDto(
              itemId: line.itemId!,
              description: line.descCtrl.text.trim().isEmpty
                  ? line.itemName
                  : line.descCtrl.text.trim(),
              quantity: line.qty,
              unitPrice: line.rate,
            ),
          )
          .toList(),
    );

    setState(() => _saving = true);
    try {
      final result = await ref.read(invoicesRepoProvider).create(dto);
      result.when(
        success: (_) {
          ref.read(invoicesStateProvider.notifier).refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.billCreatedSuccess)),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/sales/invoices');
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.createInvoice} | ${l10n.creditSale}'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: _saving ? null : () => _save(post: true),
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? l10n.saving : l10n.save),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(
              selectedCustomer: _selectedCustomer,
              onCustomerChanged: (customer) => setState(() => _selectedCustomer = customer),
              invoiceDate: _invoiceDate,
              onInvoiceDateChanged: (date) => setState(() => _invoiceDate = date),
              dueDate: _dueDate,
              onDueDateChanged: (date) => setState(() => _dueDate = date),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.items,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: TransactionLineTable(
                  lines: _lines,
                  priceMode: TransactionLinePriceMode.sales,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _TotalsCard(subtotal: _subtotal),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/sales/invoices');
                }
              },
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : () => _save(post: false),
              icon: const Icon(Icons.drafts_outlined),
              label: Text(l10n.saveDraft),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _saving ? null : () => _save(post: true),
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(l10n.createInvoice),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({
    required this.selectedCustomer,
    required this.onCustomerChanged,
    required this.invoiceDate,
    required this.onInvoiceDateChanged,
    required this.dueDate,
    required this.onDueDateChanged,
  });

  final CustomerModel? selectedCustomer;
  final ValueChanged<CustomerModel?> onCustomerChanged;
  final DateTime invoiceDate;
  final ValueChanged<DateTime> onInvoiceDateChanged;
  final DateTime dueDate;
  final ValueChanged<DateTime> onDueDateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final customersAsync = ref.watch(customersProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: customersAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(e.toString()),
                    data: (customers) {
                      final activeCustomers = customers.where((c) => c.isActive).toList();
                      return DropdownButtonFormField<CustomerModel>(
                        value: selectedCustomer,
                        decoration: InputDecoration(
                          labelText: l10n.customer,
                          hintText: l10n.selectCustomer,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        items: activeCustomers
                            .map(
                              (customer) => DropdownMenuItem(
                                value: customer,
                                child: Text(customer.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: onCustomerChanged,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DatePickerField(
                    label: l10n.billDate,
                    value: invoiceDate,
                    onChanged: onInvoiceDateChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DatePickerField(
                    label: l10n.dueDate,
                    value: dueDate,
                    onChanged: onDueDateChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.creditSale,
                    style: TextStyle(color: cs.onSurfaceVariant),
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

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text('${value.day}/${value.month}/${value.year}'),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.subtotal});
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SizedBox(
      width: 320,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _AmountRow(label: l10n.subtotal, amount: subtotal),
              const SizedBox(height: 8),
              _AmountRow(label: l10n.tax, amount: 0),
              const Divider(height: 24),
              _AmountRow(label: l10n.total, amount: subtotal, isTotal: true),
              const SizedBox(height: 8),
              Text(l10n.creditSale, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  final String label;
  final double amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount.toStringAsFixed(2), style: style),
      ],
    );
  }
}

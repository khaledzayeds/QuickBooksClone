// sales_receipt_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../core/constants/api_enums.dart';
import '../../../core/widgets/transaction_line_table.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../data/models/sales_receipt_models.dart';
import '../providers/sales_receipts_provider.dart';

class SalesReceiptFormScreen extends ConsumerStatefulWidget {
  const SalesReceiptFormScreen({super.key});

  @override
  ConsumerState<SalesReceiptFormScreen> createState() =>
      _SalesReceiptFormScreenState();
}

class _SalesReceiptFormScreenState
    extends ConsumerState<SalesReceiptFormScreen> {
  CustomerModel? _selectedCustomer;
  String? _depositAccountId;
  DateTime _receiptDate = DateTime.now();
  String _paymentMethod = 'Cash';
  bool _saving = false;

  final List<TransactionLineEntry> _lines = [TransactionLineEntry()];

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedCustomer == null) {
      _showError(l10n.selectCustomer);
      return;
    }
    if (_depositAccountId == null || _depositAccountId!.isEmpty) {
      _showError(l10n.selectDepositAccount);
      return;
    }

    final validLines = _lines
        .where((line) => line.itemId != null && line.qty > 0 && line.rate >= 0)
        .toList();
    if (validLines.isEmpty) {
      _showError(l10n.minOneQty);
      return;
    }

    final dto = CreateSalesReceiptDto(
      customerId: _selectedCustomer!.id,
      receiptDate: _receiptDate,
      depositAccountId: _depositAccountId!,
      paymentMethod: _paymentMethod,
      lines: validLines
          .map(
            (line) => CreateSalesReceiptLineDto(
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
      final result = await ref
          .read(salesReceiptsRepositoryProvider)
          .create(dto);
      result.when(
        success: (_) {
          ref.read(salesReceiptsProvider.notifier).refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.salesReceiptCreatedSuccess)),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/sales/receipts');
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

  double get _subtotal => _lines.fold(0, (sum, line) => sum + line.amount);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.newSalesReceipt} | ${l10n.paidNowSale}'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
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
              onCustomerChanged: (customer) =>
                  setState(() => _selectedCustomer = customer),
              receiptDate: _receiptDate,
              onDateChanged: (date) => setState(() => _receiptDate = date),
              depositAccountId: _depositAccountId,
              onDepositAccountChanged: (id) =>
                  setState(() => _depositAccountId = id),
              paymentMethod: _paymentMethod,
              onPaymentMethodChanged: (method) =>
                  setState(() => _paymentMethod = method),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.items,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
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
                  context.go('/sales/receipts');
                }
              },
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.point_of_sale),
              label: Text(l10n.createSalesReceipt),
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
    required this.receiptDate,
    required this.onDateChanged,
    required this.depositAccountId,
    required this.onDepositAccountChanged,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
  });

  final CustomerModel? selectedCustomer;
  final ValueChanged<CustomerModel?> onCustomerChanged;
  final DateTime receiptDate;
  final ValueChanged<DateTime> onDateChanged;
  final String? depositAccountId;
  final ValueChanged<String?> onDepositAccountChanged;
  final String paymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final customersAsync = ref.watch(customersProvider);
    final accountsAsync = ref.watch(accountsProvider);

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
                      final activeCustomers = customers
                          .where((c) => c.isActive)
                          .toList();
                      final uniqueCustomers = <CustomerModel>[];
                      final seenCustomerIds = <String>{};
                      for (final customer in activeCustomers) {
                        if (seenCustomerIds.add(customer.id)) {
                          uniqueCustomers.add(customer);
                        }
                      }
                      final selectedCustomerId =
                          selectedCustomer != null &&
                              seenCustomerIds.contains(selectedCustomer!.id)
                          ? selectedCustomer!.id
                          : null;
                      return DropdownButtonFormField<String>(
                        initialValue: selectedCustomerId,
                        decoration: InputDecoration(
                          labelText: l10n.customer,
                          hintText: l10n.selectCustomer,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        items: uniqueCustomers
                            .map(
                              (customer) => DropdownMenuItem(
                                value: customer.id,
                                child: Text(customer.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (id) {
                          final customer = id == null
                              ? null
                              : uniqueCustomers
                                    .where((customer) => customer.id == id)
                                    .firstOrNull;
                          onCustomerChanged(customer);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DatePickerField(
                    label: l10n.receiptDate,
                    value: receiptDate,
                    onChanged: onDateChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: accountsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(e.toString()),
                    data: (accounts) {
                      final depositAccounts = accounts
                          .where(
                            (account) =>
                                account.isActive &&
                                (account.accountType == AccountType.bank ||
                                    account.accountType ==
                                        AccountType.otherCurrentAsset),
                          )
                          .toList();
                      return DropdownButtonFormField<String>(
                        initialValue: depositAccountId,
                        decoration: InputDecoration(
                          labelText: l10n.depositAccount,
                          hintText: l10n.depositAccountHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.account_balance),
                        ),
                        items: depositAccounts
                            .map(
                              (account) => DropdownMenuItem(
                                value: account.id,
                                child: Text(
                                  '${account.code} - ${account.name}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: onDepositAccountChanged,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: InputDecoration(
                      labelText: l10n.paymentMethod,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Check', child: Text('Check')),
                      DropdownMenuItem(
                        value: 'BankTransfer',
                        child: Text('Bank Transfer'),
                      ),
                      DropdownMenuItem(
                        value: 'CreditCard',
                        child: Text('Credit Card'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onPaymentMethodChanged(value);
                    },
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
                    l10n.paidNowSale,
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
              Text(l10n.salesReceipt, style: theme.textTheme.bodySmall),
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
        ? Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount.toStringAsFixed(2), style: style),
      ],
    );
  }
}

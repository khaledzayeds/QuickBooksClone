// payment_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_enums.dart' show AccountType, PaymentMethod;
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../invoices/data/models/invoice_model.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../data/models/payment_model.dart';
import '../data/models/receive_payment_models.dart';
import '../providers/payments_provider.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({super.key});

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  CustomerModel? _customer;
  AccountModel? _depositAccount;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  DateTime _paymentDate = DateTime.now();
  bool _saving = false;
  final _customerCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final List<ReceivePaymentInvoiceAllocation> _allocations = [];

  @override
  void initState() {
    super.initState();
    _syncDate();
  }

  @override
  void dispose() {
    _customerCtrl.dispose();
    _depositCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  String _fmtMoney(double value) => NumberFormat('#,##0.00').format(value);

  void _syncDate() => _dateCtrl.text = _fmtDate(_paymentDate);

  double get _totalSelected => _allocations
      .where((allocation) => allocation.selected)
      .fold(0, (sum, allocation) => sum + allocation.amount);

  int get _selectedCount => _allocations.where((allocation) => allocation.selected).length;

  void _loadCustomerInvoices(List<InvoiceModel> invoices, CustomerModel customer) {
    final openInvoices = invoices
        .where(
          (invoice) =>
              invoice.customerId == customer.id &&
              invoice.isCreditInvoice &&
              !invoice.isVoid &&
              invoice.postedTransactionId != null &&
              invoice.balanceDue > 0,
        )
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    setState(() {
      _customer = customer;
      _customerCtrl.text = customer.displayName;
      _allocations
        ..clear()
        ..addAll(openInvoices.map((invoice) => ReceivePaymentInvoiceAllocation(invoice: invoice)));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _paymentDate = picked;
      _syncDate();
    });
  }

  void _autoApplyOldestFirst() {
    setState(() {
      for (final allocation in _allocations) {
        allocation.selected = true;
        allocation.amount = allocation.balanceDue;
      }
    });
  }

  void _clearAllocations() {
    setState(() {
      for (final allocation in _allocations) {
        allocation.selected = false;
        allocation.amount = allocation.balanceDue;
      }
    });
  }

  Future<void> _save() async {
    if (_customer == null) {
      _showError('Select a customer first.');
      return;
    }
    if (_depositAccount == null) {
      _showError('Select a deposit account first.');
      return;
    }

    final selected = _allocations
        .where((allocation) => allocation.selected && allocation.amount > 0)
        .toList();
    if (selected.isEmpty) {
      _showError('Select at least one invoice to receive payment.');
      return;
    }

    for (final allocation in selected) {
      if (allocation.amount > allocation.balanceDue) {
        _showError('Payment for invoice ${allocation.invoiceNumber} exceeds balance due.');
        return;
      }
    }

    final dto = ReceivePaymentDto(
      customerId: _customer!.id,
      depositAccountId: _depositAccount!.id,
      paymentDate: _paymentDate,
      paymentMethod: _paymentMethod,
      allocations: selected
          .map(
            (allocation) => ReceivePaymentAllocationDto(
              invoiceId: allocation.invoiceId,
              amount: allocation.amount,
            ),
          )
          .toList(),
    );

    setState(() => _saving = true);
    final result = await ref.read(paymentsProvider.notifier).receive(dto);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (payments) {
        ref.read(invoicesProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Received ${payments.length} payment allocation(s).')),
        );
        context.go('/sales/payments');
      },
      failure: (error) => _showError(error.message),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final invoicesAsync = ref.watch(invoicesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final customers = customersAsync.maybeWhen(
      data: (items) => items.where((customer) => customer.isActive).toList(),
      orElse: () => const <CustomerModel>[],
    );
    final invoices = invoicesAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <InvoiceModel>[],
    );
    final depositAccounts = accountsAsync.maybeWhen(
      data: (accounts) => accounts
          .where(
            (account) =>
                account.isActive &&
                (account.accountType == AccountType.bank ||
                    account.accountType == AccountType.otherCurrentAsset),
          )
          .toList(),
      orElse: () => const <AccountModel>[],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            _ReceivePaymentToolbar(
              saving: _saving,
              total: _totalSelected,
              selectedCount: _selectedCount,
              onClose: () => context.canPop() ? context.pop() : context.go('/sales/payments'),
              onSave: _save,
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _HeaderPanel(
                          customers: customers,
                          invoices: invoices,
                          depositAccounts: depositAccounts,
                          customer: _customer,
                          depositAccount: _depositAccount,
                          paymentMethod: _paymentMethod,
                          customerController: _customerCtrl,
                          depositController: _depositCtrl,
                          dateController: _dateCtrl,
                          onCustomerSelected: (customer) => _loadCustomerInvoices(invoices, customer),
                          onCustomerCleared: () {
                            setState(() {
                              _customer = null;
                              _customerCtrl.clear();
                              _allocations.clear();
                            });
                          },
                          onDepositSelected: (account) {
                            setState(() {
                              _depositAccount = account;
                              _depositCtrl.text = account.name;
                            });
                          },
                          onDepositCleared: () {
                            setState(() {
                              _depositAccount = null;
                              _depositCtrl.clear();
                            });
                          },
                          onPaymentMethodChanged: (method) => setState(() => _paymentMethod = method),
                          onPickDate: _pickDate,
                        ),
                        _AllocationActions(
                          enabled: _allocations.isNotEmpty,
                          onAutoApply: _autoApplyOldestFirst,
                          onClear: _clearAllocations,
                        ),
                        Expanded(
                          child: _OpenInvoiceAllocationGrid(
                            allocations: _allocations,
                            fmtMoney: _fmtMoney,
                            onChanged: () => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SummaryPanel(
                    customer: _customer,
                    allocations: _allocations,
                    total: _totalSelected,
                    fmtMoney: _fmtMoney,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivePaymentToolbar extends StatelessWidget {
  const _ReceivePaymentToolbar({
    required this.saving,
    required this.total,
    required this.selectedCount,
    required this.onClose,
    required this.onSave,
  });

  final bool saving;
  final double total;
  final int selectedCount;
  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(onPressed: saving ? null : onClose, icon: const Icon(Icons.arrow_back)),
          const SizedBox(width: 8),
          Text('Receive Payment', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(width: 12),
          Text('Sales / Payments / New', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const Spacer(),
          Text('$selectedCount invoice(s) • ${NumberFormat('#,##0.00').format(total)}', style: theme.textTheme.labelLarge),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: saving ? null : onClose,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.task_alt_outlined, size: 16),
            label: Text(saving ? 'Posting...' : 'Save & Post'),
          ),
        ],
      ),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({
    required this.customers,
    required this.invoices,
    required this.depositAccounts,
    required this.customer,
    required this.depositAccount,
    required this.paymentMethod,
    required this.customerController,
    required this.depositController,
    required this.dateController,
    required this.onCustomerSelected,
    required this.onCustomerCleared,
    required this.onDepositSelected,
    required this.onDepositCleared,
    required this.onPaymentMethodChanged,
    required this.onPickDate,
  });

  final List<CustomerModel> customers;
  final List<InvoiceModel> invoices;
  final List<AccountModel> depositAccounts;
  final CustomerModel? customer;
  final AccountModel? depositAccount;
  final PaymentMethod paymentMethod;
  final TextEditingController customerController;
  final TextEditingController depositController;
  final TextEditingController dateController;
  final ValueChanged<CustomerModel> onCustomerSelected;
  final VoidCallback onCustomerCleared;
  final ValueChanged<AccountModel> onDepositSelected;
  final VoidCallback onDepositCleared;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedCustomerId = customer?.id;
    final safeDepositId = depositAccounts.any((account) => account.id == depositAccount?.id) ? depositAccount?.id : null;
    final customerOpenCount = selectedCustomerId == null
        ? 0
        : invoices
            .where((invoice) =>
                invoice.customerId == selectedCustomerId &&
                invoice.isCreditInvoice &&
                !invoice.isVoid &&
                invoice.postedTransactionId != null &&
                invoice.balanceDue > 0)
            .length;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: customers.any((item) => item.id == selectedCustomerId) ? selectedCustomerId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Customer *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                  items: customers
                      .map((item) => DropdownMenuItem<String>(value: item.id, child: Text(item.displayName)))
                      .toList(),
                  onChanged: (id) {
                    final selected = customers.where((item) => item.id == id).firstOrNull;
                    if (selected != null) onCustomerSelected(selected);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: dateController,
                  readOnly: true,
                  onTap: onPickDate,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Payment Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<PaymentMethod>(
                  value: paymentMethod,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: PaymentMethod.cash, child: Text('Cash')),
                    DropdownMenuItem(value: PaymentMethod.check, child: Text('Check')),
                    DropdownMenuItem(value: PaymentMethod.bankTransfer, child: Text('Bank Transfer')),
                    DropdownMenuItem(value: PaymentMethod.creditCard, child: Text('Card')),
                  ],
                  onChanged: (value) {
                    if (value != null) onPaymentMethodChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: safeDepositId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Deposit Account *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  items: depositAccounts
                      .map((account) => DropdownMenuItem<String>(value: account.id, child: Text('${account.code} - ${account.name}')))
                      .toList(),
                  onChanged: (id) {
                    final selected = depositAccounts.where((item) => item.id == id).firstOrNull;
                    if (selected != null) onDepositSelected(selected);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallInfoTile(
                  label: 'Open invoices',
                  value: customer == null ? '-' : customerOpenCount.toString(),
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallInfoTile(
                  label: 'Customer balance',
                  value: customer == null ? '-' : NumberFormat('#,##0.00').format(customer!.balance),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallInfoTile extends StatelessWidget {
  const _SmallInfoTile({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocationActions extends StatelessWidget {
  const _AllocationActions({required this.enabled, required this.onAutoApply, required this.onClear});
  final bool enabled;
  final VoidCallback onAutoApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant), bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          const Text('Open invoices', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Text('Select invoices and edit payment amount per row.', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const Spacer(),
          TextButton.icon(
            onPressed: enabled ? onAutoApply : null,
            icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
            label: const Text('Auto apply'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: enabled ? onClear : null,
            icon: const Icon(Icons.clear_all_outlined, size: 16),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _OpenInvoiceAllocationGrid extends StatelessWidget {
  const _OpenInvoiceAllocationGrid({
    required this.allocations,
    required this.fmtMoney,
    required this.onChanged,
  });

  final List<ReceivePaymentInvoiceAllocation> allocations;
  final String Function(double value) fmtMoney;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (allocations.isEmpty) {
      return Center(
        child: Text(
          'Select a customer with posted open credit invoices.',
          style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: [
            _GridHeader(cs: cs),
            ...allocations.asMap().entries.map((entry) {
              final index = entry.key;
              final allocation = entry.value;
              return _AllocationRow(
                allocation: allocation,
                shaded: index.isOdd,
                fmtMoney: fmtMoney,
                onChanged: onChanged,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GridHeader extends StatelessWidget {
  const _GridHeader({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.onSurfaceVariant);
    return Container(
      height: 34,
      color: cs.surfaceContainerHighest,
      child: Row(
        children: [
          const SizedBox(width: 46),
          _HeaderCell('Invoice #', flex: 2, style: style),
          _HeaderCell('Date', flex: 1, style: style),
          _HeaderCell('Due Date', flex: 1, style: style),
          _HeaderCell('Original', flex: 1, style: style, right: true),
          _HeaderCell('Paid', flex: 1, style: style, right: true),
          _HeaderCell('Balance', flex: 1, style: style, right: true),
          _HeaderCell('Payment Amount', flex: 1, style: style, right: true),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex, required this.style, this.right = false});
  final String text;
  final int flex;
  final TextStyle style;
  final bool right;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(text, textAlign: right ? TextAlign.right : TextAlign.left, style: style),
      ),
    );
  }
}

class _AllocationRow extends StatefulWidget {
  const _AllocationRow({
    required this.allocation,
    required this.shaded,
    required this.fmtMoney,
    required this.onChanged,
  });

  final ReceivePaymentInvoiceAllocation allocation;
  final bool shaded;
  final String Function(double value) fmtMoney;
  final VoidCallback onChanged;

  @override
  State<_AllocationRow> createState() => _AllocationRowState();
}

class _AllocationRowState extends State<_AllocationRow> {
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.allocation.amount.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant _AllocationRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allocation != widget.allocation) {
      _amountCtrl.text = widget.allocation.amount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allocation = widget.allocation;
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Container(
      height: 42,
      color: widget.shaded ? cs.primaryContainer.withOpacity(0.10) : cs.surface,
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Checkbox(
              value: allocation.selected,
              onChanged: (value) {
                setState(() {
                  allocation.selected = value ?? false;
                  if (allocation.selected && allocation.amount <= 0) {
                    allocation.amount = allocation.balanceDue;
                    _amountCtrl.text = allocation.amount.toStringAsFixed(2);
                  }
                });
                widget.onChanged();
              },
            ),
          ),
          _Cell(allocation.invoiceNumber, flex: 2),
          _Cell(dateFmt.format(allocation.invoiceDate), flex: 1),
          _Cell(dateFmt.format(allocation.dueDate), flex: 1),
          _Cell(widget.fmtMoney(allocation.originalAmount), flex: 1, right: true),
          _Cell(widget.fmtMoney(allocation.paidAmount), flex: 1, right: true),
          _Cell(widget.fmtMoney(allocation.balanceDue), flex: 1, right: true, bold: true),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: TextField(
                controller: _amountCtrl,
                textAlign: TextAlign.right,
                enabled: allocation.selected,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (value) {
                  allocation.amount = double.tryParse(value) ?? 0;
                  widget.onChanged();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {required this.flex, this.right = false, this.bold = false});
  final String text;
  final int flex;
  final bool right;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: right ? TextAlign.right : TextAlign.left,
          style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w500),
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.customer,
    required this.allocations,
    required this.total,
    required this.fmtMoney,
  });

  final CustomerModel? customer;
  final List<ReceivePaymentInvoiceAllocation> allocations;
  final double total;
  final String Function(double value) fmtMoney;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = allocations.where((allocation) => allocation.selected).toList();
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(left: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Customer', value: customer?.displayName ?? '-'),
          _SummaryRow(label: 'Selected invoices', value: selected.length.toString()),
          _SummaryRow(label: 'Open invoices', value: allocations.length.toString()),
          const Divider(height: 28),
          Text('Amount received', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            fmtMoney(total),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary),
          ),
          const SizedBox(height: 16),
          if (selected.isNotEmpty)
            Expanded(
              child: ListView.separated(
                itemCount: selected.length,
                separatorBuilder: (_, __) => Divider(color: cs.outlineVariant),
                itemBuilder: (context, index) {
                  final row = selected[index];
                  return Row(
                    children: [
                      Expanded(child: Text(row.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text(fmtMoney(row.amount)),
                    ],
                  );
                },
              ),
            )
          else
            Text('No invoices selected.', style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

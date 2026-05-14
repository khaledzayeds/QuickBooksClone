// payment_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
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
  const PaymentFormScreen({super.key, this.invoiceId});

  final String? invoiceId;

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  CustomerModel? _customer;
  AccountModel? _depositAccount;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  DateTime _paymentDate = DateTime.now();
  bool _saving = false;
  bool _prefillApplied = false;
  final List<ReceivePaymentInvoiceAllocation> _allocations = [];

  final _moneyFmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  double get _amountReceived => _selectedAllocations.fold(
    0,
    (sum, allocation) => sum + allocation.amount,
  );

  double get _openBalance =>
      _allocations.fold(0, (sum, allocation) => sum + allocation.balanceDue);

  List<ReceivePaymentInvoiceAllocation> get _selectedAllocations => _allocations
      .where((allocation) => allocation.selected && allocation.amount > 0)
      .toList();

  int get _selectedCount => _selectedAllocations.length;

  String _money(double value) => _moneyFmt.format(value);

  void _loadCustomerInvoices(
    List<InvoiceModel> invoices,
    CustomerModel customer, {
    String? selectedInvoiceId,
  }) {
    final openInvoices =
        invoices
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
      _allocations
        ..clear()
        ..addAll(
          openInvoices.map(
            (invoice) => ReceivePaymentInvoiceAllocation(
              invoice: invoice,
              selected:
                  selectedInvoiceId != null && invoice.id == selectedInvoiceId,
            ),
          ),
        );
    });
  }

  void _applyInvoicePrefill(
    List<InvoiceModel> invoices,
    List<CustomerModel> customers,
  ) {
    if (_prefillApplied || (widget.invoiceId ?? '').isEmpty) return;
    final invoice = invoices
        .where((item) => item.id == widget.invoiceId && item.balanceDue > 0)
        .firstOrNull;
    if (invoice == null) return;
    final customer = customers
        .where((item) => item.id == invoice.customerId)
        .firstOrNull;
    if (customer == null) return;
    _prefillApplied = true;
    _loadCustomerInvoices(invoices, customer, selectedInvoiceId: invoice.id);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !mounted) return;
    setState(() => _paymentDate = picked);
  }

  void _autoApplyOldestFirst() {
    setState(() {
      for (final allocation in _allocations) {
        allocation.selected = true;
        allocation.amount = allocation.balanceDue;
      }
    });
  }

  void _clearPayment() {
    setState(() {
      _customer = null;
      _depositAccount = null;
      _paymentMethod = PaymentMethod.cash;
      _paymentDate = DateTime.now();
      _allocations.clear();
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
    if (_selectedAllocations.isEmpty) {
      _showError('Select at least one open invoice.');
      return;
    }

    for (final allocation in _selectedAllocations) {
      if (allocation.amount > allocation.balanceDue) {
        _showError(
          'Payment for ${allocation.invoiceNumber} exceeds the open balance.',
        );
        return;
      }
    }

    final dto = ReceivePaymentDto(
      customerId: _customer!.id,
      depositAccountId: _depositAccount!.id,
      paymentDate: _paymentDate,
      paymentMethod: _paymentMethod,
      allocations: _selectedAllocations
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
          SnackBar(content: Text('Posted ${payments.length} payment line(s).')),
        );
        context.go(AppRoutes.payments);
      },
      failure: (error) => _showError(error.message),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyInvoicePrefill(invoices, customers);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: SafeArea(
        child: Column(
          children: [
            _PaymentCommandBar(
              saving: _saving,
              onFind: () => context.go(AppRoutes.payments),
              onNew: () => context.go(AppRoutes.paymentNew),
              onSave: _saving ? null : _save,
              onClear: _clearPayment,
              onClose: () => context.go(AppRoutes.payments),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(10, 8, 0, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFB9C3CA)),
                      ),
                      child: Column(
                        children: [
                          _PaymentHeader(
                            customers: customers,
                            invoices: invoices,
                            depositAccounts: depositAccounts,
                            customer: _customer,
                            depositAccount: _depositAccount,
                            paymentMethod: _paymentMethod,
                            paymentDate: _paymentDate,
                            dateText: _dateFmt.format(_paymentDate),
                            openBalance: _openBalance,
                            amountReceived: _amountReceived,
                            onCustomerSelected: (customer) =>
                                _loadCustomerInvoices(invoices, customer),
                            onDepositSelected: (account) =>
                                setState(() => _depositAccount = account),
                            onPaymentMethodChanged: (method) =>
                                setState(() => _paymentMethod = method),
                            onPickDate: _pickDate,
                            money: _money,
                          ),
                          _AllocationToolbar(
                            enabled: _allocations.isNotEmpty,
                            selectedCount: _selectedCount,
                            amountReceived: _amountReceived,
                            money: _money,
                            onAutoApply: _autoApplyOldestFirst,
                            onClear: _clearAllocations,
                          ),
                          Expanded(
                            child: _PaymentAllocationGrid(
                              allocations: _allocations,
                              money: _money,
                              date: _dateFmt.format,
                              onChanged: () => setState(() {}),
                            ),
                          ),
                          _PaymentFooter(
                            amountReceived: _amountReceived,
                            selectedCount: _selectedCount,
                            money: _money,
                            saving: _saving,
                            onSave: _saving ? null : _save,
                            onClear: _clearAllocations,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _PaymentSidePanel(
                    customer: _customer,
                    depositAccount: _depositAccount,
                    paymentMethod: _paymentMethod,
                    allocations: _allocations,
                    amountReceived: _amountReceived,
                    openBalance: _openBalance,
                    money: _money,
                  ),
                ],
              ),
            ),
            const _ShortcutStrip(),
          ],
        ),
      ),
    );
  }
}

class _PaymentCommandBar extends StatelessWidget {
  const _PaymentCommandBar({
    required this.saving,
    required this.onFind,
    required this.onNew,
    required this.onClear,
    required this.onClose,
    this.onSave,
  });

  final bool saving;
  final VoidCallback onFind;
  final VoidCallback onNew;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F6F7),
        border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const _Tool(icon: Icons.arrow_back, label: 'Prev'),
          const _Tool(icon: Icons.arrow_forward, label: 'Next'),
          _Tool(icon: Icons.search, label: 'Find', onTap: onFind),
          _Tool(icon: Icons.note_add_outlined, label: 'New', onTap: onNew),
          _Tool(
            icon: saving ? Icons.hourglass_top : Icons.save_outlined,
            label: saving ? 'Posting' : 'Save',
            onTap: onSave,
          ),
          _Tool(icon: Icons.delete_outline, label: 'Clear', onTap: onClear),
          const _Separator(),
          const _Tool(icon: Icons.print_outlined, label: 'Print'),
          const _Tool(icon: Icons.mail_outline, label: 'Email'),
          const Spacer(),
          _Tool(icon: Icons.close, label: 'Close', onTap: onClose),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({
    required this.customers,
    required this.invoices,
    required this.depositAccounts,
    required this.customer,
    required this.depositAccount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.dateText,
    required this.openBalance,
    required this.amountReceived,
    required this.onCustomerSelected,
    required this.onDepositSelected,
    required this.onPaymentMethodChanged,
    required this.onPickDate,
    required this.money,
  });

  final List<CustomerModel> customers;
  final List<InvoiceModel> invoices;
  final List<AccountModel> depositAccounts;
  final CustomerModel? customer;
  final AccountModel? depositAccount;
  final PaymentMethod paymentMethod;
  final DateTime paymentDate;
  final String dateText;
  final double openBalance;
  final double amountReceived;
  final ValueChanged<CustomerModel> onCustomerSelected;
  final ValueChanged<AccountModel> onDepositSelected;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final VoidCallback onPickDate;
  final String Function(double value) money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerOpenCount = customer == null
        ? 0
        : invoices
              .where(
                (invoice) =>
                    invoice.customerId == customer!.id &&
                    invoice.isCreditInvoice &&
                    !invoice.isVoid &&
                    invoice.postedTransactionId != null &&
                    invoice.balanceDue > 0,
              )
              .length;
    final selectedDeposit =
        depositAccounts.any((account) => account.id == depositAccount?.id)
        ? depositAccount?.id
        : null;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF264D5B),
              border: Border(bottom: BorderSide(color: Color(0xFF183642))),
            ),
            child: Row(
              children: [
                const _StripLabel('CUSTOMER:JOB'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: _InlineCustomerField(
                    customers: customers,
                    selected: customer,
                    onSelected: onCustomerSelected,
                  ),
                ),
                const SizedBox(width: 16),
                const _StripLabel('DEPOSIT TO'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: _DepositField(
                    accounts: depositAccounts,
                    selectedId: selectedDeposit,
                    onSelected: onDepositSelected,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 168,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 310,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receive Payment',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF243E4A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 62,
                          width: double.infinity,
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFB7C3CB)),
                          ),
                          child: Text(
                            customer == null
                                ? 'Received from: select a customer'
                                : '${customer!.displayName}\n${customer!.primaryContact}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: customer == null
                                  ? const Color(0xFF7B8B93)
                                  : const Color(0xFF253C47),
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 260,
                    child: Column(
                      children: [
                        _HorizontalField(
                          label: 'DATE',
                          child: _StaticBox(
                            text: dateText,
                            icon: Icons.calendar_today_outlined,
                            onTap: onPickDate,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _HorizontalField(
                          label: 'METHOD',
                          child: _MethodField(
                            value: paymentMethod,
                            onChanged: onPaymentMethodChanged,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _HorizontalField(
                          label: 'PAYMENT #',
                          child: const _StaticBox(text: 'AUTO'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        _PaymentStat(
                          label: 'OPEN INVOICES',
                          value: customer == null
                              ? '-'
                              : customerOpenCount.toString(),
                          accent: false,
                        ),
                        const SizedBox(height: 8),
                        _PaymentStat(
                          label: 'OPEN BALANCE',
                          value: money(openBalance),
                          accent: false,
                        ),
                        const SizedBox(height: 8),
                        _PaymentStat(
                          label: 'AMOUNT RECEIVED',
                          value: money(amountReceived),
                          accent: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineCustomerField extends StatelessWidget {
  const _InlineCustomerField({
    required this.customers,
    required this.selected,
    required this.onSelected,
  });

  final List<CustomerModel> customers;
  final CustomerModel? selected;
  final ValueChanged<CustomerModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<CustomerModel>(
      key: ValueKey(selected?.id ?? 'payment-customer'),
      displayStringForOption: (customer) => customer.displayName,
      initialValue: TextEditingValue(text: selected?.displayName ?? ''),
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return customers.take(20);
        return customers
            .where(
              (customer) => customer.displayName.toLowerCase().contains(query),
            )
            .take(20);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return SizedBox(
          height: 30,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.search, size: 16),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              border: OutlineInputBorder(),
              hintText: 'Select a customer...',
            ),
          ),
        );
      },
    );
  }
}

class _DepositField extends StatelessWidget {
  const _DepositField({
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
  });

  final List<AccountModel> accounts;
  final String? selectedId;
  final ValueChanged<AccountModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: DropdownButtonFormField<String>(
        initialValue: selectedId,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(),
        ),
        hint: const Text('Select deposit account'),
        items: accounts
            .map(
              (account) => DropdownMenuItem(
                value: account.id,
                child: Text('${account.code}  ${account.name}'),
              ),
            )
            .toList(),
        onChanged: (id) {
          final selected = accounts.where((item) => item.id == id).firstOrNull;
          if (selected != null) onSelected(selected);
        },
      ),
    );
  }
}

class _MethodField extends StatelessWidget {
  const _MethodField({required this.value, required this.onChanged});

  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: DropdownButtonFormField<PaymentMethod>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: PaymentMethod.cash, child: Text('Cash')),
          DropdownMenuItem(value: PaymentMethod.check, child: Text('Check')),
          DropdownMenuItem(
            value: PaymentMethod.bankTransfer,
            child: Text('Bank Transfer'),
          ),
          DropdownMenuItem(
            value: PaymentMethod.creditCard,
            child: Text('Card'),
          ),
        ],
        onChanged: (method) {
          if (method != null) onChanged(method);
        },
      ),
    );
  }
}

class _PaymentStat extends StatelessWidget {
  const _PaymentStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFE7F1F4) : Colors.white,
        border: Border.all(
          color: accent ? const Color(0xFF8EABB7) : const Color(0xFFB7C3CB),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _FieldLabel(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF213D49),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocationToolbar extends StatelessWidget {
  const _AllocationToolbar({
    required this.enabled,
    required this.selectedCount,
    required this.amountReceived,
    required this.money,
    required this.onAutoApply,
    required this.onClear,
  });

  final bool enabled;
  final int selectedCount;
  final double amountReceived;
  final String Function(double value) money;
  final VoidCallback onAutoApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFE9EFF2),
        border: Border(
          top: BorderSide(color: Color(0xFFB7C3CB)),
          bottom: BorderSide(color: Color(0xFFB7C3CB)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Open Invoices',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF233F4C),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Select invoices • edit payment amount per row',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF596B74),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '$selectedCount selected  •  ${money(amountReceived)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF233F4C),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: enabled ? onAutoApply : null,
            icon: const Icon(Icons.auto_fix_high_outlined, size: 15),
            label: const Text('Auto Apply'),
          ),
          TextButton.icon(
            onPressed: enabled ? onClear : null,
            icon: const Icon(Icons.clear_all_outlined, size: 15),
            label: const Text('Clear Lines'),
          ),
        ],
      ),
    );
  }
}

class _PaymentAllocationGrid extends StatelessWidget {
  const _PaymentAllocationGrid({
    required this.allocations,
    required this.money,
    required this.date,
    required this.onChanged,
  });

  final List<ReceivePaymentInvoiceAllocation> allocations;
  final String Function(double value) money;
  final String Function(DateTime value) date;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (allocations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 42,
              color: Color(0xFF8CA0AA),
            ),
            SizedBox(height: 10),
            Text(
              'Select a customer to load posted open invoices.',
              style: TextStyle(
                color: Color(0xFF60747D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF9EADB6)),
        ),
        child: Column(
          children: [
            Container(
              height: 28,
              color: const Color(0xFFDDE8ED),
              child: const Row(
                children: [
                  SizedBox(width: 44),
                  _GridHeaderCell('INVOICE #', flex: 2),
                  _GridHeaderCell('DATE', flex: 1),
                  _GridHeaderCell('DUE DATE', flex: 1),
                  _GridHeaderCell('ORIGINAL', flex: 1, right: true),
                  _GridHeaderCell('PAID', flex: 1, right: true),
                  _GridHeaderCell('BALANCE', flex: 1, right: true),
                  _GridHeaderCell('PAYMENT', flex: 1, right: true),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: allocations.length,
                itemBuilder: (context, index) {
                  final allocation = allocations[index];
                  return _AllocationRow(
                    key: ValueKey(
                      '${allocation.invoiceId}-${allocation.selected}-${allocation.amount}',
                    ),
                    allocation: allocation,
                    shaded: index.isEven,
                    money: money,
                    date: date,
                    onChanged: onChanged,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridHeaderCell extends StatelessWidget {
  const _GridHeaderCell(this.text, {required this.flex, this.right = false});

  final String text;
  final int flex;
  final bool right;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: right ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF53656E),
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _AllocationRow extends StatefulWidget {
  const _AllocationRow({
    super.key,
    required this.allocation,
    required this.shaded,
    required this.money,
    required this.date,
    required this.onChanged,
  });

  final ReceivePaymentInvoiceAllocation allocation;
  final bool shaded;
  final String Function(double value) money;
  final String Function(DateTime value) date;
  final VoidCallback onChanged;

  @override
  State<_AllocationRow> createState() => _AllocationRowState();
}

class _AllocationRowState extends State<_AllocationRow> {
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.allocation.amount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allocation = widget.allocation;
    return Container(
      height: 36,
      color: widget.shaded ? const Color(0xFFDDEFF4) : Colors.white,
      child: Row(
        children: [
          SizedBox(
            width: 44,
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
          _GridCell(allocation.invoiceNumber, flex: 2, strong: true),
          _GridCell(widget.date(allocation.invoiceDate), flex: 1),
          _GridCell(widget.date(allocation.dueDate), flex: 1),
          _GridCell(
            widget.money(allocation.originalAmount),
            flex: 1,
            right: true,
          ),
          _GridCell(widget.money(allocation.paidAmount), flex: 1, right: true),
          _GridCell(
            widget.money(allocation.balanceDue),
            flex: 1,
            right: true,
            strong: true,
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: TextField(
                controller: _amountCtrl,
                enabled: allocation.selected,
                textAlign: TextAlign.end,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 7,
                  ),
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

class _GridCell extends StatelessWidget {
  const _GridCell(
    this.text, {
    required this.flex,
    this.right = false,
    this.strong = false,
  });

  final String text;
  final int flex;
  final bool right;
  final bool strong;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Container(
      height: double.infinity,
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFB8C6CE))),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
          color: const Color(0xFF273F4B),
        ),
      ),
    ),
  );
}

class _PaymentFooter extends StatelessWidget {
  const _PaymentFooter({
    required this.amountReceived,
    required this.selectedCount,
    required this.money,
    required this.saving,
    required this.onClear,
    this.onSave,
  });

  final double amountReceived;
  final int selectedCount;
  final String Function(double value) money;
  final bool saving;
  final VoidCallback onClear;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F9),
        border: Border(top: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Payments are posted automatically when saved and applied to the selected invoices.',
              style: TextStyle(
                color: Color(0xFF53656E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 330,
            child: Column(
              children: [
                _AmountRow(label: 'SELECTED INVOICES', value: '$selectedCount'),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F1F4),
                    border: Border.all(color: const Color(0xFF9DB2BC)),
                  ),
                  child: _AmountRow(
                    label: 'AMOUNT RECEIVED',
                    value: money(amountReceived),
                    strong: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: onSave,
            style: _smallButton(),
            child: Text(saving ? 'Posting...' : 'Save & Close'),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: onClear,
            style: _smallButton(),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  ButtonStyle _smallButton() => OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    side: const BorderSide(color: Color(0xFF8FA1AB)),
  );
}

class _PaymentSidePanel extends StatefulWidget {
  const _PaymentSidePanel({
    required this.customer,
    required this.depositAccount,
    required this.paymentMethod,
    required this.allocations,
    required this.amountReceived,
    required this.openBalance,
    required this.money,
  });

  final CustomerModel? customer;
  final AccountModel? depositAccount;
  final PaymentMethod paymentMethod;
  final List<ReceivePaymentInvoiceAllocation> allocations;
  final double amountReceived;
  final double openBalance;
  final String Function(double value) money;

  @override
  State<_PaymentSidePanel> createState() => _PaymentSidePanelState();
}

class _PaymentSidePanelState extends State<_PaymentSidePanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: _expanded ? 258 : 38,
      margin: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F8),
        border: Border.all(color: const Color(0xFFB9C3CA)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (_expanded) Positioned.fill(child: _panelContent(context)),
          Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: const Color(0xFFE6EEF2),
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    _expanded ? Icons.chevron_right : Icons.chevron_left,
                    color: const Color(0xFF2B4A56),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelContent(BuildContext context) {
    final customer = widget.customer;
    final selected = widget.allocations
        .where((allocation) => allocation.selected && allocation.amount > 0)
        .toList();

    if (customer == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_search_outlined,
                size: 38,
                color: Color(0xFF8CA0AA),
              ),
              SizedBox(height: 12),
              Text(
                'Select a customer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2D4854),
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Choose a customer to load open invoices and allocate payment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF667A84), height: 1.35),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          decoration: const BoxDecoration(
            color: Color(0xFF264D5B),
            border: Border(bottom: BorderSide(color: Color(0xFF183642))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.depositAccount?.name ?? 'No deposit account selected',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFD7E6EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
          color: const Color(0xFFFFE7C4),
          child: Text(
            selected.isEmpty
                ? 'Select invoices before saving.'
                : 'Payment will post and apply to selected invoices.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF714600),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _SideSection(
          title: 'Payment Snapshot',
          child: Column(
            children: [
              _InfoRow(
                label: 'Open balance',
                value: widget.money(widget.openBalance),
              ),
              _InfoRow(
                label: 'Selected invoices',
                value: selected.length.toString(),
              ),
              _InfoRow(
                label: 'Payment method',
                value: widget.paymentMethod.toApiString(),
              ),
              const Divider(height: 14),
              _InfoRow(
                label: 'Amount received',
                value: widget.money(widget.amountReceived),
                strong: true,
              ),
            ],
          ),
        ),
        _SideSection(
          title: 'Applied Invoices',
          expanded: true,
          child: selected.isEmpty
              ? const Center(child: Text('No invoices selected.'))
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: selected.length,
                  itemBuilder: (context, index) {
                    final item = selected[index];
                    return _AppliedLine(
                      title: item.invoiceNumber,
                      amount: widget.money(item.amount),
                    );
                  },
                ),
        ),
        const _SideSection(
          title: 'Notes',
          child: Text(
            'No notes added.',
            style: TextStyle(color: Color(0xFF4E616A)),
          ),
        ),
      ],
    );
  }
}

class _SideSection extends StatelessWidget {
  const _SideSection({
    required this.title,
    required this.child,
    this.expanded = false,
  });

  final String title;
  final Widget child;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB8C6CE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 30,
            padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFE7EEF1),
              border: Border(bottom: BorderSide(color: Color(0xFFB8C6CE))),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF2D4854),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (expanded)
            Expanded(
              child: Padding(padding: const EdgeInsets.all(8), child: child),
            )
          else
            Padding(padding: const EdgeInsets.all(8), child: child),
        ],
      ),
    );

    return expanded ? Expanded(child: content) : content;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF334A55),
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _AppliedLine extends StatelessWidget {
  const _AppliedLine({required this.title, required this.amount});

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E6E9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF263E49),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Color(0xFF263E49),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? const Color(0xFF234C5D) : const Color(0xFF7D8B93);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: enabled ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 48,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: const Color(0xFFC4D0D6),
  );
}

class _StripLabel extends StatelessWidget {
  const _StripLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: const Color(0xFF53656E),
      fontWeight: FontWeight.w900,
    ),
  );
}

class _StaticBox extends StatelessWidget {
  const _StaticBox({required this.text, this.icon, this.onTap});

  final String text;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 34,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7C3CB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
          if (icon != null) Icon(icon, size: 15),
        ],
      ),
    ),
  );
}

class _HorizontalField extends StatelessWidget {
  const _HorizontalField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 86, child: _FieldLabel(label)),
      Expanded(child: child),
    ],
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
      Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    ],
  );
}

class _ShortcutStrip extends StatelessWidget {
  const _ShortcutStrip();

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    alignment: Alignment.centerLeft,
    decoration: const BoxDecoration(
      color: Color(0xFFD4DDE3),
      border: Border(top: BorderSide(color: Color(0xFFAFBBC4))),
    ),
    child: Text(
      'Receive payment workspace  •  Save posts payment  •  Auto Apply  •  Esc Close',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: const Color(0xFF33434C),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

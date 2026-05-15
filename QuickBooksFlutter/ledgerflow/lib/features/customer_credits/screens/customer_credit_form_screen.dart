// customer_credit_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../../../core/constants/api_enums.dart'
    show AccountType, CustomerCreditAction, PaymentMethod;
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../invoices/data/models/invoice_model.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
import '../data/models/customer_credit_model.dart';
import '../providers/customer_credits_provider.dart';

class CustomerCreditFormScreen extends ConsumerStatefulWidget {
  const CustomerCreditFormScreen({super.key});

  @override
  ConsumerState<CustomerCreditFormScreen> createState() =>
      _CustomerCreditFormScreenState();
}

class _CustomerCreditFormScreenState
    extends ConsumerState<CustomerCreditFormScreen> {
  CustomerModel? _selectedCustomer;
  InvoiceModel? _selectedInvoice;
  String? _refundAccountId;
  final DateTime _activityDate = DateTime.now();
  double _amount = 0;
  CustomerCreditAction _action = CustomerCreditAction.applyToInvoice;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _saving = false;

  final _customerCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();

  @override
  void dispose() {
    _customerCtrl.dispose();
    _invoiceCtrl.dispose();
    super.dispose();
  }

  void _clearState() {
    setState(() {
      _selectedCustomer = null;
      _selectedInvoice = null;
      _refundAccountId = null;
      _amount = 0;
      _action = CustomerCreditAction.applyToInvoice;
    });
    _customerCtrl.clear();
    _invoiceCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(customersProvider);
    final invoicesAsync = ref.watch(invoicesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final customers = customersAsync.maybeWhen(
      data: (items) => items.where((c) => c.isActive).toList(),
      orElse: () => <CustomerModel>[],
    );

    final customerInvoices = invoicesAsync.maybeWhen(
      data: (invoices) => invoices
          .where((inv) =>
              !inv.isVoid &&
              inv.balanceDue > 0 &&
              (_selectedCustomer == null ||
                  inv.customerId == _selectedCustomer!.id))
          .toList(),
      orElse: () => <InvoiceModel>[],
    );

    final refundAccounts = accountsAsync.maybeWhen(
      data: (accounts) => accounts
          .where((a) =>
              a.isActive &&
              (a.accountType == AccountType.bank ||
                  a.accountType == AccountType.otherCurrentAsset ||
                  a.accountType == AccountType.creditCard))
          .toList(),
      orElse: () => <AccountModel>[],
    );

    final credits = ref.watch(customerCreditsProvider).maybeWhen(
          data: (items) => items,
          orElse: () => <CustomerCreditModel>[],
        );

    return TransactionWorkspaceShell(
      workspaceName: 'Customer credit workspace',
      saving: _saving,
      posting: false,
      isEdit: false,
      readOnly: false,
      onFind: () => context.go(AppRoutes.customerCredits),
      onPrevious: credits.isNotEmpty
          ? () => context.go(
                AppRoutes.customerCreditDetails
                    .replaceFirst(':id', credits.first.id),
              )
          : null,
      onNext: null,
      onNew: _clearState,
      onSave: _saving ? null : _save,
      onClear: _clearState,
      onClose: () => context.go(AppRoutes.customerCredits),
      showVoid: false,
      formContent: Column(
        children: [
          _CreditHeader(
            selectedCustomer: _selectedCustomer,
            selectedInvoice: _selectedInvoice,
            refundAccountId: _refundAccountId,
            activityDate: _activityDate,
            amount: _amount,
            action: _action,
            paymentMethod: _paymentMethod,
            customers: customers,
            customerInvoices: customerInvoices,
            refundAccounts: refundAccounts,
            customerCtrl: _customerCtrl,
            invoiceCtrl: _invoiceCtrl,
            onCustomerChanged: (customer) {
              setState(() {
                _selectedCustomer = customer;
                _selectedInvoice = null;
              });
              _invoiceCtrl.clear();
            },
            onActionChanged: (value) => setState(() {
              _action = value;
              _selectedInvoice = null;
              _refundAccountId = null;
              _invoiceCtrl.clear();
            }),
            onInvoiceChanged: (invoice) => setState(() {
              _selectedInvoice = invoice;
              _amount = invoice?.balanceDue ?? _amount;
            }),
            onRefundAccountChanged: (value) =>
                setState(() => _refundAccountId = value),
            onPaymentMethodChanged: (value) =>
                setState(() => _paymentMethod = value),
            onAmountChanged: (value) => setState(() => _amount = value),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Customer balances, invoice balances, and accounting impact are computed by the backend automatically upon saving.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667A84),
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          _CreditFooter(total: _amount, currency: l10n.egp),
        ],
      ),
      contextPanel: _CreditContextPanel(
        customer: _selectedCustomer,
        amount: _amount,
        action: _action,
        selectedInvoice: _selectedInvoice,
        currency: l10n.egp,
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedCustomer == null) {
      _error(context, l10n.selectCustomerFirst);
      return;
    }
    if (_amount <= 0) {
      _error(context, l10n.enterPositiveAmount);
      return;
    }
    if (_action == CustomerCreditAction.applyToInvoice &&
        _selectedInvoice == null) {
      _error(context, l10n.selectInvoiceFirst);
      return;
    }
    if (_action == CustomerCreditAction.refundReceipt &&
        (_refundAccountId == null || _refundAccountId!.isEmpty)) {
      _error(context, l10n.selectPaymentAccountFirst);
      return;
    }

    final dto = CreateCustomerCreditDto(
      customerId: _selectedCustomer!.id,
      activityDate: _activityDate,
      amount: _amount,
      action: _action,
      invoiceId: _action == CustomerCreditAction.applyToInvoice
          ? _selectedInvoice?.id
          : null,
      refundAccountId: _action == CustomerCreditAction.refundReceipt
          ? _refundAccountId
          : null,
      paymentMethod:
          _action == CustomerCreditAction.refundReceipt ? _paymentMethod : null,
    );

    setState(() => _saving = true);
    final result = await ref.read(customerCreditsProvider.notifier).create(dto);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        ref.read(invoicesProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentCreatedSuccess)),
        );
        context.go(AppRoutes.customerCredits);
      },
      failure: (error) => _error(context, error.message),
    );
  }

  static void _error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _CreditHeader extends StatelessWidget {
  const _CreditHeader({
    required this.selectedCustomer,
    required this.selectedInvoice,
    required this.refundAccountId,
    required this.activityDate,
    required this.amount,
    required this.action,
    required this.paymentMethod,
    required this.customers,
    required this.customerInvoices,
    required this.refundAccounts,
    required this.customerCtrl,
    required this.invoiceCtrl,
    required this.onCustomerChanged,
    required this.onActionChanged,
    required this.onInvoiceChanged,
    required this.onRefundAccountChanged,
    required this.onPaymentMethodChanged,
    required this.onAmountChanged,
  });

  final CustomerModel? selectedCustomer;
  final InvoiceModel? selectedInvoice;
  final String? refundAccountId;
  final DateTime activityDate;
  final double amount;
  final CustomerCreditAction action;
  final PaymentMethod paymentMethod;
  final List<CustomerModel> customers;
  final List<InvoiceModel> customerInvoices;
  final List<AccountModel> refundAccounts;
  final TextEditingController customerCtrl;
  final TextEditingController invoiceCtrl;
  final ValueChanged<CustomerModel?> onCustomerChanged;
  final ValueChanged<CustomerCreditAction> onActionChanged;
  final ValueChanged<InvoiceModel?> onInvoiceChanged;
  final ValueChanged<String?> onRefundAccountChanged;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final ValueChanged<double> onAmountChanged;

  static String _dateOnly(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeAccountId =
        refundAccounts.any((a) => a.id == refundAccountId) ? refundAccountId : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7F8),
        border: Border(bottom: BorderSide(color: Color(0xFFB9C3CA))),
      ),
      child: Column(
        children: [
          // Row 1: Customer + Action + Date
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _CustomerTypeAhead(
                  controller: customerCtrl,
                  customers: customers,
                  selected: selectedCustomer,
                  label: '${l10n.customer} *',
                  onSelected: onCustomerChanged,
                  onClear: () => onCustomerChanged(null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<CustomerCreditAction>(
                  value: action,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.creditBalance,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: CustomerCreditAction.applyToInvoice,
                      child: Text(l10n.invoice,
                          overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: CustomerCreditAction.refundReceipt,
                      child: Text(l10n.recordDeposits,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) onActionChanged(v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: TextFormField(
                  readOnly: true,
                  initialValue: _dateOnly(activityDate),
                  decoration: InputDecoration(
                    labelText: l10n.paymentDate,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    prefixIcon:
                        const Icon(Icons.calendar_today_outlined, size: 16),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Invoice / Refund fields + Amount
          Row(
            children: [
              if (action == CustomerCreditAction.applyToInvoice)
                Expanded(
                  flex: 3,
                  child: _InvoiceTypeAhead(
                    controller: invoiceCtrl,
                    invoices: customerInvoices,
                    selected: selectedInvoice,
                    label: '${l10n.invoice} *',
                    currency: l10n.egp,
                    onSelected: onInvoiceChanged,
                    onClear: () => onInvoiceChanged(null),
                  ),
                )
              else ...[
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: safeAccountId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: '${l10n.paymentAccount} *',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.account_balance_outlined,
                          size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    items: refundAccounts
                        .map((a) => DropdownMenuItem<String>(
                              value: a.id,
                              child: Text('${a.code} - ${a.name}',
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: onRefundAccountChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<PaymentMethod>(
                    value: paymentMethod,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.paymentMethod,
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(),
                      prefixIcon:
                          const Icon(Icons.payments_outlined, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: PaymentMethod.cash,
                          child: Text(l10n.cash,
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: PaymentMethod.check,
                          child: Text(l10n.check,
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: PaymentMethod.bankTransfer,
                          child: Text(l10n.bankTransfer,
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: PaymentMethod.creditCard,
                          child: Text(l10n.creditCard,
                              overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) {
                      if (v != null) onPaymentMethodChanged(v);
                    },
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: amount == 0 ? '' : amount.toString(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${l10n.amount} *',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                  onChanged: (v) => onAmountChanged(double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────────────────

class _CreditFooter extends StatelessWidget {
  const _CreditFooter({required this.total, required this.currency});
  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7F8),
        border: Border(top: BorderSide(color: Color(0xFFB9C3CA))),
      ),
      child: Row(
        children: [
          const Spacer(),
          const Text(
            'CREDIT AMOUNT',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF7D8B93)),
          ),
          const SizedBox(width: 16),
          Text(
            '${total.toStringAsFixed(2)} $currency',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF264D5B)),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Context Panel ───────────────────────────────────────────────────────────

class _CreditContextPanel extends StatelessWidget {
  const _CreditContextPanel({
    required this.customer,
    required this.amount,
    required this.action,
    required this.selectedInvoice,
    required this.currency,
  });

  final CustomerModel? customer;
  final double amount;
  final CustomerCreditAction action;
  final InvoiceModel? selectedInvoice;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
            color: const Color(0xFF264D5B),
            child: Text(
              'Credit Info',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Stat(
                  label: 'AMOUNT',
                  value: '${amount.toStringAsFixed(2)} $currency',
                  isTotal: true,
                ),
                if (customer != null)
                  _Stat(label: 'CUSTOMER', value: customer!.displayName),
                if (action == CustomerCreditAction.applyToInvoice &&
                    selectedInvoice != null)
                  _Stat(
                    label: 'APPLIED TO',
                    value: 'Invoice #${selectedInvoice!.invoiceNumber}',
                  ),
                if (action == CustomerCreditAction.refundReceipt)
                  const _Stat(label: 'TYPE', value: 'Refund Receipt'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ──────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.isTotal = false});
  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF7D8B93),
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
                  color: const Color(0xFF264D5B))),
        ],
      ),
    );
  }
}

// ── Customer TypeAhead ──────────────────────────────────────────────────────

class _CustomerTypeAhead extends StatelessWidget {
  const _CustomerTypeAhead({
    required this.controller,
    required this.customers,
    required this.selected,
    required this.label,
    required this.onSelected,
    required this.onClear,
  });

  final TextEditingController controller;
  final List<CustomerModel> customers;
  final CustomerModel? selected;
  final String label;
  final ValueChanged<CustomerModel?> onSelected;
  final VoidCallback onClear;

  List<CustomerModel> _matches(String q) {
    final text = q.trim().toLowerCase();
    if (text.isEmpty) return customers.take(10).toList();
    return customers
        .where((c) =>
            c.displayName.toLowerCase().contains(text) ||
            (c.companyName?.toLowerCase().contains(text) ?? false) ||
            (c.phone?.contains(text) ?? false))
        .take(12)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (selected != null && controller.text != selected!.displayName) {
      controller.text = selected!.displayName;
    }
    return TypeAheadField<CustomerModel>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          prefixIcon: const Icon(Icons.person_outline, size: 18),
          suffixIcon: selected != null
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    controller.clear();
                    onClear();
                  },
                )
              : null,
        ),
      ),
      suggestionsCallback: _matches,
      itemBuilder: (context, c) => ListTile(
        dense: true,
        leading: CircleAvatar(
            radius: 14,
            child: Text(c.initials, style: const TextStyle(fontSize: 11))),
        title: Text(c.displayName,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
            '${c.primaryContact} | Bal: ${c.balance.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 11)),
      ),
      onSuggestionSelected: (c) {
        controller.text = c.displayName;
        onSelected(c);
      },
      noItemsFoundBuilder: (_) => const Padding(
          padding: EdgeInsets.all(10), child: Text('No matching customers')),
      suggestionsBoxDecoration: const SuggestionsBoxDecoration(
          elevation: 4, constraints: BoxConstraints(maxHeight: 300)),
    );
  }
}

// ── Invoice TypeAhead ───────────────────────────────────────────────────────

class _InvoiceTypeAhead extends StatelessWidget {
  const _InvoiceTypeAhead({
    required this.controller,
    required this.invoices,
    required this.selected,
    required this.label,
    required this.currency,
    required this.onSelected,
    required this.onClear,
  });

  final TextEditingController controller;
  final List<InvoiceModel> invoices;
  final InvoiceModel? selected;
  final String label;
  final String currency;
  final ValueChanged<InvoiceModel?> onSelected;
  final VoidCallback onClear;

  List<InvoiceModel> _matches(String q) {
    final text = q.trim().toLowerCase();
    if (text.isEmpty) return invoices.take(10).toList();
    return invoices
        .where((inv) =>
            inv.invoiceNumber.toLowerCase().contains(text) ||
            (inv.customerName?.toLowerCase().contains(text) ?? false))
        .take(12)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (selected != null && controller.text.isEmpty) {
      controller.text =
          '${selected!.invoiceNumber} - ${selected!.customerName ?? ''}';
    }
    return TypeAheadField<InvoiceModel>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          prefixIcon: const Icon(Icons.receipt_long_outlined, size: 18),
          suffixIcon: selected != null
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    controller.clear();
                    onClear();
                  },
                )
              : null,
        ),
      ),
      suggestionsCallback: _matches,
      itemBuilder: (context, inv) => ListTile(
        dense: true,
        leading: const Icon(Icons.receipt_long_outlined,
            size: 18, color: Color(0xFF264D5B)),
        title: Text(
            '${inv.invoiceNumber} — ${inv.customerName ?? inv.customerId}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        subtitle: Text(
            'Balance: ${inv.balanceDue.toStringAsFixed(2)} $currency',
            style: const TextStyle(fontSize: 11)),
      ),
      onSuggestionSelected: (inv) {
        controller.text =
            '${inv.invoiceNumber} - ${inv.customerName ?? ''}';
        onSelected(inv);
      },
      noItemsFoundBuilder: (_) => const Padding(
          padding: EdgeInsets.all(10), child: Text('No matching invoices')),
      suggestionsBoxDecoration: const SuggestionsBoxDecoration(
          elevation: 4, constraints: BoxConstraints(maxHeight: 300)),
    );
  }
}

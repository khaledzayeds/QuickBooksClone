// customer_credit_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../../../core/constants/api_enums.dart'
    show AccountType, CustomerCreditAction, PaymentMethod;
import '../../../core/widgets/app_text_field.dart';
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
  String? _customerId;
  String? _invoiceId;
  String? _refundAccountId;
  final DateTime _activityDate = DateTime.now();
  double _amount = 0;
  CustomerCreditAction _action = CustomerCreditAction.applyToInvoice;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(customersProvider);
    final invoicesAsync = ref.watch(invoicesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final credits = ref.watch(customerCreditsProvider).maybeWhen(
          data: (items) => items,
          orElse: () => <CustomerCreditModel>[],
        );

    final selectedCustomer = customersAsync.maybeWhen(
      data: (customers) =>
          customers.where((c) => c.id == _customerId).firstOrNull,
      orElse: () => null,
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
                AppRoutes.customerCreditDetails.replaceFirst(
                  ':id',
                  credits.first.id,
                ),
              )
          : null,
      onNext: null,
      onNew: () {
        setState(() {
          _customerId = null;
          _invoiceId = null;
          _refundAccountId = null;
          _amount = 0;
          _action = CustomerCreditAction.applyToInvoice;
        });
      },
      onSave: _saving ? null : _save,
      onClear: () {
        setState(() {
          _customerId = null;
          _invoiceId = null;
          _refundAccountId = null;
          _amount = 0;
          _action = CustomerCreditAction.applyToInvoice;
        });
      },
      onClose: () => context.go(AppRoutes.customerCredits),
      showVoid: false,
      formContent: Column(
        children: [
          _CreditHeader(
            customerId: _customerId,
            invoiceId: _invoiceId,
            refundAccountId: _refundAccountId,
            activityDate: _activityDate,
            amount: _amount,
            action: _action,
            paymentMethod: _paymentMethod,
            customersAsync: customersAsync,
            invoicesAsync: invoicesAsync,
            accountsAsync: accountsAsync,
            onCustomerChanged: (value) => setState(() {
              _customerId = value;
              _invoiceId = null;
            }),
            onActionChanged: (value) => setState(() {
              _action = value;
              _invoiceId = null;
              _refundAccountId = null;
            }),
            onInvoiceChanged: (invoice) => setState(() {
              _invoiceId = invoice?.id;
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
                padding: const EdgeInsets.all(32.0),
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
        customer: selectedCustomer,
        amount: _amount,
        action: _action,
        invoiceId: _invoiceId,
        invoicesAsync: invoicesAsync,
        currency: l10n.egp,
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    if (_customerId == null || _customerId!.isEmpty) {
      _error(context, l10n.selectCustomerFirst);
      return;
    }
    if (_amount <= 0) {
      _error(context, l10n.enterPositiveAmount);
      return;
    }
    if (_action == CustomerCreditAction.applyToInvoice &&
        (_invoiceId == null || _invoiceId!.isEmpty)) {
      _error(context, l10n.selectInvoiceFirst);
      return;
    }
    if (_action == CustomerCreditAction.refundReceipt &&
        (_refundAccountId == null || _refundAccountId!.isEmpty)) {
      _error(context, l10n.selectPaymentAccountFirst);
      return;
    }

    final dto = CreateCustomerCreditDto(
      customerId: _customerId!,
      activityDate: _activityDate,
      amount: _amount,
      action: _action,
      invoiceId:
          _action == CustomerCreditAction.applyToInvoice ? _invoiceId : null,
      refundAccountId: _action == CustomerCreditAction.refundReceipt
          ? _refundAccountId
          : null,
      paymentMethod: _action == CustomerCreditAction.refundReceipt
          ? _paymentMethod
          : null,
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

// ── Form Sections ──────────────────────────────────────────────────────────

class _CreditHeader extends StatelessWidget {
  const _CreditHeader({
    required this.customerId,
    required this.invoiceId,
    required this.refundAccountId,
    required this.activityDate,
    required this.amount,
    required this.action,
    required this.paymentMethod,
    required this.customersAsync,
    required this.invoicesAsync,
    required this.accountsAsync,
    required this.onCustomerChanged,
    required this.onActionChanged,
    required this.onInvoiceChanged,
    required this.onRefundAccountChanged,
    required this.onPaymentMethodChanged,
    required this.onAmountChanged,
  });

  final String? customerId;
  final String? invoiceId;
  final String? refundAccountId;
  final DateTime activityDate;
  final double amount;
  final CustomerCreditAction action;
  final PaymentMethod paymentMethod;
  final AsyncValue customersAsync;
  final AsyncValue<List<InvoiceModel>> invoicesAsync;
  final AsyncValue<List<AccountModel>> accountsAsync;
  final ValueChanged<String?> onCustomerChanged;
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

    final customerInvoices = invoicesAsync.maybeWhen(
      data: (invoices) => invoices
          .where(
            (invoice) =>
                customerId == null || invoice.customerId == customerId,
          )
          .where((invoice) => !invoice.isVoid && invoice.balanceDue > 0)
          .toList(),
      orElse: () => <InvoiceModel>[],
    );

    final refundAccounts = accountsAsync.maybeWhen(
      data: (accounts) => accounts
          .where(
            (account) =>
                account.isActive &&
                (account.accountType == AccountType.bank ||
                    account.accountType == AccountType.otherCurrentAsset ||
                    account.accountType == AccountType.creditCard),
          )
          .toList(),
      orElse: () => <AccountModel>[],
    );

    final safeInvoiceId = customerInvoices.any((i) => i.id == invoiceId)
        ? invoiceId
        : null;
    final safeAccountId = refundAccounts.any((a) => a.id == refundAccountId)
        ? refundAccountId
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7F8),
        border: Border(bottom: BorderSide(color: Color(0xFFB9C3CA))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: customerId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: '${l10n.customer} *',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: customersAsync.maybeWhen(
                    data: (customers) => customers
                        .map<DropdownMenuItem<String>>(
                          (CustomerModel customer) => DropdownMenuItem<String>(
                            value: customer.id,
                            child: Text(
                              customer.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    orElse: () => const <DropdownMenuItem<String>>[],
                  ),
                  onChanged: onCustomerChanged,
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
                      size: 18,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem<CustomerCreditAction>(
                      value: CustomerCreditAction.applyToInvoice,
                      child: Text(l10n.invoice, overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem<CustomerCreditAction>(
                      value: CustomerCreditAction.refundReceipt,
                      child: Text(l10n.recordDeposits, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onActionChanged(value);
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (action == CustomerCreditAction.applyToInvoice)
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: safeInvoiceId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: '${l10n.invoice} *',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.receipt_long_outlined, size: 18),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: customerInvoices
                        .map<DropdownMenuItem<String>>(
                          (InvoiceModel invoice) => DropdownMenuItem<String>(
                            value: invoice.id,
                            child: Text(
                              '${invoice.invoiceNumber} - ${invoice.balanceDue.toStringAsFixed(2)} ${l10n.egp}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      final invoice = customerInvoices
                          .where((i) => i.id == value)
                          .firstOrNull;
                      onInvoiceChanged(invoice);
                    },
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
                      prefixIcon: const Icon(Icons.account_balance_outlined, size: 18),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: refundAccounts
                        .map<DropdownMenuItem<String>>(
                          (AccountModel account) => DropdownMenuItem<String>(
                            value: account.id,
                            child: Text(
                              '${account.code} - ${account.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
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
                      prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem<PaymentMethod>(
                          value: PaymentMethod.cash, child: Text(l10n.cash, overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem<PaymentMethod>(
                          value: PaymentMethod.check, child: Text(l10n.check, overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem<PaymentMethod>(
                          value: PaymentMethod.bankTransfer,
                          child: Text(l10n.bankTransfer, overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem<PaymentMethod>(
                          value: PaymentMethod.creditCard,
                          child: Text(l10n.creditCard, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (value) {
                      if (value != null) onPaymentMethodChanged(value);
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (value) =>
                      onAmountChanged(double.tryParse(value) ?? 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
              color: Color(0xFF7D8B93),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${total.toStringAsFixed(2)} $currency',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF264D5B),
            ),
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
    required this.invoiceId,
    required this.invoicesAsync,
    required this.currency,
  });

  final CustomerModel? customer;
  final double amount;
  final CustomerCreditAction action;
  final String? invoiceId;
  final AsyncValue<List<InvoiceModel>> invoicesAsync;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final invoice = invoicesAsync.maybeWhen(
      data: (invoices) => invoices.where((i) => i.id == invoiceId).firstOrNull,
      orElse: () => null,
    );

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
                    invoice != null)
                  _Stat(
                    label: 'APPLIED TO',
                    value: 'Invoice #${invoice.invoiceNumber}',
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF7D8B93),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: const Color(0xFF264D5B),
            ),
          ),
        ],
      ),
    );
  }
}

// customer_credit_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../../../core/constants/api_enums.dart'
    show AccountType, CustomerCreditAction, PaymentMethod;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../invoices/data/models/invoice_model.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../data/models/customer_credit_model.dart';
import '../providers/customer_credits_provider.dart';

class CustomerCreditFormScreen extends ConsumerStatefulWidget {
  const CustomerCreditFormScreen({super.key});

  static String _dateOnly(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  ConsumerState<CustomerCreditFormScreen> createState() => _CustomerCreditFormScreenState();
}

class _CustomerCreditFormScreenState extends ConsumerState<CustomerCreditFormScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.newText} ${l10n.creditBalance}'),
        actions: [
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.secondary,
            onPressed: _saving
                ? null
                : () => context.canPop() ? context.pop() : context.go(AppRoutes.customerCredits),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.save,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _CreditCard(
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
            onRefundAccountChanged: (value) => setState(() => _refundAccountId = value),
            onPaymentMethodChanged: (value) => setState(() => _paymentMethod = value),
            onAmountChanged: (value) => setState(() => _amount = value),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _DraftCreditAmountCard(amount: _amount),
          ),
        ],
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
    if (_action == CustomerCreditAction.applyToInvoice && (_invoiceId == null || _invoiceId!.isEmpty)) {
      _error(context, l10n.selectInvoiceFirst);
      return;
    }
    if (_action == CustomerCreditAction.refundReceipt && (_refundAccountId == null || _refundAccountId!.isEmpty)) {
      _error(context, l10n.selectPaymentAccountFirst);
      return;
    }

    final dto = CreateCustomerCreditDto(
      customerId: _customerId!,
      activityDate: _activityDate,
      amount: _amount,
      action: _action,
      invoiceId: _action == CustomerCreditAction.applyToInvoice ? _invoiceId : null,
      refundAccountId: _action == CustomerCreditAction.refundReceipt ? _refundAccountId : null,
      paymentMethod: _action == CustomerCreditAction.refundReceipt ? _paymentMethod : null,
    );

    setState(() => _saving = true);
    final result = await ref.read(customerCreditsProvider.notifier).create(dto);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        ref.read(invoicesProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.paymentCreatedSuccess)));
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

class _CreditCard extends StatelessWidget {
  const _CreditCard({
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final customerInvoices = invoicesAsync.maybeWhen(
      data: (invoices) => invoices
          .where((invoice) => customerId == null || invoice.customerId == customerId)
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

    final safeInvoiceId = customerInvoices.any((invoice) => invoice.id == invoiceId) ? invoiceId : null;
    final safeAccountId = refundAccounts.any((account) => account.id == refundAccountId) ? refundAccountId : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: customerId,
              decoration: InputDecoration(
                labelText: '${l10n.customer} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              items: customersAsync.maybeWhen(
                data: (customers) => customers
                    .map<DropdownMenuItem<String>>(
                      (CustomerModel customer) => DropdownMenuItem<String>(
                        value: customer.id,
                        child: Text(customer.displayName),
                      ),
                    )
                    .toList(),
                orElse: () => const <DropdownMenuItem<String>>[],
              ),
              onChanged: onCustomerChanged,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CustomerCreditAction>(
                    initialValue: action,
                    decoration: InputDecoration(
                      labelText: l10n.creditBalance,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: [
                      DropdownMenuItem<CustomerCreditAction>(
                        value: CustomerCreditAction.applyToInvoice,
                        child: Text(l10n.invoice),
                      ),
                      DropdownMenuItem<CustomerCreditAction>(
                        value: CustomerCreditAction.refundReceipt,
                        child: Text(l10n.recordDeposits),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onActionChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: l10n.paymentDate,
                    readOnly: true,
                    initialValue: CustomerCreditFormScreen._dateOnly(activityDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (action == CustomerCreditAction.applyToInvoice)
              DropdownButtonFormField<String>(
                initialValue: safeInvoiceId,
                decoration: InputDecoration(
                  labelText: '${l10n.invoice} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                ),
                items: customerInvoices
                    .map<DropdownMenuItem<String>>(
                      (InvoiceModel invoice) => DropdownMenuItem<String>(
                        value: invoice.id,
                        child: Text('${invoice.invoiceNumber} - ${invoice.balanceDue.toStringAsFixed(2)} ${l10n.egp}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  final invoice = customerInvoices.where((i) => i.id == value).firstOrNull;
                  onInvoiceChanged(invoice);
                },
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: safeAccountId,
                decoration: InputDecoration(
                  labelText: '${l10n.paymentAccount} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                ),
                items: refundAccounts
                    .map<DropdownMenuItem<String>>(
                      (AccountModel account) => DropdownMenuItem<String>(
                        value: account.id,
                        child: Text('${account.code} - ${account.name}'),
                      ),
                    )
                    .toList(),
                onChanged: onRefundAccountChanged,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: paymentMethod,
                decoration: InputDecoration(
                  labelText: l10n.paymentMethod,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                items: [
                  DropdownMenuItem<PaymentMethod>(value: PaymentMethod.cash, child: Text(l10n.cash)),
                  DropdownMenuItem<PaymentMethod>(value: PaymentMethod.check, child: Text(l10n.check)),
                  DropdownMenuItem<PaymentMethod>(value: PaymentMethod.bankTransfer, child: Text(l10n.bankTransfer)),
                  DropdownMenuItem<PaymentMethod>(value: PaymentMethod.creditCard, child: Text(l10n.creditCard)),
                ],
                onChanged: (value) {
                  if (value != null) onPaymentMethodChanged(value);
                },
              ),
            ],
            const SizedBox(height: 16),
            AppTextField(
              label: '${l10n.amount} *',
              initialValue: amount == 0 ? '' : amount.toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => onAmountChanged(double.tryParse(value) ?? 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCreditAmountCard extends StatelessWidget {
  const _DraftCreditAmountCard({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  const Text('Draft credit amount', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${amount.toStringAsFixed(2)} ${l10n.egp}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Official customer balance, invoice application, refund, and accounting impact are recalculated by the backend after save.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

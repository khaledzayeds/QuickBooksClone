// customer_credit_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../../../core/constants/api_enums.dart' show AccountType, CustomerCreditAction, PaymentMethod;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../invoices/data/models/invoice_model.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../data/models/customer_credit_model.dart';
import '../providers/customer_credits_provider.dart';

class CustomerCreditFormState {
  String? customerId;
  String? invoiceId;
  String? refundAccountId;
  DateTime activityDate = DateTime.now();
  double amount = 0;
  CustomerCreditAction action = CustomerCreditAction.applyToInvoice;
  PaymentMethod paymentMethod = PaymentMethod.cash;
}

final customerCreditFormProvider = StateProvider.autoDispose<CustomerCreditFormState>((ref) => CustomerCreditFormState());
final customerCreditSavingProvider = StateProvider.autoDispose<bool>((ref) => false);

class CustomerCreditFormScreen extends ConsumerWidget {
  const CustomerCreditFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.watch(customerCreditFormProvider);
    final saving = ref.watch(customerCreditSavingProvider);
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
            onPressed: saving ? null : () => context.canPop() ? context.pop() : context.go(AppRoutes.customerCredits),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.save,
            loading: saving,
            onPressed: saving ? null : () => _save(context, ref),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _CreditCard(
            form: form,
            customersAsync: customersAsync,
            invoicesAsync: invoicesAsync,
            accountsAsync: accountsAsync,
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.read(customerCreditFormProvider);

    if (form.customerId == null || form.customerId!.isEmpty) {
      _error(context, l10n.selectCustomerFirst);
      return;
    }
    if (form.amount <= 0) {
      _error(context, l10n.enterPositiveAmount);
      return;
    }
    if (form.action == CustomerCreditAction.applyToInvoice && (form.invoiceId == null || form.invoiceId!.isEmpty)) {
      _error(context, l10n.selectInvoiceFirst);
      return;
    }
    if (form.action == CustomerCreditAction.refundReceipt && (form.refundAccountId == null || form.refundAccountId!.isEmpty)) {
      _error(context, l10n.selectPaymentAccountFirst);
      return;
    }

    final dto = CreateCustomerCreditDto(
      customerId: form.customerId!,
      activityDate: form.activityDate,
      amount: form.amount,
      action: form.action,
      invoiceId: form.action == CustomerCreditAction.applyToInvoice ? form.invoiceId : null,
      refundAccountId: form.action == CustomerCreditAction.refundReceipt ? form.refundAccountId : null,
      paymentMethod: form.action == CustomerCreditAction.refundReceipt ? form.paymentMethod : null,
    );

    ref.read(customerCreditSavingProvider.notifier).state = true;
    final result = await ref.read(customerCreditsProvider.notifier).create(dto);
    ref.read(customerCreditSavingProvider.notifier).state = false;

    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.read(invoicesProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.paymentCreatedSuccess)));
        context.go(AppRoutes.customerCredits);
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

class _CreditCard extends ConsumerWidget {
  const _CreditCard({
    required this.form,
    required this.customersAsync,
    required this.invoicesAsync,
    required this.accountsAsync,
  });

  final CustomerCreditFormState form;
  final AsyncValue customersAsync;
  final AsyncValue<List<InvoiceModel>> invoicesAsync;
  final AsyncValue<List<AccountModel>> accountsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final customerInvoices = invoicesAsync.maybeWhen(
      data: (invoices) => invoices
          .where((invoice) => form.customerId == null || invoice.customerId == form.customerId)
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

    final safeInvoiceId = customerInvoices.any((invoice) => invoice.id == form.invoiceId) ? form.invoiceId : null;
    final safeAccountId = refundAccounts.any((account) => account.id == form.refundAccountId) ? form.refundAccountId : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: form.customerId,
              decoration: InputDecoration(
                labelText: '${l10n.customer} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              items: customersAsync.maybeWhen(
                data: (customers) => customers
                    .map<DropdownMenuItem<String>>((customer) => DropdownMenuItem(value: customer.id, child: Text(customer.displayName)))
                    .toList(),
                orElse: () => const <DropdownMenuItem<String>>[],
              ),
              onChanged: (value) => _update(
                ref,
                form
                  ..customerId = value
                  ..invoiceId = null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CustomerCreditAction>(
                    initialValue: form.action,
                    decoration: InputDecoration(
                      labelText: l10n.creditBalance,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: [
                      DropdownMenuItem(value: CustomerCreditAction.applyToInvoice, child: Text(l10n.invoice)),
                      DropdownMenuItem(value: CustomerCreditAction.refundReceipt, child: Text(l10n.recordDeposits)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      _update(
                        ref,
                        form
                          ..action = value
                          ..invoiceId = null
                          ..refundAccountId = null,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: l10n.paymentDate,
                    readOnly: true,
                    initialValue: CustomerCreditFormScreen._dateOnly(form.activityDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (form.action == CustomerCreditAction.applyToInvoice)
              DropdownButtonFormField<String>(
                initialValue: safeInvoiceId,
                decoration: InputDecoration(
                  labelText: '${l10n.invoice} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                ),
                items: customerInvoices
                    .map(
                      (invoice) => DropdownMenuItem(
                        value: invoice.id,
                        child: Text('${invoice.invoiceNumber} - ${invoice.balanceDue.toStringAsFixed(2)} ${l10n.egp}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  final invoice = customerInvoices.where((i) => i.id == value).firstOrNull;
                  _update(
                    ref,
                    form
                      ..invoiceId = value
                      ..amount = invoice?.balanceDue ?? form.amount,
                  );
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
                    .map((account) => DropdownMenuItem(value: account.id, child: Text('${account.code} - ${account.name}')))
                    .toList(),
                onChanged: (value) => _update(ref, form..refundAccountId = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: form.paymentMethod,
                decoration: InputDecoration(
                  labelText: l10n.paymentMethod,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                items: [
                  DropdownMenuItem(value: PaymentMethod.cash, child: Text(l10n.cash)),
                  DropdownMenuItem(value: PaymentMethod.check, child: Text(l10n.check)),
                  DropdownMenuItem(value: PaymentMethod.bankTransfer, child: Text(l10n.bankTransfer)),
                  DropdownMenuItem(value: PaymentMethod.creditCard, child: Text(l10n.creditCard)),
                ],
                onChanged: (value) {
                  if (value != null) _update(ref, form..paymentMethod = value);
                },
              ),
            ],
            const SizedBox(height: 16),
            AppTextField(
              key: ValueKey('customer-credit-amount-${form.invoiceId}-${form.amount}'),
              label: '${l10n.amount} *',
              initialValue: form.amount == 0 ? '' : form.amount.toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                form.amount = double.tryParse(value) ?? 0;
                _update(ref, form);
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _update(WidgetRef ref, CustomerCreditFormState old) {
  ref.read(customerCreditFormProvider.notifier).state = CustomerCreditFormState()
    ..customerId = old.customerId
    ..invoiceId = old.invoiceId
    ..refundAccountId = old.refundAccountId
    ..activityDate = old.activityDate
    ..amount = old.amount
    ..action = old.action
    ..paymentMethod = old.paymentMethod;
}

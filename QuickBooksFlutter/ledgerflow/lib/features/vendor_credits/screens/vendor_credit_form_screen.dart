// vendor_credit_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../../../core/constants/api_enums.dart' show AccountType, PaymentMethod, VendorCreditAction;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../purchase_bills/data/models/purchase_bill_model.dart';
import '../../purchase_bills/providers/purchase_bills_provider.dart';
import '../../vendors/providers/vendors_provider.dart';
import '../data/models/vendor_credit_model.dart';
import '../providers/vendor_credits_provider.dart';

class VendorCreditFormState {
  String? vendorId;
  String? purchaseBillId;
  String? depositAccountId;
  DateTime activityDate = DateTime.now();
  double amount = 0;
  VendorCreditAction action = VendorCreditAction.applyToBill;
  PaymentMethod paymentMethod = PaymentMethod.cash;
}

final vendorCreditFormProvider = StateProvider.autoDispose<VendorCreditFormState>((ref) => VendorCreditFormState());
final vendorCreditSavingProvider = StateProvider.autoDispose<bool>((ref) => false);

class VendorCreditFormScreen extends ConsumerWidget {
  const VendorCreditFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.watch(vendorCreditFormProvider);
    final saving = ref.watch(vendorCreditSavingProvider);
    final vendorsAsync = ref.watch(vendorsProvider);
    final billsAsync = ref.watch(purchaseBillsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.newText} ${l10n.creditBalance}'),
        actions: [
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.secondary,
            onPressed: saving ? null : () => context.canPop() ? context.pop() : context.go(AppRoutes.vendorCredits),
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
            vendorsAsync: vendorsAsync,
            billsAsync: billsAsync,
            accountsAsync: accountsAsync,
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.read(vendorCreditFormProvider);

    if (form.vendorId == null || form.vendorId!.isEmpty) {
      _error(context, l10n.selectVendor);
      return;
    }
    if (form.amount <= 0) {
      _error(context, l10n.enterPositiveAmount);
      return;
    }
    if (form.action == VendorCreditAction.applyToBill && (form.purchaseBillId == null || form.purchaseBillId!.isEmpty)) {
      _error(context, l10n.selectPurchaseBillFirst);
      return;
    }
    if (form.action == VendorCreditAction.refundReceipt && (form.depositAccountId == null || form.depositAccountId!.isEmpty)) {
      _error(context, l10n.selectDepositAccountFirst);
      return;
    }

    final dto = CreateVendorCreditDto(
      vendorId: form.vendorId!,
      activityDate: form.activityDate,
      amount: form.amount,
      action: form.action,
      purchaseBillId: form.action == VendorCreditAction.applyToBill ? form.purchaseBillId : null,
      depositAccountId: form.action == VendorCreditAction.refundReceipt ? form.depositAccountId : null,
      paymentMethod: form.action == VendorCreditAction.refundReceipt ? form.paymentMethod : null,
    );

    ref.read(vendorCreditSavingProvider.notifier).state = true;
    final result = await ref.read(vendorCreditsProvider.notifier).create(dto);
    ref.read(vendorCreditSavingProvider.notifier).state = false;

    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.read(purchaseBillsProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.paymentCreatedSuccess)));
        context.go(AppRoutes.vendorCredits);
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
    required this.vendorsAsync,
    required this.billsAsync,
    required this.accountsAsync,
  });

  final VendorCreditFormState form;
  final AsyncValue vendorsAsync;
  final AsyncValue<List<PurchaseBillModel>> billsAsync;
  final AsyncValue<List<AccountModel>> accountsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final vendorBills = billsAsync.maybeWhen(
      data: (bills) => bills
          .where((bill) => form.vendorId == null || bill.vendorId == form.vendorId)
          .where((bill) => bill.balanceDue > 0)
          .toList(),
      orElse: () => <PurchaseBillModel>[],
    );

    final depositAccounts = accountsAsync.maybeWhen(
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

    final safeBillId = vendorBills.any((bill) => bill.id == form.purchaseBillId) ? form.purchaseBillId : null;
    final safeAccountId = depositAccounts.any((account) => account.id == form.depositAccountId) ? form.depositAccountId : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: form.vendorId,
              decoration: InputDecoration(
                labelText: '${l10n.vendor} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.storefront_outlined),
              ),
              items: vendorsAsync.maybeWhen(
                data: (vendors) => vendors
                    .map<DropdownMenuItem<String>>((vendor) => DropdownMenuItem(value: vendor.id, child: Text(vendor.displayName)))
                    .toList(),
                orElse: () => const <DropdownMenuItem<String>>[],
              ),
              onChanged: (value) => _update(
                ref,
                form
                  ..vendorId = value
                  ..purchaseBillId = null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<VendorCreditAction>(
                    initialValue: form.action,
                    decoration: InputDecoration(
                      labelText: l10n.creditBalance,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: [
                      DropdownMenuItem(value: VendorCreditAction.applyToBill, child: Text(l10n.purchaseBill)),
                      DropdownMenuItem(value: VendorCreditAction.refundReceipt, child: Text(l10n.recordDeposits)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      _update(
                        ref,
                        form
                          ..action = value
                          ..purchaseBillId = null
                          ..depositAccountId = null,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: l10n.paymentDate,
                    readOnly: true,
                    initialValue: VendorCreditFormScreen._dateOnly(form.activityDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (form.action == VendorCreditAction.applyToBill)
              DropdownButtonFormField<String>(
                initialValue: safeBillId,
                decoration: InputDecoration(
                  labelText: '${l10n.purchaseBill} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                ),
                items: vendorBills
                    .map(
                      (bill) => DropdownMenuItem(
                        value: bill.id,
                        child: Text('${bill.billNumber} - ${bill.balanceDue.toStringAsFixed(2)} ${l10n.egp}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  final bill = vendorBills.where((b) => b.id == value).firstOrNull;
                  _update(
                    ref,
                    form
                      ..purchaseBillId = value
                      ..amount = bill?.balanceDue ?? form.amount,
                  );
                },
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: safeAccountId,
                decoration: InputDecoration(
                  labelText: '${l10n.depositAccount} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                ),
                items: depositAccounts
                    .map((account) => DropdownMenuItem(value: account.id, child: Text('${account.code} - ${account.name}')))
                    .toList(),
                onChanged: (value) => _update(ref, form..depositAccountId = value),
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
              key: ValueKey('vendor-credit-amount-${form.purchaseBillId}-${form.amount}'),
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

void _update(WidgetRef ref, VendorCreditFormState old) {
  ref.read(vendorCreditFormProvider.notifier).state = VendorCreditFormState()
    ..vendorId = old.vendorId
    ..purchaseBillId = old.purchaseBillId
    ..depositAccountId = old.depositAccountId
    ..activityDate = old.activityDate
    ..amount = old.amount
    ..action = old.action
    ..paymentMethod = old.paymentMethod;
}

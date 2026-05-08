// vendor_credit_form_screen.dart
// Applies existing vendor credit to bills or records vendor refund receipts.
// Supports direct opening from Purchase Bill details with billId.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../../../core/constants/api_enums.dart'
    show AccountType, PaymentMethod, VendorCreditAction;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../purchase_bills/data/models/purchase_bill_model.dart';
import '../../purchase_bills/providers/purchase_bills_provider.dart';
import '../../vendors/data/models/vendor_model.dart';
import '../../vendors/providers/vendors_provider.dart';
import '../data/models/vendor_credit_model.dart';
import '../providers/vendor_credits_provider.dart';

class VendorCreditFormScreen extends ConsumerStatefulWidget {
  const VendorCreditFormScreen({super.key, this.billId});

  final String? billId;

  @override
  ConsumerState<VendorCreditFormScreen> createState() => _VendorCreditFormScreenState();
}

class _VendorCreditFormScreenState extends ConsumerState<VendorCreditFormScreen> {
  String? _vendorId;
  String? _purchaseBillId;
  String? _depositAccountId;
  DateTime _activityDate = DateTime.now();
  double _amount = 0;
  VendorCreditAction _action = VendorCreditAction.applyToBill;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _saving = false;
  bool _loadingInitialBill = false;

  @override
  void initState() {
    super.initState();
    if (widget.billId != null && widget.billId!.isNotEmpty) {
      Future.microtask(_loadInitialBill);
    }
  }

  Future<void> _loadInitialBill() async {
    final billId = widget.billId;
    if (billId == null || billId.isEmpty) return;

    setState(() => _loadingInitialBill = true);
    final result = await ref.read(purchaseBillsRepositoryProvider).getBill(billId);
    if (!mounted) return;
    setState(() => _loadingInitialBill = false);

    result.when(
      success: (bill) {
        if (!bill.canPay) {
          _error(context, 'This bill does not have a payable balance.');
          return;
        }
        setState(() {
          _vendorId = bill.vendorId;
          _purchaseBillId = bill.id;
          _amount = bill.balanceDue;
          _action = VendorCreditAction.applyToBill;
          _activityDate = DateTime.now();
        });
      },
      failure: (error) => _error(context, error.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vendorsAsync = ref.watch(vendorsProvider);
    final billsAsync = ref.watch(purchaseBillsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    if (_loadingInitialBill) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.newText} ${l10n.creditBalance}'),
        actions: [
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.secondary,
            onPressed: _saving
                ? null
                : () => context.canPop() ? context.pop() : context.go(AppRoutes.vendorCredits),
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
          if (widget.billId != null && widget.billId!.isNotEmpty && _purchaseBillId != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Applying vendor credit to selected bill',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _CreditCard(
            vendorId: _vendorId,
            purchaseBillId: _purchaseBillId,
            depositAccountId: _depositAccountId,
            activityDate: _activityDate,
            amount: _amount,
            action: _action,
            paymentMethod: _paymentMethod,
            vendorsAsync: vendorsAsync,
            billsAsync: billsAsync,
            accountsAsync: accountsAsync,
            onVendorChanged: (value) => setState(() {
              _vendorId = value;
              _purchaseBillId = null;
            }),
            onActionChanged: (value) => setState(() {
              _action = value;
              _purchaseBillId = null;
              _depositAccountId = null;
            }),
            onBillChanged: (bill) => setState(() {
              _purchaseBillId = bill?.id;
              _amount = bill?.balanceDue ?? _amount;
            }),
            onDepositAccountChanged: (value) => setState(() => _depositAccountId = value),
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

    if (_vendorId == null || _vendorId!.isEmpty) {
      _error(context, l10n.selectVendor);
      return;
    }
    if (_amount <= 0) {
      _error(context, l10n.enterPositiveAmount);
      return;
    }
    if (_action == VendorCreditAction.applyToBill && (_purchaseBillId == null || _purchaseBillId!.isEmpty)) {
      _error(context, l10n.selectPurchaseBillFirst);
      return;
    }
    if (_action == VendorCreditAction.refundReceipt && (_depositAccountId == null || _depositAccountId!.isEmpty)) {
      _error(context, l10n.selectDepositAccountFirst);
      return;
    }

    final dto = CreateVendorCreditDto(
      vendorId: _vendorId!,
      activityDate: _activityDate,
      amount: _amount,
      action: _action,
      purchaseBillId: _action == VendorCreditAction.applyToBill ? _purchaseBillId : null,
      depositAccountId: _action == VendorCreditAction.refundReceipt ? _depositAccountId : null,
      paymentMethod: _action == VendorCreditAction.refundReceipt ? _paymentMethod : null,
    );

    setState(() => _saving = true);
    final result = await ref.read(vendorCreditsProvider.notifier).create(dto);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        ref.read(purchaseBillsProvider.notifier).refresh();
        if (_purchaseBillId != null && _purchaseBillId!.isNotEmpty) {
          ref.invalidate(purchaseBillDetailsProvider(_purchaseBillId!));
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.paymentCreatedSuccess)));
        if (context.canPop()) {
          context.pop();
        } else if (_purchaseBillId != null && _purchaseBillId!.isNotEmpty) {
          context.go(AppRoutes.purchaseBillDetails.replaceFirst(':id', _purchaseBillId!));
        } else {
          context.go(AppRoutes.vendorCredits);
        }
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

class _CreditCard extends StatelessWidget {
  const _CreditCard({
    required this.vendorId,
    required this.purchaseBillId,
    required this.depositAccountId,
    required this.activityDate,
    required this.amount,
    required this.action,
    required this.paymentMethod,
    required this.vendorsAsync,
    required this.billsAsync,
    required this.accountsAsync,
    required this.onVendorChanged,
    required this.onActionChanged,
    required this.onBillChanged,
    required this.onDepositAccountChanged,
    required this.onPaymentMethodChanged,
    required this.onAmountChanged,
  });

  final String? vendorId;
  final String? purchaseBillId;
  final String? depositAccountId;
  final DateTime activityDate;
  final double amount;
  final VendorCreditAction action;
  final PaymentMethod paymentMethod;
  final AsyncValue vendorsAsync;
  final AsyncValue<List<PurchaseBillModel>> billsAsync;
  final AsyncValue<List<AccountModel>> accountsAsync;
  final ValueChanged<String?> onVendorChanged;
  final ValueChanged<VendorCreditAction> onActionChanged;
  final ValueChanged<PurchaseBillModel?> onBillChanged;
  final ValueChanged<String?> onDepositAccountChanged;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final ValueChanged<double> onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final vendorBills = billsAsync.maybeWhen(
      data: (bills) => bills
          .where((bill) => vendorId == null || bill.vendorId == vendorId)
          .where((bill) => bill.canPay)
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

    final safeBillId = vendorBills.any((bill) => bill.id == purchaseBillId) ? purchaseBillId : null;
    final safeAccountId = depositAccounts.any((account) => account.id == depositAccountId) ? depositAccountId : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: vendorId,
              decoration: InputDecoration(
                labelText: '${l10n.vendor} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.storefront_outlined),
              ),
              items: vendorsAsync.maybeWhen(
                data: (vendors) => vendors
                    .map<DropdownMenuItem<String>>(
                      (VendorModel vendor) => DropdownMenuItem<String>(
                        value: vendor.id,
                        child: Text('${vendor.displayName} — Credit ${vendor.creditBalance.toStringAsFixed(2)}'),
                      ),
                    )
                    .toList(),
                orElse: () => const <DropdownMenuItem<String>>[],
              ),
              onChanged: onVendorChanged,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<VendorCreditAction>(
                    initialValue: action,
                    decoration: InputDecoration(
                      labelText: l10n.creditBalance,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: [
                      DropdownMenuItem<VendorCreditAction>(
                        value: VendorCreditAction.applyToBill,
                        child: Text(l10n.purchaseBill),
                      ),
                      DropdownMenuItem<VendorCreditAction>(
                        value: VendorCreditAction.refundReceipt,
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
                    initialValue: _VendorCreditFormScreenState._dateOnly(activityDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (action == VendorCreditAction.applyToBill)
              DropdownButtonFormField<String>(
                initialValue: safeBillId,
                decoration: InputDecoration(
                  labelText: '${l10n.purchaseBill} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                ),
                items: vendorBills
                    .map<DropdownMenuItem<String>>(
                      (PurchaseBillModel bill) => DropdownMenuItem<String>(
                        value: bill.id,
                        child: Text('${bill.billNumber} - ${bill.balanceDue.toStringAsFixed(2)} ${l10n.egp}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  final bill = vendorBills.where((b) => b.id == value).firstOrNull;
                  onBillChanged(bill);
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
                    .map<DropdownMenuItem<String>>(
                      (AccountModel account) => DropdownMenuItem<String>(
                        value: account.id,
                        child: Text('${account.code} - ${account.name}'),
                      ),
                    )
                    .toList(),
                onChanged: onDepositAccountChanged,
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
                'Official vendor balance, bill application, deposit, and accounting impact are recalculated by the backend after save.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

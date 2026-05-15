// vendor_credit_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../../../core/constants/api_enums.dart'
    show AccountType, PaymentMethod, VendorCreditAction;
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../purchase_bills/data/models/purchase_bill_model.dart';
import '../../purchase_bills/providers/purchase_bills_provider.dart';
import '../../vendors/data/models/vendor_model.dart';
import '../../vendors/providers/vendors_provider.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
import '../data/models/vendor_credit_model.dart';
import '../providers/vendor_credits_provider.dart';

class VendorCreditFormScreen extends ConsumerStatefulWidget {
  const VendorCreditFormScreen({super.key, this.billId, this.id});

  final String? billId;
  final String? id;

  @override
  ConsumerState<VendorCreditFormScreen> createState() =>
      _VendorCreditFormScreenState();
}

class _VendorCreditFormScreenState
    extends ConsumerState<VendorCreditFormScreen> {
  String? _vendorId;
  String? _purchaseBillId;
  String? _depositAccountId;
  DateTime _activityDate = DateTime.now();
  VendorCreditAction _action = VendorCreditAction.applyToBill;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  VendorCreditModel? _editingCredit;
  bool _saving = false;
  bool _loading = false;

  final _amountCtrl = TextEditingController();
  final _moneyFmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  double get _amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;
  bool get _isDetails => widget.id != null && widget.id!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isDetails) {
      Future.microtask(_loadExistingCredit);
    } else if ((widget.billId ?? '').isNotEmpty) {
      Future.microtask(_loadInitialBill);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingCredit() async {
    final id = widget.id;
    if (id == null || id.isEmpty) return;
    setState(() => _loading = true);
    final result = await ref.read(vendorCreditsRepositoryProvider).getById(id);
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (credit) {
        setState(() {
          _editingCredit = credit;
          _vendorId = credit.vendorId;
          _purchaseBillId = credit.purchaseBillId;
          _depositAccountId = credit.depositAccountId;
          _activityDate = credit.activityDate;
          _action = credit.action;
          _paymentMethod = credit.paymentMethod ?? PaymentMethod.cash;
          _amountCtrl.text = credit.amount.toStringAsFixed(2);
        });
      },
      failure: (error) => _showError(error.message),
    );
  }

  Future<void> _loadInitialBill() async {
    final billId = widget.billId;
    if (billId == null || billId.isEmpty) return;
    setState(() => _loading = true);
    final result = await ref
        .read(purchaseBillsRepositoryProvider)
        .getBill(billId);
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (bill) {
        if (!bill.canPay) {
          _showError('This bill does not have a payable balance.');
          return;
        }
        setState(() {
          _vendorId = bill.vendorId;
          _purchaseBillId = bill.id;
          _action = VendorCreditAction.applyToBill;
          _activityDate = DateTime.now();
          _amountCtrl.text = bill.balanceDue.toStringAsFixed(2);
        });
      },
      failure: (error) => _showError(error.message),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _activityDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) setState(() => _activityDate = picked);
  }

  void _clear() {
    setState(() {
      _vendorId = null;
      _purchaseBillId = null;
      _depositAccountId = null;
      _activityDate = DateTime.now();
      _action = VendorCreditAction.applyToBill;
      _paymentMethod = PaymentMethod.cash;
      _editingCredit = null;
      _amountCtrl.clear();
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_vendorId == null || _vendorId!.isEmpty) {
      _showError(l10n.selectVendor);
      return;
    }
    if (_amount <= 0) {
      _showError(l10n.enterPositiveAmount);
      return;
    }
    if (_action == VendorCreditAction.applyToBill &&
        (_purchaseBillId == null || _purchaseBillId!.isEmpty)) {
      _showError(l10n.selectPurchaseBillFirst);
      return;
    }
    if (_action == VendorCreditAction.refundReceipt &&
        (_depositAccountId == null || _depositAccountId!.isEmpty)) {
      _showError(l10n.selectDepositAccountFirst);
      return;
    }

    final dto = CreateVendorCreditDto(
      vendorId: _vendorId!,
      activityDate: _activityDate,
      amount: _amount,
      action: _action,
      purchaseBillId: _action == VendorCreditAction.applyToBill
          ? _purchaseBillId
          : null,
      depositAccountId: _action == VendorCreditAction.refundReceipt
          ? _depositAccountId
          : null,
      paymentMethod: _action == VendorCreditAction.refundReceipt
          ? _paymentMethod
          : null,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Vendor credit saved.')));
        context.go(AppRoutes.vendorCredits);
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
    final vendors = ref.watch(vendorsProvider).maybeWhen(
          data: (items) => items.where((vendor) => vendor.isActive).toList(),
          orElse: () => const <VendorModel>[],
        );
    final bills = ref.watch(purchaseBillsProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <PurchaseBillModel>[],
        );
    final accounts = ref.watch(accountsProvider).maybeWhen(
          data: (items) => items,
          orElse: () => const <AccountModel>[],
        );

    final selectedVendor = vendors.where((vendor) => vendor.id == _vendorId).firstOrNull;
    final openBills = bills
        .where((bill) => _vendorId == null || bill.vendorId == _vendorId)
        .where((bill) => bill.canPay)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final selectedBill = openBills.where((bill) => bill.id == _purchaseBillId).firstOrNull;
    final depositAccounts = accounts
        .where(
          (account) =>
              account.isActive &&
              (account.accountType == AccountType.bank ||
                  account.accountType == AccountType.otherCurrentAsset ||
                  account.accountType == AccountType.creditCard),
        )
        .toList();
    final selectedAccount =
        depositAccounts.where((account) => account.id == _depositAccountId).firstOrNull;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final credits = ref.watch(vendorCreditsProvider).maybeWhen(
          data: (items) => items,
          orElse: () => <VendorCreditModel>[],
        );

    final currentIdx = widget.id != null ? credits.indexWhere((c) => c.id == widget.id) : -1;

    void navigateTo(int idx) {
      if (idx >= 0 && idx < credits.length) {
        context.go(AppRoutes.vendorCreditDetails.replaceFirst(':id', credits[idx].id));
      }
    }

    return TransactionWorkspaceShell(
      workspaceName: 'Vendor credit workspace',
      saving: _saving,
      posting: _loading,
      isEdit: _isDetails,
      readOnly: false,
      onFind: () => context.go(AppRoutes.vendorCredits),
      onPrevious: _isDetails
          ? (currentIdx > 0 ? () => navigateTo(currentIdx - 1) : null)
          : (credits.isNotEmpty ? () => navigateTo(0) : null),
      onNext: _isDetails && currentIdx < credits.length - 1 && currentIdx != -1
          ? () => navigateTo(currentIdx + 1)
          : null,
      onNew: _clear,
      onSave: _saving ? null : _save,
      onClear: _clear,
      onClose: () => context.go(AppRoutes.vendorCredits),
      formContent: Column(
        children: [
          _CreditHeader(
            vendors: vendors,
            vendor: selectedVendor,
            action: _action,
            dateText: _dateFmt.format(_activityDate),
            reference: _editingCredit?.referenceNumber ?? 'AUTO',
            amount: _amount,
            money: _moneyFmt.format,
            onVendorSelected: (vendor) => setState(() {
              _vendorId = vendor.id;
              _purchaseBillId = null;
            }),
            onActionChanged: (action) => setState(() {
              _action = action;
              _purchaseBillId = null;
              _depositAccountId = null;
            }),
            onPickDate: _pickDate,
          ),
          _ModeToolbar(action: _action),
          Expanded(
            child: _action == VendorCreditAction.applyToBill
                ? _BillCreditGrid(
                    bills: openBills,
                    selectedBillId: _purchaseBillId,
                    money: _moneyFmt.format,
                    date: _dateFmt.format,
                    onSelected: (bill) => setState(() {
                      _purchaseBillId = bill.id;
                      _amountCtrl.text = bill.balanceDue.toStringAsFixed(2);
                    }),
                  )
                : _RefundReceiptPanel(
                    accounts: depositAccounts,
                    selectedAccount: selectedAccount,
                    paymentMethod: _paymentMethod,
                    onAccountChanged: (account) => setState(
                      () => _depositAccountId = account?.id,
                    ),
                    onPaymentMethodChanged: (method) => setState(() => _paymentMethod = method),
                  ),
          ),
          _CreditFooter(
            amountCtrl: _amountCtrl,
            amount: _amount,
            money: _moneyFmt.format,
            saving: _saving,
            onAmountChanged: () => setState(() {}),
            onSave: _saving ? null : _save,
            onClear: _clear,
          ),
        ],
      ),
      contextPanel: _VendorCreditContextPanel(
        vendor: selectedVendor,
        bill: selectedBill,
        depositAccount: selectedAccount,
        action: _action,
        amount: _amount,
        money: _moneyFmt.format,
      ),
    );
  }
}

class _VendorCreditContextPanel extends StatelessWidget {
  const _VendorCreditContextPanel({
    required this.vendor,
    required this.bill,
    required this.depositAccount,
    required this.action,
    required this.amount,
    required this.money,
  });

  final VendorModel? vendor;
  final PurchaseBillModel? bill;
  final AccountModel? depositAccount;
  final VendorCreditAction action;
  final double amount;
  final String Function(double) money;

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
              'Vendor Credit Info',
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
                _SidebarStat(label: 'AMOUNT', value: money(amount), isTotal: true),
                if (vendor != null) _SidebarStat(label: 'VENDOR', value: vendor!.displayName),
                if (action == VendorCreditAction.applyToBill && bill != null)
                  _SidebarStat(label: 'APPLIED TO', value: 'Bill #${bill!.billNumber}'),
                if (action == VendorCreditAction.refundReceipt && depositAccount != null)
                  _SidebarStat(label: 'REFUND TO', value: depositAccount!.name),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarStat extends StatelessWidget {
  const _SidebarStat({required this.label, required this.value, this.isTotal = false});
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
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7D8B93), fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700, color: const Color(0xFF264D5B))),
        ],
      ),
    );
  }
}



class _CreditHeader extends StatelessWidget {
  const _CreditHeader({
    required this.vendors,
    required this.vendor,
    required this.action,
    required this.dateText,
    required this.reference,
    required this.amount,
    required this.money,
    required this.onVendorSelected,
    required this.onActionChanged,
    required this.onPickDate,
  });

  final List<VendorModel> vendors;
  final VendorModel? vendor;
  final VendorCreditAction action;
  final String dateText;
  final String reference;
  final double amount;
  final String Function(double value) money;
  final ValueChanged<VendorModel> onVendorSelected;
  final ValueChanged<VendorCreditAction> onActionChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
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
                const _StripLabel('VENDOR'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: _InlineVendorField(
                    vendors: vendors,
                    selected: vendor,
                    onSelected: onVendorSelected,
                  ),
                ),
                const SizedBox(width: 16),
                const _StripLabel('ACTION'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: _ActionField(
                    value: action,
                    onChanged: onActionChanged,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 300,
                    child: Text(
                      'Vendor Credit',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF243E4A),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 280,
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
                          label: 'CREDIT #',
                          child: _StaticBox(text: reference),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _StatBox(
                          label: 'VENDOR BALANCE',
                          value: vendor == null ? '-' : money(vendor!.balance),
                          accent: false,
                        ),
                        const SizedBox(height: 6),
                        _StatBox(
                          label: 'AVAILABLE CREDIT',
                          value: vendor == null
                              ? '-'
                              : money(vendor!.creditBalance),
                          accent: false,
                        ),
                        const SizedBox(height: 6),
                        _StatBox(
                          label: 'THIS CREDIT',
                          value: money(amount),
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

class _ModeToolbar extends StatelessWidget {
  const _ModeToolbar({required this.action});

  final VendorCreditAction action;

  @override
  Widget build(BuildContext context) {
    final applying = action == VendorCreditAction.applyToBill;
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
            applying ? 'Open Vendor Bills' : 'Refund Receipt',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF233F4C),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            applying
                ? 'Select one bill to apply this vendor credit'
                : 'Choose the deposit account and payment method',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF596B74),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillCreditGrid extends StatelessWidget {
  const _BillCreditGrid({
    required this.bills,
    required this.selectedBillId,
    required this.money,
    required this.date,
    required this.onSelected,
  });

  final List<PurchaseBillModel> bills;
  final String? selectedBillId;
  final String Function(double value) money;
  final String Function(DateTime value) date;
  final ValueChanged<PurchaseBillModel> onSelected;

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) {
      return const Center(
        child: Text(
          'Select a vendor with open bills.',
          style: TextStyle(
            color: Color(0xFF60747D),
            fontWeight: FontWeight.w700,
          ),
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
              height: 30,
              color: const Color(0xFFDDE8ED),
              child: const Row(
                children: [
                  SizedBox(width: 44),
                  _HeaderCell('BILL #', flex: 2),
                  _HeaderCell('DATE', flex: 1),
                  _HeaderCell('DUE DATE', flex: 1),
                  _HeaderCell('TOTAL', flex: 1, right: true),
                  _HeaderCell('PAID', flex: 1, right: true),
                  _HeaderCell('BALANCE', flex: 1, right: true),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: bills.length,
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  final selected = bill.id == selectedBillId;
                  return InkWell(
                    onTap: () => onSelected(bill),
                    child: Container(
                      height: 36,
                      color: selected
                          ? const Color(0xFFCFE5EC)
                          : index.isEven
                          ? const Color(0xFFDDEFF4)
                          : Colors.white,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Radio<String>(
                              value: bill.id,
                              groupValue: selectedBillId,
                              onChanged: (_) => onSelected(bill),
                            ),
                          ),
                          _GridCell(bill.billNumber, flex: 2, strong: true),
                          _GridCell(date(bill.billDate), flex: 1),
                          _GridCell(date(bill.dueDate), flex: 1),
                          _GridCell(
                            money(bill.totalAmount),
                            flex: 1,
                            right: true,
                          ),
                          _GridCell(
                            money(bill.amountPaid),
                            flex: 1,
                            right: true,
                          ),
                          _GridCell(
                            money(bill.balanceDue),
                            flex: 1,
                            right: true,
                            strong: true,
                          ),
                        ],
                      ),
                    ),
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

class _RefundReceiptPanel extends StatelessWidget {
  const _RefundReceiptPanel({
    required this.accounts,
    required this.selectedAccount,
    required this.paymentMethod,
    required this.onAccountChanged,
    required this.onPaymentMethodChanged,
  });

  final List<AccountModel> accounts;
  final AccountModel? selectedAccount;
  final PaymentMethod paymentMethod;
  final ValueChanged<AccountModel?> onAccountChanged;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF9EADB6)),
        ),
        child: Column(
          children: [
            Container(
              height: 30,
              color: const Color(0xFFDDE8ED),
              child: const Row(
                children: [
                  _HeaderCell('DEPOSIT ACCOUNT', flex: 3),
                  _HeaderCell('PAYMENT METHOD', flex: 2),
                  _HeaderCell('ACCOUNT TYPE', flex: 2),
                ],
              ),
            ),
            Container(
              height: 44,
              color: const Color(0xFFDDEFF4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 5,
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedAccount?.id,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
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
                        onChanged: (id) => onAccountChanged(
                          accounts
                              .where((account) => account.id == id)
                              .firstOrNull,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 5,
                      ),
                      child: DropdownButtonFormField<PaymentMethod>(
                        initialValue: paymentMethod,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: PaymentMethod.cash,
                            child: Text('Cash'),
                          ),
                          DropdownMenuItem(
                            value: PaymentMethod.check,
                            child: Text('Check'),
                          ),
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
                          if (method != null) onPaymentMethodChanged(method);
                        },
                      ),
                    ),
                  ),
                  _GridCell(selectedAccount?.accountTypeName ?? '-', flex: 2),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Refund receipts increase the selected deposit account and reduce vendor credit.',
                  style: TextStyle(
                    color: Color(0xFF60747D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditFooter extends StatelessWidget {
  const _CreditFooter({
    required this.amountCtrl,
    required this.amount,
    required this.money,
    required this.saving,
    required this.onAmountChanged,
    required this.onClear,
    this.onSave,
  });

  final TextEditingController amountCtrl;
  final double amount;
  final String Function(double value) money;
  final bool saving;
  final VoidCallback onAmountChanged;
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
              'Vendor credit posts automatically when saved and updates vendor payable balances.',
              style: TextStyle(
                color: Color(0xFF53656E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 340,
            child: Row(
              children: [
                const SizedBox(width: 115, child: _FieldLabel('AMOUNT')),
                Expanded(
                  child: TextField(
                    controller: amountCtrl,
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
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) => onAmountChanged(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 230,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1F4),
              border: Border.all(color: const Color(0xFF9DB2BC)),
            ),
            child: _AmountRow(
              label: 'CREDIT TOTAL',
              value: money(amount),
              strong: true,
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: onSave,
            style: _smallButton(),
            child: Text(saving ? 'Saving...' : 'Save & Close'),
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

class _CreditSidePanel extends StatefulWidget {
  const _CreditSidePanel({
    required this.vendor,
    required this.bill,
    required this.depositAccount,
    required this.action,
    required this.amount,
    required this.money,
  });

  final VendorModel? vendor;
  final PurchaseBillModel? bill;
  final AccountModel? depositAccount;
  final VendorCreditAction action;
  final double amount;
  final String Function(double value) money;

  @override
  State<_CreditSidePanel> createState() => _CreditSidePanelState();
}

class _CreditSidePanelState extends State<_CreditSidePanel> {
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
          if (_expanded) Positioned.fill(child: _content(context)),
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

  Widget _content(BuildContext context) {
    final vendor = widget.vendor;
    if (vendor == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 38,
                color: Color(0xFF8CA0AA),
              ),
              SizedBox(height: 12),
              Text(
                'Select a vendor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2D4854),
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Choose a vendor to apply credits or record refunds.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF667A84), height: 1.35),
              ),
            ],
          ),
        ),
      );
    }

    final applyToBill = widget.action == VendorCreditAction.applyToBill;
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
                vendor.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                vendor.companyName ?? vendor.primaryContact,
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
            widget.amount <= 0
                ? 'Enter credit amount before saving.'
                : applyToBill
                ? 'Credit will reduce the selected bill balance.'
                : 'Refund receipt will post to the deposit account.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF714600),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _SideSection(
          title: 'Vendor Summary',
          child: Column(
            children: [
              _InfoRow(
                label: 'Open balance',
                value: widget.money(vendor.balance),
              ),
              _InfoRow(
                label: 'Credit balance',
                value: widget.money(vendor.creditBalance),
              ),
              const Divider(height: 14),
              _InfoRow(
                label: 'This credit',
                value: widget.money(widget.amount),
                strong: true,
              ),
            ],
          ),
        ),
        _SideSection(
          title: applyToBill ? 'Selected Bill' : 'Refund Deposit',
          child: Column(
            children: applyToBill
                ? [
                    _InfoRow(
                      label: 'Bill #',
                      value: widget.bill?.billNumber ?? '-',
                    ),
                    _InfoRow(
                      label: 'Balance due',
                      value: widget.bill == null
                          ? '-'
                          : widget.money(widget.bill!.balanceDue),
                    ),
                  ]
                : [
                    _InfoRow(
                      label: 'Deposit to',
                      value: widget.depositAccount?.name ?? '-',
                    ),
                    _InfoRow(label: 'Method', value: 'Refund receipt'),
                  ],
          ),
        ),
        const Expanded(
          child: _SideSection(
            title: 'Notes',
            expanded: true,
            child: Text(
              'No notes added.',
              style: TextStyle(color: Color(0xFF4E616A)),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineVendorField extends StatelessWidget {
  const _InlineVendorField({
    required this.vendors,
    required this.selected,
    required this.onSelected,
  });

  final List<VendorModel> vendors;
  final VendorModel? selected;
  final ValueChanged<VendorModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<VendorModel>(
      key: ValueKey(selected?.id ?? 'vendor-credit-vendor'),
      displayStringForOption: (vendor) => vendor.displayName,
      initialValue: TextEditingValue(text: selected?.displayName ?? ''),
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return vendors.take(20);
        return vendors
            .where((vendor) => vendor.displayName.toLowerCase().contains(query))
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
              hintText: 'Select vendor...',
            ),
          ),
        );
      },
    );
  }
}

class _ActionField extends StatelessWidget {
  const _ActionField({required this.value, required this.onChanged});

  final VendorCreditAction value;
  final ValueChanged<VendorCreditAction> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: DropdownButtonFormField<VendorCreditAction>(
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
          DropdownMenuItem(
            value: VendorCreditAction.applyToBill,
            child: Text('Apply to Bill'),
          ),
          DropdownMenuItem(
            value: VendorCreditAction.refundReceipt,
            child: Text('Refund Receipt'),
          ),
        ],
        onChanged: (action) {
          if (action != null) onChanged(action);
        },
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex, this.right = false});
  final String text;
  final int flex;
  final bool right;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
          color: const Color(0xFF273F4B),
          fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
    ),
  );
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.accent,
  });
  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
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



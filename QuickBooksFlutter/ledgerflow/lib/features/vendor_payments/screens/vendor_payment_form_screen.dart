// vendor_payment_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../../purchase_bills/data/models/purchase_bill_model.dart';
import '../../purchase_bills/providers/purchase_bills_provider.dart';
import '../../transactions/widgets/transaction_context_sidebar.dart';
import '../../transactions/widgets/transaction_models.dart';
import '../../vendors/data/models/vendor_model.dart';
import '../../vendors/providers/vendors_provider.dart';
import 'package:ledgerflow/features/accounts/providers/accounts_provider.dart';
import '../providers/vendor_payments_provider.dart';

class VendorPaymentFormScreen extends ConsumerStatefulWidget {
  const VendorPaymentFormScreen({super.key, this.billId});

  final String? billId;

  @override
  ConsumerState<VendorPaymentFormScreen> createState() =>
      _VendorPaymentFormScreenState();
}

class _VendorPaymentFormScreenState
    extends ConsumerState<VendorPaymentFormScreen> {
  VendorModel? _selectedVendor;
  List<PurchaseBillModel> _openBills = [];
  final Set<String> _selectedBillIds = {};
  final Map<String, TextEditingController> _amountControllers = {};

  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'Cash';
  String? _paymentAccountId;

  bool _loadingInitialBill = false;
  bool _loadingBills = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.billId != null && widget.billId!.isNotEmpty) {
      Future.microtask(_loadInitialBill);
    }
  }

  @override
  void dispose() {
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialBill() async {
    final billId = widget.billId;
    if (billId == null || billId.isEmpty) return;

    setState(() => _loadingInitialBill = true);
    try {
      final result = await ref
          .read(purchaseBillsRepositoryProvider)
          .getBill(billId);
      if (!mounted) return;
      result.when(
        success: (bill) async {
          if (!bill.canPay) {
            _showError('This bill is not payable.');
            return;
          }
          setState(() {
            _selectedVendor = VendorModel(
              id: bill.vendorId,
              displayName: bill.vendorName,
              isActive: true,
              balance: bill.balanceDue,
              creditBalance: 0,
            );
          });
          await _fetchOpenBills(bill.vendorId, preselectBillId: bill.id);
        },
        failure: (e) => _showError(e.message),
      );
    } finally {
      if (mounted) setState(() => _loadingInitialBill = false);
    }
  }

  void _onVendorChanged(VendorModel vendor) {
    setState(() {
      _selectedVendor = vendor;
      _selectedBillIds.clear();
      _openBills = [];
      for (final c in _amountControllers.values) {
        c.dispose();
      }
      _amountControllers.clear();
    });
    _fetchOpenBills(vendor.id);
  }

  Future<void> _fetchOpenBills(
    String vendorId, {
    String? preselectBillId,
  }) async {
    setState(() => _loadingBills = true);
    try {
      final result = await ref
          .read(purchaseBillsRepositoryProvider)
          .getBills(vendorId: vendorId);
      result.when(
        success: (bills) {
          setState(() {
            _selectedBillIds.clear();
            for (final c in _amountControllers.values) {
              c.dispose();
            }
            _amountControllers.clear();

            _openBills = bills.where((b) => b.canPay).toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
            for (final bill in _openBills) {
              _amountControllers[bill.id] = TextEditingController(
                text: bill.balanceDue.toStringAsFixed(2),
              );
            }

            if (preselectBillId != null &&
                _openBills.any((bill) => bill.id == preselectBillId)) {
              _selectedBillIds.add(preselectBillId);
            }
          });
        },
        failure: (e) => _showError(e.message),
      );
    } finally {
      if (mounted) setState(() => _loadingBills = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedVendor == null) {
      _showError(l10n.selectVendor);
      return;
    }
    if (_paymentAccountId == null || _paymentAccountId!.isEmpty) {
      _showError(l10n.paymentAccount);
      return;
    }
    if (_selectedBillIds.isEmpty) {
      _showError(l10n.selectBillsToPay);
      return;
    }

    final amounts = <String, double>{};
    for (final id in _selectedBillIds) {
      final amount = double.tryParse(_amountControllers[id]?.text ?? '0') ?? 0;
      final bill = _openBills.firstWhere((b) => b.id == id);

      if (amount <= 0) {
        _showError(l10n.amountPaid);
        return;
      }
      if (amount > bill.balanceDue) {
        _showError(
          '${l10n.amountPaid} > ${bill.balanceDue.toStringAsFixed(2)}',
        );
        return;
      }
      amounts[id] = amount;
    }

    setState(() => _saving = true);
    try {
      final result = await ref
          .read(vendorPaymentsProvider.notifier)
          .createBatchPayment(
            billIds: _selectedBillIds.toList(),
            amounts: amounts,
            paymentAccountId: _paymentAccountId!,
            paymentDate: _paymentDate,
            paymentMethod: _paymentMethod,
          );

      result.when(
        success: (_) {
          ref.read(purchaseBillsProvider.notifier).refresh();
          for (final id in _selectedBillIds) {
            ref.invalidate(purchaseBillDetailsProvider(id));
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.paymentCreatedSuccess)));
          if (_selectedBillIds.length == 1) {
            context.go(
              AppRoutes.purchaseBillDetails.replaceFirst(
                ':id',
                _selectedBillIds.first,
              ),
            );
          } else {
            context.go(AppRoutes.purchaseBills);
          }
        },
        failure: (e) => _showError(e.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clear() {
    setState(() {
      _selectedVendor = null;
      _openBills = [];
      _selectedBillIds.clear();
      _paymentDate = DateTime.now();
      _paymentMethod = 'Cash';
      _paymentAccountId = null;
      for (final c in _amountControllers.values) {
        c.dispose();
      }
      _amountControllers.clear();
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vendors = ref
        .watch(vendorsProvider)
        .maybeWhen(
          data: (items) => items.where((vendor) => vendor.isActive).toList(),
          orElse: () => const <VendorModel>[],
        );

    if (_loadingInitialBill) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: SafeArea(
        child: Column(
          children: [
            _PaymentCommandBar(
              saving: _saving,
              onFind: () => context.go(AppRoutes.vendorPayments),
              onNew: () => context.go(AppRoutes.vendorPaymentNew),
              onSave: _saving ? null : _save,
              onClear: _clear,
              onClose: () => context.go(AppRoutes.vendorPayments),
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
                            l10n: l10n,
                            vendors: vendors,
                            selectedVendor: _selectedVendor,
                            paymentDate: _paymentDate,
                            paymentMethod: _paymentMethod,
                            paymentAccountId: _paymentAccountId,
                            onVendorChanged: _onVendorChanged,
                            onPaymentDateChanged: (d) =>
                                setState(() => _paymentDate = d),
                            onPaymentMethodChanged: (value) =>
                                setState(() => _paymentMethod = value),
                            onPaymentAccountChanged: (value) =>
                                setState(() => _paymentAccountId = value),
                          ),
                          const _BillsHeader(),
                          Expanded(
                            child: _loadingBills
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _openBills.isEmpty
                                ? Center(
                                    child: Text(
                                      _selectedVendor == null
                                          ? l10n.selectVendorHint
                                          : l10n.noRecentTransactions,
                                    ),
                                  )
                                : _PayBillsGrid(
                                    bills: _openBills,
                                    selectedBillIds: _selectedBillIds,
                                    amountControllers: _amountControllers,
                                    currency: l10n.egp,
                                    onChanged: () => setState(() {}),
                                  ),
                          ),
                          _PaymentFooter(
                            total: _calculateTotal(),
                            currency: l10n.egp,
                            saving: _saving,
                            onSave: _saving ? null : _save,
                            onClear: _clear,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _CollapsiblePaymentPanel(
                    child: _PaymentContextPanel(
                      vendor: _selectedVendor,
                      openBills: _openBills,
                      total: _calculateTotal(),
                      currency: l10n.egp,
                      onViewAll: _selectedVendor == null
                          ? null
                          : () => context.go(AppRoutes.purchaseBills),
                    ),
                  ),
                ],
              ),
            ),
            const _PaymentShortcutStrip(),
          ],
        ),
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (final id in _selectedBillIds) {
      total += double.tryParse(_amountControllers[id]?.text ?? '0') ?? 0;
    }
    return total;
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
            label: saving ? 'Saving' : 'Save',
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
    required this.l10n,
    required this.vendors,
    required this.selectedVendor,
    required this.paymentDate,
    required this.paymentMethod,
    required this.paymentAccountId,
    required this.onVendorChanged,
    required this.onPaymentDateChanged,
    required this.onPaymentMethodChanged,
    required this.onPaymentAccountChanged,
  });

  final AppLocalizations l10n;
  final List<VendorModel> vendors;
  final VendorModel? selectedVendor;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? paymentAccountId;
  final ValueChanged<VendorModel> onVendorChanged;
  final ValueChanged<DateTime> onPaymentDateChanged;
  final ValueChanged<String> onPaymentMethodChanged;
  final ValueChanged<String?> onPaymentAccountChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    selected: selectedVendor,
                    onSelected: (vendor) {
                      if (vendor != null) onVendorChanged(vendor);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const _StripLabel('ACCOUNT'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _PaymentAccountField(
                    selectedAccountId: paymentAccountId,
                    onChanged: onPaymentAccountChanged,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 128,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 230,
                    child: Text(
                      'Pay Bills',
                      style: theme.textTheme.headlineMedium?.copyWith(
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
                          child: _DateBox(
                            value: paymentDate,
                            onChanged: onPaymentDateChanged,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _HorizontalField(
                          label: 'METHOD',
                          child: _PaymentMethodField(
                            value: paymentMethod,
                            onChanged: onPaymentMethodChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('PAYING VENDOR'),
                        const SizedBox(height: 4),
                        Container(
                          height: 70,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFB7C3CB)),
                          ),
                          child: Text(
                            selectedVendor?.displayName ?? 'Select a vendor',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: selectedVendor == null
                                  ? const Color(0xFF7B8B93)
                                  : const Color(0xFF253C47),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

class _InlineVendorField extends StatelessWidget {
  const _InlineVendorField({
    required this.vendors,
    required this.selected,
    required this.onSelected,
  });

  final List<VendorModel> vendors;
  final VendorModel? selected;
  final ValueChanged<VendorModel?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<VendorModel>(
      key: ValueKey(selected?.id ?? 'payment-vendor'),
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
              hintText: 'Select vendor',
            ),
          ),
        );
      },
    );
  }
}

class _PaymentAccountField extends ConsumerWidget {
  const _PaymentAccountField({
    required this.selectedAccountId,
    required this.onChanged,
  });

  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    return accountsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(e.toString()),
      data: (accounts) {
        final paymentAccounts = accounts
            .where((a) => a.accountType.value == 1 || a.accountType.value == 7)
            .toList();
        final safeValue = paymentAccounts.any((a) => a.id == selectedAccountId)
            ? selectedAccountId
            : null;
        return DropdownButtonFormField<String>(
          initialValue: safeValue,
          isDense: true,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          ),
          items: paymentAccounts
              .map(
                (a) => DropdownMenuItem<String>(
                  value: a.id,
                  child: Text(a.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}

class _PaymentMethodField extends StatelessWidget {
  const _PaymentMethodField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isDense: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
      items: const [
        'Cash',
        'Check',
        'Credit Card',
        'Bank Transfer',
      ].map((m) => DropdownMenuItem<String>(value: m, child: Text(m))).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.value, required this.onChanged});

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
          lastDate: DateTime(2035),
        );
        if (picked != null) onChanged(picked);
      },
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
              child: Text(
                '${value.day}/${value.month}/${value.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 15),
          ],
        ),
      ),
    );
  }
}

class _BillsHeader extends StatelessWidget {
  const _BillsHeader();

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
            'Open Bills',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF233F4C),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Select bills and enter payment amount',
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

class _PayBillsGrid extends StatelessWidget {
  const _PayBillsGrid({
    required this.bills,
    required this.selectedBillIds,
    required this.amountControllers,
    required this.currency,
    required this.onChanged,
  });

  final List<PurchaseBillModel> bills;
  final Set<String> selectedBillIds;
  final Map<String, TextEditingController> amountControllers;
  final String currency;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
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
                  _HeaderCell('', flex: 1),
                  _HeaderCell('DATE', flex: 2),
                  _HeaderCell('NUM', flex: 2),
                  _HeaderCell('VENDOR', flex: 4),
                  _HeaderCell('DUE', flex: 2, right: true),
                  _HeaderCell('PAYMENT', flex: 2, right: true),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: bills.length,
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  final selected = selectedBillIds.contains(bill.id);
                  final shaded = index.isEven;
                  return Container(
                    height: 34,
                    color: shaded ? const Color(0xFFDDEFF4) : Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFFB8C6CE)),
                              ),
                            ),
                            child: Checkbox(
                              value: selected,
                              onChanged: (value) {
                                if (value == true) {
                                  selectedBillIds.add(bill.id);
                                } else {
                                  selectedBillIds.remove(bill.id);
                                }
                                onChanged();
                              },
                            ),
                          ),
                        ),
                        _Cell(_date(bill.billDate), flex: 2),
                        _Cell(
                          bill.billNumber.isEmpty ? 'Bill' : bill.billNumber,
                          flex: 2,
                        ),
                        _Cell(bill.vendorName, flex: 4),
                        _Cell(
                          '${bill.balanceDue.toStringAsFixed(2)} $currency',
                          flex: 2,
                          right: true,
                          strong: true,
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: double.infinity,
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFFB8C6CE)),
                              ),
                            ),
                            child: TextField(
                              controller: amountControllers[bill.id],
                              enabled: selected,
                              textAlign: TextAlign.end,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => onChanged(),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                      ],
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

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _PaymentFooter extends StatelessWidget {
  const _PaymentFooter({
    required this.total,
    required this.currency,
    required this.saving,
    required this.onClear,
    this.onSave,
  });

  final double total;
  final String currency;
  final bool saving;
  final VoidCallback onClear;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F9),
        border: Border(top: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Official bill balances and accounting impact are recalculated by the backend after save.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF53646D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 310,
            child: Column(
              children: [
                _AmountRow(
                  label: 'TOTAL PAYMENT',
                  amount: total,
                  currency: currency,
                ),
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
                    label: 'PAY BILLS',
                    amount: total,
                    currency: currency,
                    strong: true,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
              ],
            ),
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

class _CollapsiblePaymentPanel extends StatefulWidget {
  const _CollapsiblePaymentPanel({required this.child});
  final Widget child;

  @override
  State<_CollapsiblePaymentPanel> createState() =>
      _CollapsiblePaymentPanelState();
}

class _CollapsiblePaymentPanelState extends State<_CollapsiblePaymentPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: _expanded ? 258 : 38,
      margin: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: const Color(0xFFB9C3CA)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (_expanded) Positioned.fill(child: widget.child),
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
                    size: 22,
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
}

class _PaymentContextPanel extends StatelessWidget {
  const _PaymentContextPanel({
    required this.vendor,
    required this.openBills,
    required this.total,
    required this.currency,
    this.onViewAll,
  });

  final VendorModel? vendor;
  final List<PurchaseBillModel> openBills;
  final double total;
  final String currency;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final v = vendor;
    final openTotal = openBills.fold<double>(
      0,
      (sum, bill) => sum + bill.balanceDue,
    );
    return TransactionContextSidebar(
      title: v?.displayName ?? '',
      subtitle: v?.companyName,
      initials: v == null ? null : _initials(v.displayName),
      emptyTitle: 'Select a vendor',
      emptyMessage: 'Choose a vendor to see open bills and payment activity.',
      partyTabLabel: 'Vendor',
      warning: v == null ? null : 'Vendor payment batch.',
      metrics: [
        TransactionContextMetric(
          label: 'Open bills',
          value: openBills.length.toString(),
          icon: Icons.receipt_long_outlined,
        ),
        TransactionContextMetric(
          label: 'Open balance',
          value: '${openTotal.toStringAsFixed(2)} $currency',
          icon: Icons.account_balance_wallet_outlined,
        ),
        TransactionContextMetric(
          label: 'Payment total',
          value: '${total.toStringAsFixed(2)} $currency',
          icon: Icons.payments_outlined,
        ),
      ],
      activities: openBills
          .take(6)
          .map(
            (bill) => TransactionContextActivity(
              title: bill.billNumber.isEmpty ? 'Bill' : bill.billNumber,
              subtitle: _PayBillsGrid._date(bill.dueDate),
              amount: '${bill.balanceDue.toStringAsFixed(2)} $currency',
            ),
          )
          .toList(),
      notes: '',
      totals: TransactionTotalsUiModel(
        subtotal: total,
        total: total,
        paid: total,
        balanceDue: 0,
        currency: currency,
      ),
      onViewAll: onViewAll,
    );
  }

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'V';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _PaymentShortcutStrip extends StatelessWidget {
  const _PaymentShortcutStrip();

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
      'Pay bills workspace  •  Save & Close  •  Ctrl+P Print  •  Esc Close',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: const Color(0xFF33434C),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
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

class _HorizontalField extends StatelessWidget {
  const _HorizontalField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 82, child: _FieldLabel(label)),
      Expanded(child: child),
    ],
  );
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

class _Cell extends StatelessWidget {
  const _Cell(
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
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

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    required this.currency,
    this.strong = false,
  });

  final String label;
  final double amount;
  final String currency;
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
        '${amount.toStringAsFixed(2)} $currency',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    ],
  );
}

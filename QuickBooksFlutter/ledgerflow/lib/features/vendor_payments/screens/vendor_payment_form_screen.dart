// vendor_payment_form_screen.dart
// Batch payment screen with Sidebar and multi-bill selection.
// Supports direct opening from Purchase Bill details with a preselected bill.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../core/widgets/transaction_sidebar.dart';
import '../../../../core/widgets/transaction_vendor_picker.dart';
import '../../accounts/data/models/account_model.dart';
import '../../purchase_bills/data/models/purchase_bill_model.dart';
import '../../purchase_bills/providers/purchase_bills_provider.dart';
import '../../vendors/data/models/vendor_model.dart';
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
  PurchaseBillModel? _initialBill;
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
            _initialBill = bill;
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
      _initialBill = null;
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
      final repo = ref.read(purchaseBillsRepositoryProvider);
      final result = await repo.getBills(vendorId: vendorId);
      result.when(
        success: (bills) {
          setState(() {
            _selectedBillIds.clear();
            for (final c in _amountControllers.values) {
              c.dispose();
            }
            _amountControllers.clear();

            _openBills = bills.where((b) => b.canPay).toList();
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
          if (context.canPop()) {
            context.pop();
          } else if (_selectedBillIds.length == 1) {
            context.go('/purchases/bills/${_selectedBillIds.first}');
          } else {
            context.go('/purchases/bills');
          }
        },
        failure: (e) => _showError(e.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loadingInitialBill) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.payBills} | ${l10n.purchases}')),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (_initialBill != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Paying ${_initialBill!.billNumber} — Due ${_initialBill!.balanceDue.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: VendorPickerField(
                              value: _selectedVendor,
                              onChanged: _onVendorChanged,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DatePickerField(
                              label: l10n.paymentDate,
                              value: _paymentDate,
                              onChanged: (d) =>
                                  setState(() => _paymentDate = d),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, _) {
                                final accountsAsync = ref.watch(
                                  accountsProvider,
                                );
                                return accountsAsync.when(
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (e, _) => Text(e.toString()),
                                  data: (accounts) {
                                    final paymentAccounts = accounts
                                        .where(
                                          (a) =>
                                              a.accountType.value == 1 ||
                                              a.accountType.value == 7,
                                        )
                                        .toList();

                                    return DropdownButtonFormField<String>(
                                      initialValue: _paymentAccountId,
                                      decoration: InputDecoration(
                                        labelText: l10n.paymentAccount,
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(
                                          Icons.account_balance,
                                        ),
                                      ),
                                      items: paymentAccounts
                                          .map(
                                            (a) => DropdownMenuItem<String>(
                                              value: a.id,
                                              child: Text(a.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _paymentAccountId = v),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _paymentMethod,
                              decoration: InputDecoration(
                                labelText: l10n.paymentMethod,
                                border: const OutlineInputBorder(),
                              ),
                              items:
                                  [
                                        'Cash',
                                        'Check',
                                        'Credit Card',
                                        'Bank Transfer',
                                      ]
                                      .map(
                                        (m) => DropdownMenuItem<String>(
                                          value: m,
                                          child: Text(m),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) =>
                                  setState(() => _paymentMethod = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _loadingBills
                      ? const Center(child: CircularProgressIndicator())
                      : _openBills.isEmpty
                      ? Center(
                          child: Text(
                            _selectedVendor == null
                                ? l10n.selectVendorHint
                                : l10n.noRecentTransactions,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: _openBills.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final bill = _openBills[i];
                            final isSelected = _selectedBillIds.contains(
                              bill.id,
                            );

                            return Card(
                              elevation: isSelected ? 4 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSelected
                                      ? cs.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: CheckboxListTile(
                                value: isSelected,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedBillIds.add(bill.id);
                                    } else {
                                      _selectedBillIds.remove(bill.id);
                                    }
                                  });
                                },
                                title: Text(
                                  '${bill.billNumber} — ${bill.billDate.day}/${bill.billDate.month}/${bill.billDate.year}',
                                ),
                                subtitle: Text(
                                  '${l10n.total}: ${bill.totalAmount.toStringAsFixed(2)} • ${l10n.amountDue}: ${bill.balanceDue.toStringAsFixed(2)}',
                                ),
                                secondary: SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: _amountControllers[bill.id],
                                    enabled: isSelected,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      labelText: l10n.amountPaid,
                                      isDense: true,
                                      suffixText: l10n.egp,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          TransactionSidebar(vendorId: _selectedVendor?.id),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.totalPayment, style: theme.textTheme.labelSmall),
                Text(
                  '${_calculateTotal().toStringAsFixed(2)} ${l10n.egp}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/purchases/bills');
                    }
                  },
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payments_outlined),
                  label: Text(l10n.payBills),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(140, 48),
                  ),
                ),
              ],
            ),
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

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text('${value.day}/${value.month}/${value.year}'),
      ),
    );
  }
}

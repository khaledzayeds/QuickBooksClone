// sales_receipt_form_page_redesign.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_enums.dart';
import '../../../core/widgets/transaction_line_table.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../invoices/data/models/sales_preview_contracts.dart';
import '../../invoices/providers/invoices_state.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_context_sidebar.dart';
import '../../transactions/widgets/transaction_models.dart';
import '../../transactions/widgets/transaction_totals_footer.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../providers/sales_receipts_state.dart';

class SalesReceiptFormPageRedesign extends ConsumerStatefulWidget {
  const SalesReceiptFormPageRedesign({super.key});

  @override
  ConsumerState<SalesReceiptFormPageRedesign> createState() => _SalesReceiptFormPageRedesignState();
}

class _SalesReceiptFormPageRedesignState extends ConsumerState<SalesReceiptFormPageRedesign> {
  CustomerModel? _customer;
  CustomerSalesActivityModel? _activity;
  SalesPostingPreviewModel? _preview;
  AccountModel? _depositAccount;
  DateTime _receiptDate = DateTime.now();
  String _paymentMethod = 'Cash';
  bool _saving = false;
  bool _previewing = false;
  bool _loadingActivity = false;
  Timer? _previewDebounce;

  final _numberCtrl = TextEditingController(text: 'AUTO');
  final _dateCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _lines = <TransactionLineEntry>[TransactionLineEntry()];

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = _date(_receiptDate);
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _numberCtrl.dispose();
    _dateCtrl.dispose();
    _referenceCtrl.dispose();
    _customerCtrl.dispose();
    _depositCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double get _localSubtotal => _lines.fold(0, (sum, line) => sum + line.amount);

  TransactionTotalsUiModel get _totals => TransactionTotalsUiModel(
        subtotal: _preview?.subtotal ?? _localSubtotal,
        discountTotal: _preview?.discountTotal ?? 0,
        taxTotal: _preview?.taxTotal ?? 0,
        total: _preview?.total ?? _localSubtotal,
        paid: _preview?.paidAmount ?? _localSubtotal,
        balanceDue: _preview?.balanceDue ?? 0,
        currency: _activity?.currency ?? _customer?.currency ?? 'EGP',
      );

  List<TransactionLineEntry> _validLines() => _lines.where((line) => line.itemId != null && line.qty > 0 && line.rate >= 0).toList();

  List<TransactionContextMetric> get _metrics {
    final currency = _activity?.currency ?? _customer?.currency ?? 'EGP';
    return [
      if (_customer != null)
        TransactionContextMetric(
          label: 'Open balance',
          value: '${(_activity?.openBalance ?? _customer!.balance).toStringAsFixed(2)} $currency',
          icon: Icons.account_balance_wallet_outlined,
        ),
      if (_customer != null)
        TransactionContextMetric(
          label: 'Credits',
          value: '${(_activity?.creditBalance ?? _customer!.creditBalance).toStringAsFixed(2)} $currency',
          icon: Icons.credit_score_outlined,
        ),
      TransactionContextMetric(
        label: 'Receipt total',
        value: '${_totals.total.toStringAsFixed(2)} $currency',
        icon: Icons.receipt_long_outlined,
      ),
      if (_preview != null)
        TransactionContextMetric(
          label: 'Tax',
          value: '${_preview!.taxTotal.toStringAsFixed(2)} $currency',
          icon: Icons.percent_outlined,
        ),
    ];
  }

  List<TransactionContextActivity> get _activities {
    final activity = _activity;
    if (activity == null) return const [];
    return [
      ...activity.recentSalesReceipts.map(
        (x) => TransactionContextActivity(
          title: 'Receipt ${x.number}',
          subtitle: _date(x.date),
          amount: '${x.totalAmount.toStringAsFixed(2)} ${activity.currency}',
          status: 'Receipt',
        ),
      ),
      ...activity.recentInvoices.map(
        (x) => TransactionContextActivity(
          title: 'Invoice ${x.number}',
          subtitle: _date(x.date),
          amount: '${x.balanceDue.toStringAsFixed(2)} ${activity.currency}',
          status: 'Invoice',
        ),
      ),
      ...activity.recentPayments.map(
        (x) => TransactionContextActivity(
          title: 'Payment ${x.number}',
          subtitle: '${_date(x.paymentDate)} • ${x.paymentMethod}',
          amount: '${x.amount.toStringAsFixed(2)} ${activity.currency}',
          status: 'Payment',
        ),
      ),
    ];
  }

  String? get _warning {
    if (_customer == null) return null;
    final warnings = <String>[...?_activity?.warnings, ...?_preview?.warnings];
    if (_depositAccount == null) warnings.add('Select a deposit account.');
    return warnings.isEmpty ? null : warnings.join('\n');
  }

  Future<void> _loadCustomerActivity(String id) async {
    setState(() => _loadingActivity = true);
    final result = await ref.read(invoicesRepoProvider).getCustomerActivity(id, limit: 5);
    if (!mounted) return;
    setState(() => _loadingActivity = false);
    result.when(success: (data) => setState(() => _activity = data), failure: (error) => _showError(error.message));
  }

  Future<void> _runPreview() async {
    if (_customer == null || _depositAccount == null || _validLines().isEmpty) return;
    setState(() => _previewing = true);
    final dto = PreviewSalesReceiptDto(
      customerId: _customer!.id,
      receiptDate: _receiptDate,
      depositAccountId: _depositAccount!.id,
      paymentMethod: _paymentMethod,
      lines: _validLines()
          .map((line) => PreviewSalesLineDto(
                itemId: line.itemId!,
                description: line.descCtrl.text.trim().isEmpty ? line.itemName : line.descCtrl.text.trim(),
                quantity: line.qty,
                unitPrice: line.rate,
              ))
          .toList(),
    );
    final result = await ref.read(salesReceiptsRepoProvider).preview(dto);
    if (!mounted) return;
    setState(() => _previewing = false);
    result.when(success: (data) => setState(() => _preview = data), failure: (error) => _showError(error.message));
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 550), _runPreview);
  }

  Future<void> _save({required bool closeAfterSave}) async {
    if (_customer == null) return _showError('Select a customer.');
    if (_depositAccount == null) return _showError('Select a deposit account.');
    final validLines = _validLines();
    if (validLines.isEmpty) return _showError('Add at least one valid line.');

    setState(() => _saving = true);
    final dto = CreateSalesReceiptDto(
      customerId: _customer!.id,
      receiptDate: _receiptDate,
      depositAccountId: _depositAccount!.id,
      paymentMethod: _paymentMethod,
      lines: validLines
          .map((line) => CreateSalesReceiptLineDto(
                itemId: line.itemId!,
                description: line.descCtrl.text.trim().isEmpty ? line.itemName : line.descCtrl.text.trim(),
                quantity: line.qty,
                unitPrice: line.rate,
              ))
          .toList(),
    );
    try {
      final result = await ref.read(salesReceiptsRepoProvider).create(dto);
      result.when(
        success: (_) {
          ref.read(salesReceiptsStateProvider.notifier).refresh();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sales receipt created.')));
          if (closeAfterSave) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/sales/receipts');
            }
          } else {
            _reset();
          }
        },
        failure: (error) => _showError(error.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reset() {
    setState(() {
      _customer = null;
      _activity = null;
      _preview = null;
      _depositAccount = null;
      _receiptDate = DateTime.now();
      _paymentMethod = 'Cash';
      _numberCtrl.text = 'AUTO';
      _dateCtrl.text = _date(_receiptDate);
      _referenceCtrl.clear();
      _customerCtrl.clear();
      _depositCtrl.clear();
      for (final line in _lines) {
        line.dispose();
      }
      _lines
        ..clear()
        ..add(TransactionLineEntry());
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _receiptDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (picked == null) return;
    setState(() {
      _receiptDate = picked;
      _dateCtrl.text = _date(picked);
      _preview = null;
    });
    _schedulePreview();
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error));

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/sales/receipts');
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider).maybeWhen(data: (items) => items.where((x) => x.isActive).toList(), orElse: () => const <CustomerModel>[]);
    final accounts = ref.watch(accountsProvider).maybeWhen(
          data: (items) => items.where((x) => x.isActive && (x.accountType == AccountType.bank || x.accountType == AccountType.otherCurrentAsset)).toList(),
          orElse: () => const <AccountModel>[],
        );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(children: [
          IconButton(onPressed: _goBack, icon: const Icon(Icons.arrow_back)),
          const SizedBox(width: 8),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('New Sales Receipt', style: TextStyle(fontWeight: FontWeight.w900)),
            Text('Sales / Receipts / New', style: TextStyle(fontSize: 12)),
          ]),
        ]),
        actions: [
          OutlinedButton.icon(onPressed: _saving ? null : () => _save(closeAfterSave: false), icon: const Icon(Icons.add_circle_outline), label: const Text('Save & New')),
          const SizedBox(width: 8),
          FilledButton.icon(onPressed: _saving ? null : () => _save(closeAfterSave: true), icon: _saving ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: const Text('Save & Close')),
          const SizedBox(width: 12),
          IconButton(onPressed: _goBack, icon: const Icon(Icons.close)),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 1120;
        return Row(children: [
          Expanded(child: _buildMainArea(context, customers, accounts)),
          if (showSidebar)
            TransactionContextSidebar(
              title: _customer?.displayName ?? '',
              subtitle: _customer?.companyName ?? _customer?.primaryContact,
              initials: _customer?.initials,
              emptyTitle: 'Select a customer',
              emptyMessage: 'Choose a customer to see balances, credits, recent activity, and receipt totals.',
              metrics: _metrics,
              activities: _activities,
              warning: _warning,
              isLoading: _loadingActivity,
              totals: _totals,
              notes: _referenceCtrl.text.trim().isEmpty ? null : 'Reference: ${_referenceCtrl.text.trim()}',
            ),
        ]);
      }),
    );
  }

  Widget _buildMainArea(BuildContext context, List<CustomerModel> customers, List<AccountModel> accounts) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: cs.outlineVariant)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                Row(children: [
                  Expanded(child: _ReadOnlyField(controller: _numberCtrl, label: 'Receipt #')),
                  const SizedBox(width: 12),
                  Expanded(child: _ReadOnlyField(controller: _dateCtrl, label: 'Date', icon: Icons.calendar_today_outlined, onTap: _pickDate)),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: TextField(controller: _referenceCtrl, decoration: const InputDecoration(labelText: 'Reference', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(flex: 2, child: _customerField(customers)),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _accountField(accounts)),
                  const SizedBox(width: 12),
                  Expanded(child: _paymentMethodField()),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Products and services', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              Text('Backend preview recalculates totals automatically.', style: TextStyle(fontSize: 12)),
            ]),
            const Spacer(),
            if (_previewing) const Padding(padding: EdgeInsets.only(right: 8), child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            FilledButton.tonalIcon(onPressed: _addLine, icon: const Icon(Icons.add), label: const Text('Add line')),
          ]),
          const SizedBox(height: 10),
          Expanded(
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: cs.outlineVariant)),
              child: Column(children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: TransactionLineTable(lines: _lines, priceMode: TransactionLinePriceMode.sales, onChanged: () {
                        setState(() => _preview = null);
                        _schedulePreview();
                      }),
                    ),
                  ),
                ),
                TransactionTotalsFooter(totals: _totals),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _addLine() {
    setState(() {
      _preview = null;
      _lines.add(TransactionLineEntry());
    });
    _schedulePreview();
  }

  Widget _customerField(List<CustomerModel> customers) => TypeAheadField<CustomerModel>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: _customerCtrl,
          decoration: InputDecoration(labelText: 'Customer', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.person_outline), suffixIcon: _customer == null ? const Icon(Icons.search) : IconButton(onPressed: () => setState(() { _customer = null; _customerCtrl.clear(); _activity = null; _preview = null; }), icon: const Icon(Icons.close))),
        ),
        suggestionsCallback: (pattern) {
          final text = pattern.toLowerCase().trim();
          return customers.where((c) => text.isEmpty || c.displayName.toLowerCase().contains(text) || (c.companyName?.toLowerCase().contains(text) ?? false) || (c.email?.toLowerCase().contains(text) ?? false)).take(12).toList();
        },
        itemBuilder: (context, c) => ListTile(leading: CircleAvatar(child: Text(c.initials)), title: Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(c.primaryContact), trailing: Text(c.balance.toStringAsFixed(2))),
        onSuggestionSelected: (c) {
          setState(() { _customer = c; _customerCtrl.text = c.displayName; _activity = null; _preview = null; });
          _loadCustomerActivity(c.id);
          _schedulePreview();
        },
        noItemsFoundBuilder: (_) => const Padding(padding: EdgeInsets.all(16), child: Text('No customers found.')),
      );

  Widget _accountField(List<AccountModel> accounts) => TypeAheadField<AccountModel>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: _depositCtrl,
          decoration: InputDecoration(labelText: 'Deposit Account', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.account_balance_outlined), suffixIcon: _depositAccount == null ? const Icon(Icons.search) : IconButton(onPressed: () => setState(() { _depositAccount = null; _depositCtrl.clear(); _preview = null; }), icon: const Icon(Icons.close))),
        ),
        suggestionsCallback: (pattern) {
          final text = pattern.toLowerCase().trim();
          return accounts.where((a) => text.isEmpty || a.name.toLowerCase().contains(text) || a.code.toLowerCase().contains(text)).take(12).toList();
        },
        itemBuilder: (context, a) => ListTile(leading: const Icon(Icons.account_balance_outlined), title: Text('${a.code} - ${a.name}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(a.accountType.name), trailing: Text(a.balance.toStringAsFixed(2))),
        onSuggestionSelected: (a) {
          setState(() { _depositAccount = a; _depositCtrl.text = '${a.code} - ${a.name}'; _preview = null; });
          _schedulePreview();
        },
        noItemsFoundBuilder: (_) => const Padding(padding: EdgeInsets.all(16), child: Text('No deposit accounts found.')),
      );

  Widget _paymentMethodField() => DropdownButtonFormField<String>(
        value: _paymentMethod,
        decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
          DropdownMenuItem(value: 'Check', child: Text('Check')),
          DropdownMenuItem(value: 'BankTransfer', child: Text('Bank Transfer')),
          DropdownMenuItem(value: 'CreditCard', child: Text('Credit Card')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() { _paymentMethod = value; _preview = null; });
          _schedulePreview();
        },
      );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.controller, required this.label, this.icon, this.onTap});
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => TextField(controller: controller, readOnly: true, onTap: onTap, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: icon == null ? null : Icon(icon)));
}

String _date(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

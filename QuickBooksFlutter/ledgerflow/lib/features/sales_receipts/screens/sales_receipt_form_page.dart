// sales_receipt_form_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/core/widgets/transaction_sidebar.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../core/constants/api_enums.dart';
import '../../../core/widgets/transaction_line_table.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../invoices/data/models/sales_preview_contracts.dart';
import '../../invoices/providers/invoices_state.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_models.dart';
import '../../transactions/widgets/transaction_totals_footer.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../providers/sales_receipts_state.dart';

class SalesReceiptFormPage extends ConsumerStatefulWidget {
  const SalesReceiptFormPage({super.key});

  @override
  ConsumerState<SalesReceiptFormPage> createState() =>
      _SalesReceiptFormPageState();
}

class _SalesReceiptFormPageState extends ConsumerState<SalesReceiptFormPage> {
  // Customer
  CustomerModel? _selectedCustomer;
  CustomerSalesActivityModel? _customerActivity;
  SalesPostingPreviewModel? _preview;
  AccountModel? _selectedDepositAccount;
  String? _depositAccountId;
  DateTime _receiptDate = DateTime.now();
  String _paymentMethod = 'Cash';
  bool _saving = false;
  bool _previewing = false;
  bool _loadingActivity = false;
  Timer? _lineChangeDebounce;
  Timer? _previewDebounce;
  int _previewRequestId = 0;
  String? _lastPreviewSignature;

  final _numberCtrl = TextEditingController(text: 'AUTO');
  final _dateCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _depositAccountCtrl = TextEditingController();
  final _paymentMethodCtrl = TextEditingController(text: 'Cash');

  final List<TransactionLineEntry> _lines = [TransactionLineEntry()];

  @override
  void initState() {
    super.initState();
    _syncDateController();
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _dateCtrl.dispose();
    _referenceCtrl.dispose();
    _customerCtrl.dispose();
    _depositAccountCtrl.dispose();
    _paymentMethodCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    _lineChangeDebounce?.cancel();
    _previewDebounce?.cancel();
    super.dispose();
  }

  double get _subtotal => _lines.fold(0, (sum, line) => sum + line.amount);

  TransactionTotalsUiModel get _totals => TransactionTotalsUiModel(
    subtotal: _preview?.subtotal ?? _subtotal,
    discountTotal: _preview?.discountTotal ?? 0,
    taxTotal: _preview?.taxTotal ?? 0,
    total: _preview?.total ?? _subtotal,
    paid: _preview?.paidAmount ?? _subtotal,
    balanceDue: _preview?.balanceDue ?? 0,
    currency:
        _customerActivity?.currency ?? _selectedCustomer?.currency ?? 'EGP',
  );

  List<TransactionContextMetric> get _sideMetrics {
    final currency =
        _customerActivity?.currency ?? _selectedCustomer?.currency ?? 'EGP';
    return [
      if (_selectedCustomer != null)
        TransactionContextMetric(
          label: 'Balance',
          value: (_customerActivity?.openBalance ?? _selectedCustomer!.balance)
              .toStringAsFixed(2),
          icon: Icons.account_balance_wallet_outlined,
        ),
      if (_selectedCustomer != null)
        TransactionContextMetric(
          label: 'Credits',
          value:
              (_customerActivity?.creditBalance ??
                      _selectedCustomer!.creditBalance)
                  .toStringAsFixed(2),
          icon: Icons.credit_score_outlined,
        ),
      TransactionContextMetric(
        label: 'Receipt Total',
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

  String? get _sideWarning {
    if (_selectedCustomer == null) return 'Select customer';
    final warnings = <String>[
      ...?_customerActivity?.warnings,
      ...?_preview?.warnings,
    ];
    if (_depositAccountId == null) warnings.add('No deposit account');
    return warnings.isEmpty ? null : warnings.join('\n');
  }

  void _syncDateController() {
    _dateCtrl.text = _formatDate(_receiptDate);
  }

  List<TransactionLineEntry> _validLines() => _lines
      .where((line) => line.itemId != null && line.qty > 0 && line.rate >= 0)
      .toList();

  Future<void> _loadCustomerActivity(String customerId) async {
    setState(() => _loadingActivity = true);
    final result = await ref
        .read(invoicesRepoProvider)
        .getCustomerActivity(customerId, limit: 5);
    if (!mounted) return;
    setState(() => _loadingActivity = false);
    result.when(
      success: (activity) => setState(() => _customerActivity = activity),
      failure: (error) => _showError(error.message),
    );
  }

  Future<void> _runPreview() async {
    final validLines = _validLines();
    if (_selectedCustomer == null || _depositAccountId == null || validLines.isEmpty) {
      if (_previewing) {
        setState(() => _previewing = false);
      }
      return;
    }

    final signature = _previewSignature(validLines);
    if (_preview != null && signature == _lastPreviewSignature) {
      return;
    }

    final requestId = ++_previewRequestId;
    if (!_previewing) {
      setState(() => _previewing = true);
    }

    final dto = PreviewSalesReceiptDto(
      customerId: _selectedCustomer!.id,
      receiptDate: _receiptDate,
      depositAccountId: _depositAccountId!,
      paymentMethod: _paymentMethod,
      lines: validLines
          .map(
            (line) => PreviewSalesLineDto(
              itemId: line.itemId!,
              description: line.descCtrl.text.trim().isEmpty
                  ? line.itemName
                  : line.descCtrl.text.trim(),
              quantity: line.qty,
              unitPrice: line.rate,
            ),
          )
          .toList(),
    );
    final result = await ref.read(salesReceiptsRepoProvider).preview(dto);
    if (!mounted) return;
    if (requestId != _previewRequestId) return;

    setState(() => _previewing = false);
    result.when(
      success: (preview) => setState(() {
        _preview = preview;
        _lastPreviewSignature = signature;
      }),
      failure: (error) => _showError(error.message),
    );
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 900), () {
      _runPreview();
    });
  }

  void _invalidatePreview() {
    _previewRequestId++;
    _lastPreviewSignature = null;
    _preview = null;
    _previewing = false;
  }

  String _previewSignature(List<TransactionLineEntry> validLines) {
    final lineSignature = validLines.map((line) {
      final description = line.descCtrl.text.trim().isEmpty
          ? line.itemName
          : line.descCtrl.text.trim();
      return '${line.itemId}|$description|${line.qty}|${line.rate}';
    }).join(';');

    return '${_selectedCustomer?.id}|$_depositAccountId|${_formatDate(_receiptDate)}|$_paymentMethod|$lineSignature';
  }

  Future<void> _save({bool closeAfterSave = true}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedCustomer == null) {
      _showError(l10n.selectCustomer);
      return;
    }
    if (_depositAccountId == null || _depositAccountId!.isEmpty) {
      _showError(l10n.selectDepositAccount);
      return;
    }
    final validLines = _validLines();
    if (validLines.isEmpty) {
      _showError(l10n.minOneQty);
      return;
    }
    final dto = CreateSalesReceiptDto(
      customerId: _selectedCustomer!.id,
      receiptDate: _receiptDate,
      depositAccountId: _depositAccountId!,
      paymentMethod: _paymentMethod,
      lines: validLines
          .map(
            (line) => CreateSalesReceiptLineDto(
              itemId: line.itemId!,
              description: line.descCtrl.text.trim().isEmpty
                  ? line.itemName
                  : line.descCtrl.text.trim(),
              quantity: line.qty,
              unitPrice: line.rate,
            ),
          )
          .toList(),
    );
    setState(() => _saving = true);
    try {
      final result = await ref.read(salesReceiptsRepoProvider).create(dto);
      result.when(
        success: (_) {
          ref.read(salesReceiptsStateProvider.notifier).refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.salesReceiptCreatedSuccess)),
          );
          if (closeAfterSave) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/sales/receipts');
            }
          } else {
            setState(() {
              _clearForm();
            });
          }
        },
        failure: (error) => _showError(error.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearForm() {
    _selectedCustomer = null;
    _customerActivity = null;
    _preview = null;
    _selectedDepositAccount = null;
    _depositAccountId = null;
    _receiptDate = DateTime.now();
    _paymentMethod = 'Cash';
    _customerCtrl.clear();
    _depositAccountCtrl.clear();
    _paymentMethodCtrl.text = 'Cash';
    for (final l in _lines) {
      l.dispose();
    }
    _lines
      ..clear()
      ..add(TransactionLineEntry());
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );

  Future<void> _pickReceiptDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receiptDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      _receiptDate = picked;
      _invalidatePreview();
      _syncDateController();
      _schedulePreview();
    });
  }

  // ignore: unused_element
  Future<void> _selectCustomer() async {
    final customersAsync = ref.read(customersProvider);
    final customers = customersAsync.maybeWhen(
      data: (items) => items.where((customer) => customer.isActive).toList(),
      orElse: () => const <CustomerModel>[],
    );
    final selected = await showDialog<CustomerModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Customer'),
        content: SizedBox(
          width: 520,
          child: customers.isEmpty
              ? const Text('No active customers loaded yet.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(customer.displayName),
                      subtitle: Text(
                        'Balance: ${customer.balance.toStringAsFixed(2)} ${customer.currency} • Credits: ${customer.creditBalance.toStringAsFixed(2)}',
                      ),
                      onTap: () => Navigator.of(context).pop(customer),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (selected == null) return;
    setState(() {
      _selectedCustomer = selected;
      _customerActivity = null;
      _invalidatePreview();
      _customerCtrl.text = selected.displayName;
    });
    _loadCustomerActivity(selected.id);
    _schedulePreview();
  }

  // ignore: unused_element
  Future<void> _selectDepositAccount() async {
    final accountsAsync = ref.read(accountsProvider);
    final accounts = accountsAsync.maybeWhen(
      data: (items) => items
          .where(
            (account) =>
                account.isActive &&
                (account.accountType == AccountType.bank ||
                    account.accountType == AccountType.otherCurrentAsset),
          )
          .toList(),
      orElse: () => const <AccountModel>[],
    );
    final selected = await showDialog<AccountModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Deposit Account'),
        content: SizedBox(
          width: 520,
          child: accounts.isEmpty
              ? const Text('No active bank/current asset accounts loaded yet.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return ListTile(
                      leading: const Icon(Icons.account_balance_outlined),
                      title: Text('${account.code} - ${account.name}'),
                      subtitle: Text(account.accountType.name),
                      onTap: () => Navigator.of(context).pop(account),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (selected == null) return;
    setState(() {
      _selectedDepositAccount = selected;
      _depositAccountId = selected.id;
      _depositAccountCtrl.text = '${selected.code} - ${selected.name}';
      _invalidatePreview();
    });
    _schedulePreview();
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _customerActivity = null;
      _invalidatePreview();
      _customerCtrl.clear();
    });
  }

  void _clearDepositAccount() {
    setState(() {
      _selectedDepositAccount = null;
      _depositAccountId = null;
      _depositAccountCtrl.clear();
      _invalidatePreview();
    });
  }

  void _selectCustomerDirect(CustomerModel customer) {
    setState(() {
      _selectedCustomer = customer;
      _customerActivity = null;
      _invalidatePreview();
      _customerCtrl.text = customer.displayName;
    });
    _loadCustomerActivity(customer.id);
    _schedulePreview();
  }

  void _selectDepositAccountDirect(AccountModel account) {
    setState(() {
      _selectedDepositAccount = account;
      _depositAccountId = account.id;
      _depositAccountCtrl.text = '${account.code} - ${account.name}';
      _invalidatePreview();
    });
    _schedulePreview();
  }

  void _addLine() {
    setState(() {
      _invalidatePreview();
      _lines.add(TransactionLineEntry());
    });
    _schedulePreview();
  }

  // ignore: unused_element
  void _clearLines() {
    if (_lines.length == 1 && _lines.first.itemId == null) return;
    setState(() {
      for (final line in _lines) {
        line.dispose();
      }
      _lines
        ..clear()
        ..add(TransactionLineEntry());
      _invalidatePreview();
    });
  }

  void _onTableChanged() {
    _lineChangeDebounce?.cancel();
    _lineChangeDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(_invalidatePreview);
      _schedulePreview();
    });
  }

  Future<void> _showCustomerContextDialog() async {
    if (_selectedCustomer == null) return;
    final activity = _customerActivity;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_selectedCustomer!.displayName),
        content: SizedBox(
          width: 400,
          child: activity == null
              ? const Text('Loading...')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    ...activity.recentSalesReceipts.map(
                      (x) => ListTile(
                        title: Text('Receipt ${x.number}'),
                        subtitle: Text(_formatDate(x.date)),
                        trailing: Text(
                          '${x.totalAmount.toStringAsFixed(2)} ${activity.currency}',
                        ),
                      ),
                    ),
                    ...activity.recentInvoices.map(
                      (x) => ListTile(
                        title: Text('Invoice ${x.number}'),
                        subtitle: Text(_formatDate(x.date)),
                        trailing: Text(
                          '${x.balanceDue.toStringAsFixed(2)} ${activity.currency}',
                        ),
                      ),
                    ),
                    ...activity.recentPayments.map(
                      (x) => ListTile(
                        title: Text('Payment ${x.number}'),
                        subtitle: Text(
                          '${_formatDate(x.paymentDate)} • ${x.paymentMethod}',
                        ),
                        trailing: Text(
                          '${x.amount.toStringAsFixed(2)} ${activity.currency}',
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/sales/receipts');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final customers = ref
        .watch(customersProvider)
        .maybeWhen(
          data: (items) =>
              items.where((customer) => customer.isActive).toList(),
          orElse: () => const <CustomerModel>[],
        );
    final depositAccounts = ref
        .watch(accountsProvider)
        .maybeWhen(
          data: (items) => items
              .where(
                (account) =>
                    account.isActive &&
                    (account.accountType == AccountType.bank ||
                        account.accountType == AccountType.otherCurrentAsset),
              )
              .toList(),
          orElse: () => const <AccountModel>[],
        );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 42,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 8,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _saving ? null : () => _save(closeAfterSave: true),
                icon: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 18),
                label: const Text(
                  'Save & Close',
                  style: TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _saving ? null : () => _save(closeAfterSave: false),
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save & New', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _cancel,
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Close',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // ---- Unified Header Card ----
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Row 1: Receipt #, Date, Reference
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth > 500;
                                return wide
                                    ? Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              controller: _numberCtrl,
                                              readOnly: true,
                                              decoration: const InputDecoration(
                                                labelText: 'Receipt #',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              controller: _dateCtrl,
                                              readOnly: true,
                                              onTap: _pickReceiptDate,
                                              decoration: const InputDecoration(
                                                labelText: 'Date',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                                suffixIcon: Icon(
                                                  Icons.calendar_today_outlined,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: TextField(
                                              controller: _referenceCtrl,
                                              decoration: const InputDecoration(
                                                labelText: 'Reference',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          TextField(
                                            controller: _numberCtrl,
                                            readOnly: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Receipt #',
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _dateCtrl,
                                            readOnly: true,
                                            onTap: _pickReceiptDate,
                                            decoration: const InputDecoration(
                                              labelText: 'Date',
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                              suffixIcon: Icon(
                                                Icons.calendar_today_outlined,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _referenceCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Reference',
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ],
                                      );
                              },
                            ),
                            const SizedBox(height: 10),
                            // Row 2: Customer
                            Row(
                              children: [
                                Expanded(
                                  child: _CustomerTypeAheadField(
                                    controller: _customerCtrl,
                                    customers: customers,
                                    label: l10n.customer,
                                    selectedCustomer: _selectedCustomer,
                                    onSelected: _selectCustomerDirect,
                                    onClear: _clearCustomer,
                                    onDetails: _showCustomerContextDialog,
                                  ),
                                ),
                                if (_selectedCustomer != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'Balance: ${(_customerActivity?.openBalance ?? _selectedCustomer!.balance).toStringAsFixed(2)} ${_selectedCustomer!.currency}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Row 3: Deposit & Payment Method
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth > 500;
                                return wide
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: _DepositAccountTypeAheadField(
                                              controller: _depositAccountCtrl,
                                              accounts: depositAccounts,
                                              selectedAccount:
                                                  _selectedDepositAccount,
                                              onSelected:
                                                  _selectDepositAccountDirect,
                                              onClear: _clearDepositAccount,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                                  value: _paymentMethod,
                                                  isDense: true,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Payment Method',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: 'Cash',
                                                      child: Text('Cash'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'Check',
                                                      child: Text('Check'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'BankTransfer',
                                                      child: Text(
                                                        'Bank Transfer',
                                                      ),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'CreditCard',
                                                      child: Text(
                                                        'Credit Card',
                                                      ),
                                                    ),
                                                  ],
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      setState(() {
                                                        _paymentMethod = value;
                                                        _invalidatePreview();
                                                      });
                                                      _schedulePreview();
                                                    }
                                                  },
                                                ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _DepositAccountTypeAheadField(
                                            controller: _depositAccountCtrl,
                                            accounts: depositAccounts,
                                            selectedAccount:
                                                _selectedDepositAccount,
                                            onSelected:
                                                _selectDepositAccountDirect,
                                            onClear: _clearDepositAccount,
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<String>(
                                            value: _paymentMethod,
                                            isDense: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Payment Method',
                                              border: OutlineInputBorder(),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Cash',
                                                child: Text('Cash'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Check',
                                                child: Text('Check'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'BankTransfer',
                                                child: Text('Bank Transfer'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'CreditCard',
                                                child: Text('Credit Card'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(() {
                                                  _paymentMethod = value;
                                                  _invalidatePreview();
                                                });
                                                _schedulePreview();
                                              }
                                            },
                                          ),
                                        ],
                                      );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Items Header + Add Line
                    Row(
                      children: [
                        Text(
                          l10n.items,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(label: Text('${_lines.length} lines')),
                        if (_previewing) ...[
                          const SizedBox(width: 8),
                          const Chip(
                            label: Text('Previewing'),
                            avatar: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ] else if (_preview != null) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: const Text('Preview ready'),
                            avatar: Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: cs.primary,
                            ),
                          ),
                        ],
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addLine,
                          icon: const Icon(Icons.add),
                          label: const Text('Add line'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Scrollable Items Table + Totals
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: cs.outlineVariant),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 800,
                                    ),
                                    child: TransactionLineTable(
                                      lines: _lines,
                                      priceMode: TransactionLinePriceMode.sales,
                                      onChanged: _onTableChanged,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Footer
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right Sidebar
            _buildRightSidebar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return TransactionTotalsFooter(totals: _totals);
  }

  Widget _buildRightSidebar() {
    return TransactionSidebar();
  }

  Widget _buildRedDot() {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(left: 4, bottom: 4),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildRibbon() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ribbon Tabs
          Container(
            color: const Color(0xFFE5E5E5),
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _buildRibbonTab('Main', isActive: true),
                _buildRibbonTab('Formatting', hasRedDot: true),
                _buildRibbonTab('Reports', hasRedDot: true),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.black54,
                  ),
                  onPressed: _cancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          // Ribbon Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFCCCCCC))),
            ),
            child: Row(
              children: [
                _buildRibbonButton(
                  Icons.note_add,
                  'New',
                  onPressed: () => _save(closeAfterSave: false),
                ),
                _buildRibbonButton(
                  Icons.save,
                  'Save',
                  onPressed: () => _save(closeAfterSave: true),
                ),
                _buildRibbonButton(
                  Icons.delete_forever,
                  'Delete',
                  hasRedDot: true,
                ),
                _buildRibbonButton(
                  Icons.copy,
                  'Create a Copy',
                  hasRedDot: true,
                ),
                const SizedBox(width: 16),
                _buildRibbonButton(Icons.print, 'Print', hasRedDot: true),
                _buildRibbonButton(Icons.email, 'Email', hasRedDot: true),
                const SizedBox(width: 16),
                _buildRibbonButton(
                  Icons.attach_file,
                  'Attach\nFile',
                  hasRedDot: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRibbonTab(
    String text, {
    bool isActive = false,
    bool hasRedDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF0F0F0) : Colors.transparent,
        border: isActive
            ? const Border(
                top: BorderSide(color: Color(0xFFCCCCCC)),
                left: BorderSide(color: Color(0xFFCCCCCC)),
                right: BorderSide(color: Color(0xFFCCCCCC)),
              )
            : null,
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.black : Colors.black87,
            ),
          ),
          if (hasRedDot) _buildRedDot(),
        ],
      ),
    );
  }

  Widget _buildRibbonButton(
    IconData icon,
    String label, {
    bool isBlue = false,
    VoidCallback? onPressed,
    bool hasRedDot = false,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isBlue ? Colors.blue.shade700 : Colors.blue.shade600,
                ),
                if (hasRedDot) _buildRedDot(),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueBar(
    List<CustomerModel> customers,
    List<AccountModel> depositAccounts,
  ) {
    return Container(
      color: const Color(0xFF5B7B9E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Text(
            'CUSTOMER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Container(
              height: 32,
              constraints: const BoxConstraints(maxWidth: 250),
              child: Material(
                color: Colors.white,
                child: _CustomerTypeAheadField(
                  controller: _customerCtrl,
                  customers: customers,
                  label: '',
                  selectedCustomer: _selectedCustomer,
                  onSelected: _selectCustomerDirect,
                  onClear: _clearCustomer,
                  onDetails: _showCustomerContextDialog,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          const Text(
            'DEPOSIT TO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Container(
              height: 32,
              constraints: const BoxConstraints(maxWidth: 250),
              child: Material(
                color: Colors.white,
                child: _DepositAccountTypeAheadField(
                  controller: _depositAccountCtrl,
                  accounts: depositAccounts,
                  selectedAccount: _selectedDepositAccount,
                  onSelected: _selectDepositAccountDirect,
                  onClear: _clearDepositAccount,
                ),
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'TEMPLATE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildRedDot(),
          const SizedBox(width: 8),
          Flexible(
            flex: 1,
            child: Container(
              height: 28,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              child: const Text(
                'Custom Sales...',
                style: TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          const Text(
            'Sales Receipt',
            style: TextStyle(fontSize: 32, color: Color(0xFF4A4A4A)),
          ),
          // Fields
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Date & NO
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DATE',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 26,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: InkWell(
                      onTap: _pickReceiptDate,
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                _dateCtrl.text,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          Container(
                            color: Colors.grey.shade200,
                            width: 20,
                            child: const Icon(Icons.calendar_today, size: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SALE NO.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 26,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    padding: const EdgeInsets.only(left: 4),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _numberCtrl.text,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Column 2: Payment Method
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PAYMENT METH',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 150,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _paymentMethod,
                        isExpanded: true,
                        icon: Container(
                          width: 20,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.arrow_drop_down, size: 16),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Cash',
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                'Cash',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Check',
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                'Check',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'BankTransfer',
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                'Bank Transfer',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'CreditCard',
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                'Credit Card',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _paymentMethod = val;
                              _preview = null;
                            });
                            _schedulePreview();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'CHECK NO.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildRedDot(),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Customer TypeAhead Field
// ─────────────────────────────────────────────
class _CustomerTypeAheadField extends StatelessWidget {
  const _CustomerTypeAheadField({
    required this.controller,
    required this.customers,
    required this.label,
    required this.selectedCustomer,
    required this.onSelected,
    required this.onClear,
    required this.onDetails,
  });

  final TextEditingController controller;
  final List<CustomerModel> customers;
  final String label;
  final CustomerModel? selectedCustomer;
  final ValueChanged<CustomerModel> onSelected;
  final VoidCallback onClear;
  final VoidCallback onDetails;

  List<CustomerModel> _matches(String pattern) {
    final text = pattern.trim().toLowerCase();
    if (text.isEmpty) return customers.take(8).toList();
    return customers
        .where(
          (customer) =>
              customer.displayName.toLowerCase().contains(text) ||
              (customer.companyName?.toLowerCase().contains(text) ?? false) ||
              (customer.phone?.toLowerCase().contains(text) ?? false) ||
              (customer.email?.toLowerCase().contains(text) ?? false),
        )
        .take(12)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<CustomerModel>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          prefixIcon: const Icon(Icons.person_outline, size: 18),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedCustomer != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                  tooltip: 'Clear',
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.info_outline, size: 18),
                onPressed: selectedCustomer == null ? null : onDetails,
                tooltip: 'Customer details',
              ),
            ],
          ),
        ),
      ),
      suggestionsCallback: _matches,
      itemBuilder: (context, customer) {
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 14,
            child: Text(
              customer.initials,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          title: Text(
            customer.displayName,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${customer.primaryContact} | Balance ${customer.balance.toStringAsFixed(2)} ${customer.currency}',
          ),
          trailing: customer.creditBalance == 0
              ? null
              : Text(customer.creditBalance.toStringAsFixed(2)),
        );
      },
      onSuggestionSelected: (customer) {
        controller.text = customer.displayName;
        onSelected(customer);
      },
      noItemsFoundBuilder: (_) => const Padding(
        padding: EdgeInsets.all(10),
        child: Text('No matching customers'),
      ),
      suggestionsBoxDecoration: const SuggestionsBoxDecoration(
        elevation: 4,
        constraints: BoxConstraints(maxHeight: 300),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Deposit Account TypeAhead Field
// ─────────────────────────────────────────────
class _DepositAccountTypeAheadField extends StatelessWidget {
  const _DepositAccountTypeAheadField({
    required this.controller,
    required this.accounts,
    required this.selectedAccount,
    required this.onSelected,
    required this.onClear,
  });

  final TextEditingController controller;
  final List<AccountModel> accounts;
  final AccountModel? selectedAccount;
  final ValueChanged<AccountModel> onSelected;
  final VoidCallback onClear;

  List<AccountModel> _matches(String pattern) {
    final text = pattern.trim().toLowerCase();
    if (text.isEmpty) return accounts.take(8).toList();
    return accounts
        .where(
          (account) =>
              account.code.toLowerCase().contains(text) ||
              account.name.toLowerCase().contains(text) ||
              account.accountTypeName.toLowerCase().contains(text),
        )
        .take(12)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<AccountModel>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: 'Deposit Account',
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          prefixIcon: const Icon(Icons.account_balance_outlined, size: 18),
          suffixIcon: selectedAccount == null
              ? null
              : IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                  tooltip: 'Clear',
                ),
        ),
      ),
      suggestionsCallback: _matches,
      itemBuilder: (context, account) {
        return ListTile(
          dense: true,
          leading: const Icon(Icons.account_balance_outlined, size: 18),
          title: Text(
            '${account.code} - ${account.name}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${account.accountTypeName} | ${account.balance.toStringAsFixed(2)}',
          ),
        );
      },
      onSuggestionSelected: (account) {
        controller.text = '${account.code} - ${account.name}';
        onSelected(account);
      },
      noItemsFoundBuilder: (_) => const Padding(
        padding: EdgeInsets.all(10),
        child: Text('No matching deposit accounts'),
      ),
      suggestionsBoxDecoration: const SuggestionsBoxDecoration(
        elevation: 4,
        constraints: BoxConstraints(maxHeight: 300),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

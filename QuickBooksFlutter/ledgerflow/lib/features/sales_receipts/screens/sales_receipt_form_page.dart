// sales_receipt_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../core/constants/api_enums.dart';
import '../../../core/widgets/transaction_line_table.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_action_bar.dart';
import '../../transactions/widgets/transaction_context_side_panel.dart';
import '../../transactions/widgets/transaction_header_panel.dart';
import '../../transactions/widgets/transaction_keyboard_shortcuts.dart';
import '../../transactions/widgets/transaction_models.dart';
import '../../transactions/widgets/transaction_party_selector.dart';
import '../../transactions/widgets/transaction_totals_footer.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../providers/sales_receipts_state.dart';

class SalesReceiptFormPage extends ConsumerStatefulWidget {
  const SalesReceiptFormPage({super.key});

  @override
  ConsumerState<SalesReceiptFormPage> createState() => _SalesReceiptFormPageState();
}

class _SalesReceiptFormPageState extends ConsumerState<SalesReceiptFormPage> {
  CustomerModel? _selectedCustomer;
  AccountModel? _selectedDepositAccount;
  String? _depositAccountId;
  DateTime _receiptDate = DateTime.now();
  String _paymentMethod = 'Cash';
  bool _saving = false;
  bool _sidePanelExpanded = true;

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
    super.dispose();
  }

  double get _subtotal => _lines.fold(0, (sum, line) => sum + line.amount);

  TransactionTotalsUiModel get _totals => TransactionTotalsUiModel(
        subtotal: _subtotal,
        total: _subtotal,
        paid: _subtotal,
        balanceDue: 0,
        currency: _selectedCustomer?.currency ?? 'EGP',
      );

  void _syncDateController() {
    _dateCtrl.text = _formatDate(_receiptDate);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedCustomer == null) {
      _showError(l10n.selectCustomer);
      return;
    }
    if (_depositAccountId == null || _depositAccountId!.isEmpty) {
      _showError(l10n.selectDepositAccount);
      return;
    }

    final validLines = _lines.where((line) => line.itemId != null && line.qty > 0 && line.rate >= 0).toList();
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
              description: line.descCtrl.text.trim().isEmpty ? line.itemName : line.descCtrl.text.trim(),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.salesReceiptCreatedSuccess)));
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/sales/receipts');
          }
        },
        failure: (error) => _showError(error.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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
      _syncDateController();
    });
  }

  Future<void> _selectCustomer() async {
    final customersAsync = ref.read(customersProvider);
    final customers = customersAsync.valueOrNull?.where((customer) => customer.isActive).toList() ?? const <CustomerModel>[];
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
                      subtitle: Text('Balance: ${customer.balance.toStringAsFixed(2)} ${customer.currency} • Credits: ${customer.creditBalance.toStringAsFixed(2)}'),
                      onTap: () => Navigator.of(context).pop(customer),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
      ),
    );

    if (selected == null) return;
    setState(() {
      _selectedCustomer = selected;
      _customerCtrl.text = selected.displayName;
    });
  }

  Future<void> _selectDepositAccount() async {
    final accountsAsync = ref.read(accountsProvider);
    final accounts = accountsAsync.valueOrNull
            ?.where((account) => account.isActive && (account.accountType == AccountType.bank || account.accountType == AccountType.otherCurrentAsset))
            .toList() ??
        const <AccountModel>[];

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
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
      ),
    );

    if (selected == null) return;
    setState(() {
      _selectedDepositAccount = selected;
      _depositAccountId = selected.id;
      _depositAccountCtrl.text = '${selected.code} - ${selected.name}';
    });
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _customerCtrl.clear();
    });
  }

  void _clearDepositAccount() {
    setState(() {
      _selectedDepositAccount = null;
      _depositAccountId = null;
      _depositAccountCtrl.clear();
    });
  }

  void _addLine() {
    setState(() => _lines.add(TransactionLineEntry()));
  }

  void _clearLines() {
    if (_lines.length == 1 && _lines.first.itemId == null) return;
    setState(() {
      for (final line in _lines) {
        line.dispose();
      }
      _lines
        ..clear()
        ..add(TransactionLineEntry());
    });
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

    return TransactionKeyboardShortcuts(
      onAddLine: _addLine,
      onFocusBarcode: () => _showInfo('F4 barcode focus will be connected to the new grid focus node.'),
      onPreviousQuantity: () => _showInfo('F5 previous quantity jump will be wired when editable transaction grid replaces the legacy table.'),
      onLookup: () => _showInfo('F7 item lookup is scheduled for the transaction grid.'),
      onToggleSidePanel: () => setState(() => _sidePanelExpanded = !_sidePanelExpanded),
      onSave: _saving ? null : _save,
      onPrint: () => _showInfo('Print preview will be connected to the print service.'),
      onEscape: _cancel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sales Receipt — Full Accounting Mode'),
          actions: [
            IconButton(onPressed: _pickReceiptDate, icon: const Icon(Icons.calendar_today_outlined), tooltip: 'Receipt date'),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TransactionHeaderPanel(
                      kind: TransactionScreenKind.salesReceipt,
                      status: TransactionDocumentStatus.draft,
                      numberController: _numberCtrl,
                      dateController: _dateCtrl,
                      referenceController: _referenceCtrl,
                    ),
                    const SizedBox(height: 12),
                    TransactionPartySelector(
                      partyType: TransactionPartyType.customer,
                      label: l10n.customer,
                      controller: _customerCtrl,
                      selectedDisplayName: _selectedCustomer?.displayName,
                      balanceText: _selectedCustomer == null ? null : 'Balance: ${_selectedCustomer!.balance.toStringAsFixed(2)} ${_selectedCustomer!.currency}',
                      creditText: _selectedCustomer == null ? null : 'Credits: ${_selectedCustomer!.creditBalance.toStringAsFixed(2)} ${_selectedCustomer!.currency}',
                      onSearch: _selectCustomer,
                      onClear: _clearCustomer,
                    ),
                    const SizedBox(height: 12),
                    _PaymentPanel(
                      depositAccountController: _depositAccountCtrl,
                      selectedDepositAccount: _selectedDepositAccount,
                      paymentMethod: _paymentMethod,
                      onSelectDepositAccount: _selectDepositAccount,
                      onClearDepositAccount: _clearDepositAccount,
                      onPaymentMethodChanged: (value) {
                        setState(() {
                          _paymentMethod = value;
                          _paymentMethodCtrl.text = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(l10n.items, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(width: 8),
                        Chip(label: Text('${_lines.length} lines')),
                        const Spacer(),
                        TextButton.icon(onPressed: _addLine, icon: const Icon(Icons.add), label: const Text('Add line')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: TransactionLineTable(
                          lines: _lines,
                          priceMode: TransactionLinePriceMode.sales,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TransactionTotalsFooter(totals: _totals),
                  ],
                ),
              ),
            ),
            TransactionContextSidePanel(
              expanded: _sidePanelExpanded,
              onToggle: () => setState(() => _sidePanelExpanded = !_sidePanelExpanded),
              title: _selectedCustomer?.displayName ?? 'Customer context',
              subtitle: _selectedCustomer == null ? 'Select a customer to show balances and recent activity.' : 'Sales receipt customer snapshot',
              warning: _selectedCustomer == null ? 'No customer selected yet.' : null,
              notes: 'F8 toggles this panel. Sales receipt creates a paid-now sale and linked payment after posting.',
              metrics: _selectedCustomer == null
                  ? const []
                  : [
                      TransactionContextMetric(label: 'Open balance', value: '${_selectedCustomer!.balance.toStringAsFixed(2)} ${_selectedCustomer!.currency}', icon: Icons.receipt_long_outlined),
                      TransactionContextMetric(label: 'Credits', value: '${_selectedCustomer!.creditBalance.toStringAsFixed(2)} ${_selectedCustomer!.currency}', icon: Icons.credit_score_outlined),
                      TransactionContextMetric(label: 'Receipt total', value: '${_totals.total.toStringAsFixed(2)} ${_totals.currency}', icon: Icons.point_of_sale_outlined),
                    ],
              activities: const [],
            ),
          ],
        ),
        bottomNavigationBar: TransactionActionBar(
          status: TransactionDocumentStatus.draft,
          loading: _saving,
          onSaveDraft: null,
          onSave: _save,
          onPost: _save,
          onClear: _clearLines,
          onVoid: null,
          onPrintAction: (action) => _showInfo('${action.name} is scheduled for print service wiring.'),
        ),
      ),
    );
  }
}

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({
    required this.depositAccountController,
    required this.selectedDepositAccount,
    required this.paymentMethod,
    required this.onSelectDepositAccount,
    required this.onClearDepositAccount,
    required this.onPaymentMethodChanged,
  });

  final TextEditingController depositAccountController;
  final AccountModel? selectedDepositAccount;
  final String paymentMethod;
  final VoidCallback onSelectDepositAccount;
  final VoidCallback onClearDepositAccount;
  final ValueChanged<String> onPaymentMethodChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.payments_outlined, color: cs.primary), const SizedBox(width: 8), const Expanded(child: Text('Payment details', style: TextStyle(fontWeight: FontWeight.w900)))]),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final deposit = TextField(
                  controller: depositAccountController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Deposit account',
                    hintText: 'Select bank or current asset account',
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedDepositAccount != null) IconButton(onPressed: onClearDepositAccount, icon: const Icon(Icons.clear), tooltip: 'Clear'),
                        IconButton(onPressed: onSelectDepositAccount, icon: const Icon(Icons.search), tooltip: 'Select'),
                      ],
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onTap: onSelectDepositAccount,
                );
                final method = DropdownButtonFormField<String>(
                  initialValue: paymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment method', border: OutlineInputBorder(), prefixIcon: Icon(Icons.credit_card_outlined), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Check', child: Text('Check')),
                    DropdownMenuItem(value: 'BankTransfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'CreditCard', child: Text('Credit Card')),
                  ],
                  onChanged: (value) {
                    if (value != null) onPaymentMethodChanged(value);
                  },
                );

                if (!wide) return Column(children: [deposit, const SizedBox(height: 12), method]);
                return Row(children: [Expanded(child: deposit), const SizedBox(width: 12), Expanded(child: method)]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

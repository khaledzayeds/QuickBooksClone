// invoice_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../../../core/widgets/transaction_line_table.dart';
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
import '../data/models/invoice_contracts.dart';
import '../data/models/sales_preview_contracts.dart';
import '../providers/invoices_state.dart';

class InvoiceFormPage extends ConsumerStatefulWidget {
  const InvoiceFormPage({super.key});

  @override
  ConsumerState<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends ConsumerState<InvoiceFormPage> {
  CustomerModel? _selectedCustomer;
  CustomerSalesActivityModel? _customerActivity;
  SalesPostingPreviewModel? _preview;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  bool _saving = false;
  bool _previewing = false;
  bool _loadingActivity = false;
  bool _sidePanelExpanded = true;

  final _numberCtrl = TextEditingController(text: 'AUTO');
  final _dateCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController();
  final _termsCtrl = TextEditingController(text: 'Net 14');
  final _referenceCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();

  final List<TransactionLineEntry> _lines = [TransactionLineEntry()];

  @override
  void initState() {
    super.initState();
    _syncDateControllers();
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _dateCtrl.dispose();
    _dueDateCtrl.dispose();
    _termsCtrl.dispose();
    _referenceCtrl.dispose();
    _customerCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double get _subtotal => _lines.fold(0, (sum, line) => sum + line.amount);

  TransactionTotalsUiModel get _totals => TransactionTotalsUiModel(
        subtotal: _preview?.subtotal ?? _subtotal,
        discountTotal: _preview?.discountTotal ?? 0,
        taxTotal: _preview?.taxTotal ?? 0,
        total: _preview?.total ?? _subtotal,
        paid: _preview?.paidAmount ?? 0,
        balanceDue: _preview?.balanceDue ?? _subtotal,
        currency: _customerActivity?.currency ?? _selectedCustomer?.currency ?? 'EGP',
      );

  List<TransactionContextMetric> get _contextMetrics {
    final currency = _customerActivity?.currency ?? _selectedCustomer?.currency ?? 'EGP';
    return [
      if (_customerActivity != null) ...[
        TransactionContextMetric(label: 'Open balance', value: '${_customerActivity!.openBalance.toStringAsFixed(2)} $currency', icon: Icons.receipt_long_outlined),
        TransactionContextMetric(label: 'Credits', value: '${_customerActivity!.creditBalance.toStringAsFixed(2)} $currency', icon: Icons.credit_score_outlined),
      ] else if (_selectedCustomer != null) ...[
        TransactionContextMetric(label: 'Open balance', value: '${_selectedCustomer!.balance.toStringAsFixed(2)} $currency', icon: Icons.receipt_long_outlined),
        TransactionContextMetric(label: 'Credits', value: '${_selectedCustomer!.creditBalance.toStringAsFixed(2)} $currency', icon: Icons.credit_score_outlined),
      ],
      TransactionContextMetric(label: 'Current invoice', value: '${_totals.total.toStringAsFixed(2)} ${_totals.currency}', icon: Icons.description_outlined),
      if (_preview != null) TransactionContextMetric(label: 'Tax', value: '${_preview!.taxTotal.toStringAsFixed(2)} ${_totals.currency}', icon: Icons.percent_outlined),
    ];
  }

  List<TransactionContextActivity> get _contextActivities {
    final activity = _customerActivity;
    if (activity == null) return const [];
    final rows = <TransactionContextActivity>[];
    rows.addAll(activity.recentInvoices.map((x) => TransactionContextActivity(title: 'Invoice ${x.number}', subtitle: _formatDate(x.date), amount: '${x.balanceDue.toStringAsFixed(2)} ${activity.currency}', status: 'Balance')));
    rows.addAll(activity.recentSalesReceipts.map((x) => TransactionContextActivity(title: 'Receipt ${x.number}', subtitle: _formatDate(x.date), amount: '${x.totalAmount.toStringAsFixed(2)} ${activity.currency}', status: 'Paid')));
    rows.addAll(activity.recentPayments.map((x) => TransactionContextActivity(title: 'Payment ${x.number}', subtitle: '${_formatDate(x.paymentDate)} • ${x.paymentMethod}', amount: '${x.amount.toStringAsFixed(2)} ${activity.currency}', status: 'Payment')));
    return rows.take(8).toList();
  }

  String? get _sideWarning {
    if (_selectedCustomer == null) return 'No customer selected yet.';
    final warnings = <String>[
      ...?_customerActivity?.warnings,
      ...?_preview?.warnings,
    ];
    if (warnings.isEmpty) return null;
    return warnings.take(4).join('\n');
  }

  void _syncDateControllers() {
    _dateCtrl.text = _formatDate(_invoiceDate);
    _dueDateCtrl.text = _formatDate(_dueDate);
  }

  List<TransactionLineEntry> _validLines() => _lines.where((line) => line.itemId != null && line.qty > 0 && line.rate >= 0).toList();

  Future<void> _loadCustomerActivity(String customerId) async {
    setState(() => _loadingActivity = true);
    final result = await ref.read(invoicesRepoProvider).getCustomerActivity(customerId, limit: 5);
    if (!mounted) return;
    setState(() => _loadingActivity = false);
    result.when(
      success: (activity) => setState(() => _customerActivity = activity),
      failure: (error) => _showError(error.message),
    );
  }

  Future<void> _runPreview() async {
    if (_selectedCustomer == null) {
      _showError(AppLocalizations.of(context)!.selectCustomer);
      return;
    }
    final validLines = _validLines();
    if (validLines.isEmpty) {
      _showError(AppLocalizations.of(context)!.minOneQty);
      return;
    }
    setState(() => _previewing = true);
    final dto = PreviewInvoiceDto(
      customerId: _selectedCustomer!.id,
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      lines: validLines
          .map((line) => PreviewSalesLineDto(
                itemId: line.itemId!,
                description: line.descCtrl.text.trim().isEmpty ? line.itemName : line.descCtrl.text.trim(),
                quantity: line.qty,
                unitPrice: line.rate,
              ))
          .toList(),
    );
    final result = await ref.read(invoicesRepoProvider).preview(dto);
    if (!mounted) return;
    setState(() => _previewing = false);
    result.when(
      success: (preview) {
        setState(() => _preview = preview);
        _showInfo('Preview updated: ${preview.total.toStringAsFixed(2)} ${_totals.currency}');
      },
      failure: (error) => _showError(error.message),
    );
  }

  Future<void> _save({required bool post}) async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedCustomer == null) {
      _showError(l10n.selectCustomer);
      return;
    }
    if (_dueDate.isBefore(_invoiceDate)) {
      _showError('${l10n.dueDate} < ${l10n.billDate}');
      return;
    }

    final validLines = _validLines();
    if (validLines.isEmpty) {
      _showError(l10n.minOneQty);
      return;
    }

    final dto = CreateInvoiceDto(
      customerId: _selectedCustomer!.id,
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      saveMode: post ? 2 : 1,
      lines: validLines
          .map(
            (line) => CreateInvoiceLineDto(
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
      final result = await ref.read(invoicesRepoProvider).create(dto);
      result.when(
        success: (_) {
          ref.read(invoicesStateProvider.notifier).refresh();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.billCreatedSuccess)));
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.invoices);
          }
        },
        failure: (error) => _showError(error.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error));
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickInvoiceDate() async {
    final picked = await showDatePicker(context: context, initialDate: _invoiceDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (picked == null) return;
    setState(() {
      _invoiceDate = picked;
      if (_dueDate.isBefore(_invoiceDate)) _dueDate = _invoiceDate.add(const Duration(days: 14));
      _preview = null;
      _syncDateControllers();
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (picked == null) return;
    setState(() {
      _dueDate = picked;
      _preview = null;
      _syncDateControllers();
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
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => context.go(AppRoutes.customerNew), child: const Text('New Customer')),
        ],
      ),
    );

    if (selected == null) return;
    setState(() {
      _selectedCustomer = selected;
      _customerActivity = null;
      _preview = null;
      _customerCtrl.text = selected.displayName;
    });
    await _loadCustomerActivity(selected.id);
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _customerActivity = null;
      _preview = null;
      _customerCtrl.clear();
    });
  }

  void _addLine() => setState(() {
        _preview = null;
        _lines.add(TransactionLineEntry());
      });

  void _clearLines() {
    if (_lines.length == 1 && _lines.first.itemId == null) return;
    setState(() {
      for (final line in _lines) {
        line.dispose();
      }
      _lines
        ..clear()
        ..add(TransactionLineEntry());
      _preview = null;
    });
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.invoices);
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
      onSave: _saving ? null : () => _save(post: false),
      onPrint: () => _showInfo('Print preview will be connected to the print service.'),
      onEscape: _cancel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invoice — Full Accounting Mode'),
          actions: [
            TextButton.icon(onPressed: _previewing ? null : _runPreview, icon: _previewing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.analytics_outlined), label: const Text('Preview')),
            IconButton(onPressed: _pickInvoiceDate, icon: const Icon(Icons.calendar_today_outlined), tooltip: 'Invoice date'),
            IconButton(onPressed: _pickDueDate, icon: const Icon(Icons.event_available_outlined), tooltip: 'Due date'),
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
                    TransactionHeaderPanel(kind: TransactionScreenKind.invoice, status: TransactionDocumentStatus.draft, numberController: _numberCtrl, dateController: _dateCtrl, dueDateController: _dueDateCtrl, termsController: _termsCtrl, referenceController: _referenceCtrl),
                    const SizedBox(height: 12),
                    TransactionPartySelector(
                      partyType: TransactionPartyType.customer,
                      label: l10n.customer,
                      controller: _customerCtrl,
                      selectedDisplayName: _selectedCustomer?.displayName,
                      balanceText: _selectedCustomer == null ? null : 'Balance: ${(_customerActivity?.openBalance ?? _selectedCustomer!.balance).toStringAsFixed(2)} ${_customerActivity?.currency ?? _selectedCustomer!.currency}',
                      creditText: _selectedCustomer == null ? null : 'Credits: ${(_customerActivity?.creditBalance ?? _selectedCustomer!.creditBalance).toStringAsFixed(2)} ${_customerActivity?.currency ?? _selectedCustomer!.currency}',
                      onSearch: _selectCustomer,
                      onClear: _clearCustomer,
                      onCreateNew: () => context.go(AppRoutes.customerNew),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text('Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(width: 8),
                        Chip(label: Text('${_lines.length} lines')),
                        if (_preview != null) ...[
                          const SizedBox(width: 8),
                          const Chip(label: Text('Preview ready'), avatar: Icon(Icons.check_circle_outline, size: 18)),
                        ],
                        const Spacer(),
                        TextButton.icon(onPressed: _addLine, icon: const Icon(Icons.add), label: const Text('Add line')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outlineVariant)),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: TransactionLineTable(
                          lines: _lines,
                          priceMode: TransactionLinePriceMode.sales,
                          onChanged: () => setState(() => _preview = null),
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
              subtitle: _loadingActivity ? 'Loading customer activity...' : (_selectedCustomer == null ? 'Select a customer to show balances and recent activity.' : 'Invoice customer snapshot'),
              warning: _sideWarning,
              notes: _preview == null ? 'Press Preview to calculate GL, inventory impact, tax, and warnings before posting.' : 'Preview includes ${_preview!.ledgerImpacts.length} ledger impacts and ${_preview!.inventoryImpacts.length} inventory impacts.',
              metrics: _contextMetrics,
              activities: _contextActivities,
            ),
          ],
        ),
        bottomNavigationBar: TransactionActionBar(status: TransactionDocumentStatus.draft, loading: _saving, onSaveDraft: () => _save(post: false), onSave: () => _save(post: false), onPost: () => _save(post: true), onClear: _clearLines, onVoid: null, onPrintAction: (action) => _showInfo('${action.name} is scheduled for print service wiring.')),
      ),
    );
  }
}

String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

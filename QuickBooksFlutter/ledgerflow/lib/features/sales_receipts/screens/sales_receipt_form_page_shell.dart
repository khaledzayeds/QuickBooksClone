import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_enums.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../invoices/data/models/sales_preview_contracts.dart';
import '../../invoices/providers/invoices_state.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/printing/transaction_print_model.dart';
import '../../transactions/printing/transaction_print_service.dart';
import '../../transactions/widgets/transaction_models.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../providers/sales_receipts_state.dart';
import '../widgets/sales_receipt_form_fields.dart';
import '../widgets/sales_receipt_shell.dart';

const _kPaymentMethods = ['Cash', 'Card', 'Bank Transfer', 'Check', 'Other'];

class SalesReceiptFormPageShell extends ConsumerStatefulWidget {
  const SalesReceiptFormPageShell({super.key});

  @override
  ConsumerState<SalesReceiptFormPageShell> createState() => _SalesReceiptFormPageShellState();
}

class _SalesReceiptFormPageShellState extends ConsumerState<SalesReceiptFormPageShell> {
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
  final _lines = List.generate(5, (_) => TransactionLineEntry());

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = _fmtDate(_receiptDate);
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

  String _fmtDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

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

  List<TransactionLineEntry> _validLines() {
    return _lines.where((line) => line.itemId != null && line.qty > 0 && line.rate >= 0).toList();
  }

  List<TransactionContextMetric> get _metrics {
    final currency = _activity?.currency ?? _customer?.currency ?? 'EGP';
    final fmt = NumberFormat('#,##0.00');
    return [
      if (_customer != null)
        TransactionContextMetric(
          label: 'Open balance',
          value: '${fmt.format(_activity?.openBalance ?? _customer!.balance)} $currency',
          icon: Icons.account_balance_wallet_outlined,
        ),
      if (_customer != null)
        TransactionContextMetric(
          label: 'Credits available',
          value: '${fmt.format(_activity?.creditBalance ?? _customer!.creditBalance)} $currency',
          icon: Icons.credit_score_outlined,
        ),
      TransactionContextMetric(
        label: 'Receipt total',
        value: '${fmt.format(_totals.total)} $currency',
        icon: Icons.receipt_long_outlined,
      ),
      if (_preview != null && _preview!.taxTotal > 0)
        TransactionContextMetric(
          label: 'Tax',
          value: '${fmt.format(_preview!.taxTotal)} $currency',
          icon: Icons.percent_outlined,
        ),
    ];
  }

  List<TransactionContextActivity> get _activities {
    final activity = _activity;
    if (activity == null) return const [];
    return [
      ...activity.recentSalesReceipts.map(
        (receipt) => TransactionContextActivity(
          title: 'Receipt ${receipt.number}',
          subtitle: _fmtDate(receipt.date),
          amount: '${NumberFormat('#,##0.00').format(receipt.totalAmount)} ${activity.currency}',
          status: 'Receipt',
        ),
      ),
      ...activity.recentInvoices.map(
        (invoice) => TransactionContextActivity(
          title: 'Invoice ${invoice.number}',
          subtitle: _fmtDate(invoice.date),
          amount: '${NumberFormat('#,##0.00').format(invoice.balanceDue)} ${activity.currency}',
          status: 'Invoice',
        ),
      ),
      ...activity.recentPayments.map(
        (payment) => TransactionContextActivity(
          title: 'Payment ${payment.number}',
          subtitle: '${_fmtDate(payment.paymentDate)} • ${payment.paymentMethod}',
          amount: '${NumberFormat('#,##0.00').format(payment.amount)} ${activity.currency}',
          status: 'Payment',
        ),
      ),
    ];
  }

  String? get _warning {
    if (_customer == null) return null;
    final warnings = <String>[
      ...?_activity?.warnings,
      ...?_preview?.warnings,
      if (_depositAccount == null) 'Select a deposit account.',
    ];
    return warnings.isEmpty ? null : warnings.join('\n');
  }

  Future<void> _loadCustomerActivity(String customerId) async {
    setState(() => _loadingActivity = true);
    final result = await ref.read(invoicesRepoProvider).getCustomerActivity(customerId, limit: 5);
    if (!mounted) return;
    setState(() => _loadingActivity = false);
    result.when(
      success: (data) => setState(() => _activity = data),
      failure: (error) => _showError(error.message),
    );
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
          .map(
            (line) => PreviewSalesLineDto(
              itemId: line.itemId!,
              description: line.descCtrl.text.trim().isEmpty ? line.itemName : line.descCtrl.text.trim(),
              quantity: line.qty,
              unitPrice: line.rate,
            ),
          )
          .toList(),
    );
    final result = await ref.read(salesReceiptsRepoProvider).preview(dto);
    if (!mounted) return;
    setState(() => _previewing = false);
    result.when(
      success: (data) => setState(() => _preview = data),
      failure: (_) {},
    );
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 550), _runPreview);
  }

  Future<String?> _save() async {
    if (_customer == null) {
      _showError('Select a customer first.');
      return null;
    }
    if (_depositAccount == null) {
      _showError('Select a deposit account first.');
      return null;
    }
    final validLines = _validLines();
    if (validLines.isEmpty) {
      _showError('Add at least one valid line.');
      return null;
    }

    setState(() => _saving = true);
    final dto = CreateSalesReceiptDto(
      customerId: _customer!.id,
      receiptDate: _receiptDate,
      depositAccountId: _depositAccount!.id,
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

    String? savedNumber;
    try {
      final result = await ref.read(salesReceiptsRepoProvider).create(dto);
      if (!mounted) return null;
      result.when(
        success: (doc) {
          savedNumber = doc.receiptNumber;
          ref.read(salesReceiptsStateProvider.notifier).refresh();
        },
        failure: (error) => _showError(error.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    return savedNumber;
  }

  Future<void> _saveAndClose() async {
    final number = await _save();
    if (number != null && mounted) _showPostSaveDialog(number, closeAfter: true);
  }

  Future<void> _saveAndNew() async {
    final number = await _save();
    if (number != null && mounted) {
      _reset();
      _showPostSaveDialog(number, closeAfter: false);
    }
  }

  void _showPostSaveDialog(String docNumber, {required bool closeAfter}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sales Receipt Saved'),
        content: Text('Receipt $docNumber has been saved successfully.'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handlePrint(documentNumber: docNumber);
            },
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (!closeAfter) _reset();
            },
            icon: const Icon(Icons.add),
            label: const Text('New'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (closeAfter) _goBack();
            },
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrint({String? documentNumber}) async {
    if (_customer == null) {
      _showError('Select a customer before printing.');
      return;
    }
    final validLines = _validLines();
    if (validLines.isEmpty) {
      _showError('Add at least one valid line before printing.');
      return;
    }

    final totals = _totals;
    final model = TransactionPrintModel(
      documentTitle: 'Sales Receipt',
      documentNumber: documentNumber ?? _numberCtrl.text.trim().ifEmpty('Preview'),
      documentDate: _receiptDate,
      partyLabel: 'Customer',
      partyName: _customer!.displayName,
      reference: _referenceCtrl.text.trim().isEmpty ? null : _referenceCtrl.text.trim(),
      paymentMethod: _paymentMethod,
      lines: validLines
          .map(
            (line) => TransactionPrintLine(
              itemName: line.itemName.trim().isEmpty ? 'Item' : line.itemName.trim(),
              description: line.descCtrl.text.trim(),
              quantity: line.qty,
              rate: line.rate,
              amount: line.amount,
            ),
          )
          .toList(),
      totals: TransactionPrintTotals(
        subtotal: totals.subtotal,
        discountTotal: totals.discountTotal,
        taxTotal: totals.taxTotal,
        total: totals.total,
        paid: totals.paid,
        balanceDue: totals.balanceDue,
        currency: totals.currency,
      ),
    );

    try {
      await const TransactionPrintService().printDocument(model);
    } catch (e) {
      _showError('Could not open print preview: $e');
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
      _dateCtrl.text = _fmtDate(_receiptDate);
      _referenceCtrl.clear();
      _customerCtrl.clear();
      _depositCtrl.clear();
      for (final line in _lines) {
        line.dispose();
      }
      _lines
        ..clear()
        ..addAll(List.generate(5, (_) => TransactionLineEntry()));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receiptDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _receiptDate = picked;
      _dateCtrl.text = _fmtDate(picked);
      _preview = null;
    });
    _schedulePreview();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _goBack() => context.canPop() ? context.pop() : context.go('/sales/receipts');

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider).maybeWhen(
          data: (items) => items.where((customer) => customer.isActive).toList(),
          orElse: () => const <CustomerModel>[],
        );
    final accounts = ref.watch(accountsProvider).maybeWhen(
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

    return SalesReceiptShell(
      numberField: SalesReceiptFormField(
        label: 'Sales Receipt #',
        child: SalesReceiptReadonlyTextField(controller: _numberCtrl, hint: 'AUTO'),
      ),
      dateField: SalesReceiptFormField(
        label: 'Receipt Date',
        child: SalesReceiptReadonlyTextField(
          controller: _dateCtrl,
          hint: 'dd/mm/yyyy',
          suffixIcon: Icons.calendar_today_outlined,
          onTap: _pickDate,
        ),
      ),
      referenceField: SalesReceiptFormField(
        label: 'Reference / Memo',
        child: SalesReceiptMemoField(
          controller: _referenceCtrl,
          onChanged: (_) => setState(() {}),
        ),
      ),
      customerField: SalesReceiptFormField(
        label: 'Customer',
        required: true,
        child: SalesReceiptCustomerField(
          controller: _customerCtrl,
          customers: customers,
          selected: _customer,
          onSelected: (customer) {
            setState(() {
              _customer = customer;
              _customerCtrl.text = customer.displayName;
              _activity = null;
              _preview = null;
            });
            _loadCustomerActivity(customer.id);
            _schedulePreview();
          },
          onCleared: () => setState(() {
            _customer = null;
            _customerCtrl.clear();
            _activity = null;
            _preview = null;
          }),
        ),
      ),
      depositAccountField: SalesReceiptFormField(
        label: 'Deposit Account',
        required: true,
        child: SalesReceiptDepositAccountField(
          controller: _depositCtrl,
          accounts: accounts,
          selected: _depositAccount,
          onSelected: (account) {
            setState(() {
              _depositAccount = account;
              _depositCtrl.text = account.name;
              _preview = null;
            });
            _schedulePreview();
          },
          onCleared: () => setState(() {
            _depositAccount = null;
            _depositCtrl.clear();
            _preview = null;
          }),
        ),
      ),
      paymentMethodField: SalesReceiptFormField(
        label: 'Payment Method',
        child: SalesReceiptPaymentMethodField(
          value: _paymentMethod,
          methods: _kPaymentMethods,
          onChanged: (method) {
            setState(() {
              _paymentMethod = method;
              _preview = null;
            });
            _schedulePreview();
          },
        ),
      ),
      lines: _lines,
      totals: _totals,
      customer: _customer,
      metrics: _metrics,
      activities: _activities,
      loadingActivity: _loadingActivity,
      warning: _warning,
      referenceText: _referenceCtrl.text,
      saving: _saving,
      onAddLine: _addLine,
      onLinesChanged: () {
        setState(() => _preview = null);
        _schedulePreview();
      },
      onPrint: _handlePrint,
      onClear: _reset,
      onSaveAndNew: _saveAndNew,
      onSaveAndClose: _saveAndClose,
      onClose: _goBack,
    );
  }

  void _addLine() {
    setState(() {
      _preview = null;
      _lines.add(TransactionLineEntry());
    });
    _schedulePreview();
  }
}

extension _EmptyStringFallback on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

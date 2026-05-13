import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_enums.dart';
import '../../../core/api/api_result.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../invoices/data/models/sales_preview_contracts.dart';
import '../../invoices/providers/invoices_state.dart';
import '../../printing/widgets/document_print_preview_dialog.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_models.dart';
import '../../transactions/widgets/void_confirmation_dialog.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../providers/sales_receipts_state.dart';
import '../widgets/notes_edit_dialog.dart';
import '../widgets/sales_receipt_form_fields.dart';
import '../widgets/sales_receipt_shell.dart';

const _kPaymentMethods = ['Cash', 'Card', 'Bank Transfer', 'Check', 'Other'];

class SalesReceiptFormPageShell extends ConsumerStatefulWidget {
  const SalesReceiptFormPageShell({super.key, this.id});

  final String? id;

  @override
  ConsumerState<SalesReceiptFormPageShell> createState() =>
      _SalesReceiptFormPageShellState();
}

class _SalesReceiptFormPageShellState
    extends ConsumerState<SalesReceiptFormPageShell> {
  CustomerModel? _customer;
  CustomerSalesActivityModel? _activity;
  SalesPostingPreviewModel? _preview;
  SalesReceiptModel? _currentReceipt;
  AccountModel? _depositAccount;
  DateTime _receiptDate = DateTime.now();
  String _paymentMethod = 'Cash';
  String? _savedReceiptId;
  String _notes = '';
  bool _saving = false;
  bool _loadingActivity = false;
  bool _loadingExisting = false;
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
    _loadExistingReceipt();
  }

  @override
  void didUpdateWidget(covariant SalesReceiptFormPageShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id == widget.id) return;
    if (_isEdit) {
      Future.microtask(_loadExistingReceipt);
    } else {
      _reset();
    }
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

  bool get _isEdit => widget.id != null && widget.id!.isNotEmpty;
  bool get _readOnly => _currentReceipt != null;

  double get _localSubtotal => _lines.fold(0, (sum, line) => sum + line.amount);

  TransactionTotalsUiModel get _totals => TransactionTotalsUiModel(
    subtotal: _preview?.subtotal ?? _currentReceipt?.subtotal ?? _localSubtotal,
    discountTotal:
        _preview?.discountTotal ?? _currentReceipt?.discountAmount ?? 0,
    taxTotal: _preview?.taxTotal ?? _currentReceipt?.taxAmount ?? 0,
    total: _preview?.total ?? _currentReceipt?.totalAmount ?? _localSubtotal,
    paid: _preview?.paidAmount ?? _currentReceipt?.paidAmount ?? _localSubtotal,
    balanceDue: _preview?.balanceDue ?? _currentReceipt?.balanceDue ?? 0,
    currency: _activity?.currency ?? _customer?.currency ?? 'EGP',
  );

  List<TransactionLineEntry> _validLines() {
    return _lines
        .where((line) => line.itemId != null && line.qty > 0 && line.rate >= 0)
        .toList();
  }

  List<TransactionContextMetric> get _metrics {
    final currency = _activity?.currency ?? _customer?.currency ?? 'EGP';
    final fmt = NumberFormat('#,##0.00');
    return [
      if (_customer != null)
        TransactionContextMetric(
          label: 'Open balance',
          value:
              '${fmt.format(_activity?.openBalance ?? _customer!.balance)} $currency',
          icon: Icons.account_balance_wallet_outlined,
        ),
      if (_customer != null)
        TransactionContextMetric(
          label: 'Credits available',
          value:
              '${fmt.format(_activity?.creditBalance ?? _customer!.creditBalance)} $currency',
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
          amount:
              '${NumberFormat('#,##0.00').format(receipt.totalAmount)} ${activity.currency}',
          status: 'Receipt',
        ),
      ),
      ...activity.recentInvoices.map(
        (invoice) => TransactionContextActivity(
          title: 'Invoice ${invoice.number}',
          subtitle: _fmtDate(invoice.date),
          amount:
              '${NumberFormat('#,##0.00').format(invoice.balanceDue)} ${activity.currency}',
          status: 'Invoice',
        ),
      ),
      ...activity.recentPayments.map(
        (payment) => TransactionContextActivity(
          title: 'Payment ${payment.number}',
          subtitle:
              '${_fmtDate(payment.paymentDate)} • ${payment.paymentMethod}',
          amount:
              '${NumberFormat('#,##0.00').format(payment.amount)} ${activity.currency}',
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
      if (!_readOnly && _depositAccount == null) 'Select a deposit account.',
      if (_currentReceipt?.isVoid == true)
        'This sales receipt is void and cannot be changed.',
      if (_readOnly && _currentReceipt?.isVoid != true)
        'Saved sales receipts are read-only. Use Void to reverse them.',
    ];
    return warnings.isEmpty ? null : warnings.join('\n');
  }

  Future<void> _loadExistingReceipt() async {
    final id = widget.id;
    if (id == null || id.isEmpty) return;
    setState(() => _loadingExisting = true);
    final result = await ref.read(salesReceiptsRepoProvider).getById(id);
    if (!mounted || widget.id != id) return;
    setState(() => _loadingExisting = false);
    result.when(
      success: (receipt) async {
        for (final line in _lines) {
          line.dispose();
        }
        final loadedLines = receipt.lines.map((line) {
          final entry = TransactionLineEntry(
            itemId: line.itemId,
            itemName: line.description,
            qty: line.quantity,
            rate: line.unitPrice,
          );
          entry.descCtrl.text = line.description;
          entry.qtyCtrl.text = line.quantity.toString();
          entry.rateCtrl.text = line.unitPrice.toString();
          return entry;
        }).toList();
        setState(() {
          _currentReceipt = receipt;
          _savedReceiptId = receipt.id;
          _receiptDate = receipt.receiptDate;
          _paymentMethod = receipt.paymentMethod ?? 'Cash';
          _numberCtrl.text = receipt.receiptNumber;
          _dateCtrl.text = _fmtDate(receipt.receiptDate);
          _customer = CustomerModel(
            id: receipt.customerId,
            displayName: receipt.customerName,
            isActive: true,
            balance: 0,
            creditBalance: 0,
          );
          _customerCtrl.text = receipt.customerName;
          _depositAccount = receipt.depositAccountId == null
              ? null
              : AccountModel(
                  id: receipt.depositAccountId!,
                  code: '',
                  name: receipt.depositAccountName ?? 'Deposit account',
                  accountType: AccountType.bank,
                  balance: 0,
                  isActive: true,
                );
          _depositCtrl.text = receipt.depositAccountName ?? '';
          _lines
            ..clear()
            ..addAll(
              loadedLines.isEmpty ? [TransactionLineEntry()] : loadedLines,
            );
          _preview = null;
        });
        await _loadReceiptNotes(receipt.id);
        await _loadCustomerActivity(receipt.customerId);
      },
      failure: (error) => _showError(error.message),
    );
  }

  String? get _statusBadgeText {
    final receipt = _currentReceipt;
    if (receipt == null) return null;
    if (receipt.isVoid) return 'VOID';
    return 'PAID';
  }

  String? get _statusMessage {
    final receipt = _currentReceipt;
    if (receipt == null) return null;
    final currency = _activity?.currency ?? _customer?.currency ?? 'EGP';
    final total = NumberFormat('#,##0.00').format(receipt.totalAmount);
    final deposit = receipt.depositAccountName?.trim();
    if (receipt.isVoid) {
      return 'This sales receipt is void. Accounting movement was reversed.';
    }
    if (deposit != null && deposit.isNotEmpty) {
      return 'Paid sales receipt: $total $currency deposited to $deposit.';
    }
    return 'Paid sales receipt: $total $currency received.';
  }

  Color get _statusColor {
    final receipt = _currentReceipt;
    if (receipt?.isVoid == true) return const Color(0xFFC62828);
    return const Color(0xFF2E7D32);
  }

  Future<void> _loadCustomerActivity(String customerId) async {
    setState(() => _loadingActivity = true);
    final result = await ref
        .read(invoicesRepoProvider)
        .getCustomerActivity(customerId, limit: 5);
    if (!mounted) return;
    setState(() => _loadingActivity = false);
    result.when(
      success: (data) => setState(() => _activity = data),
      failure: (error) => _showError(error.message),
    );
  }

  Future<void> _runPreview() async {
    if (_readOnly) return;
    if (_customer == null || _depositAccount == null || _validLines().isEmpty) {
      return;
    }
    final dto = PreviewSalesReceiptDto(
      customerId: _customer!.id,
      receiptDate: _receiptDate,
      depositAccountId: _depositAccount!.id,
      paymentMethod: _paymentMethod,
      lines: _validLines()
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
    result.when(
      success: (data) => setState(() => _preview = data),
      failure: (_) {},
    );
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 550), _runPreview);
  }

  Future<SalesReceiptModel?> _save() async {
    if (_readOnly) return _currentReceipt;
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
              description: line.descCtrl.text.trim().isEmpty
                  ? line.itemName
                  : line.descCtrl.text.trim(),
              quantity: line.qty,
              unitPrice: line.rate,
            ),
          )
          .toList(),
    );

    SalesReceiptModel? savedReceipt;
    try {
      final result = await ref.read(salesReceiptsRepoProvider).create(dto);
      if (!mounted) return null;
      result.when(
        success: (doc) {
          savedReceipt = doc;
          _currentReceipt = doc;
          _savedReceiptId = doc.id;
          _numberCtrl.text = doc.receiptNumber;
          ref.read(salesReceiptsStateProvider.notifier).refresh();
        },
        failure: (error) => _showError(error.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (savedReceipt != null) {
      await _saveReceiptNotes(savedReceipt!.id);
    }
    return savedReceipt;
  }

  Future<void> _saveAndClose() async {
    final receipt = await _save();
    if (receipt != null && mounted) {
      _showPostSaveDialog(receipt.receiptNumber, closeAfter: true);
    }
  }

  Future<void> _saveAndNew() async {
    final receipt = await _save();
    if (receipt != null && mounted) {
      _reset();
      _showPostSaveDialog(receipt.receiptNumber, closeAfter: false);
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
    final receipt = await _ensureSavedReceipt();
    if (receipt == null || !mounted) return;
    try {
      await printDocumentUsingSettings(
        context: context,
        ref: ref,
        documentType: 'sales-receipt',
        documentId: receipt.id,
      );
    } catch (e) {
      _showError('Could not print sales receipt: $e');
    }
  }

  Future<SalesReceiptModel?> _ensureSavedReceipt() async {
    if (_currentReceipt != null) return _currentReceipt;
    return _save();
  }

  Future<void> _handleVoid() async {
    final receipt = _currentReceipt;
    if (receipt == null || receipt.isVoid) return;
    final confirmed = await showVoidConfirmationDialog(
      context: context,
      documentLabel: 'sales receipt ${receipt.receiptNumber}',
      warning: 'Voiding will reverse this cash sale and linked payment.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    final result = await ref
        .read(salesReceiptsRepoProvider)
        .voidReceipt(receipt.id);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success(data: final updated):
        setState(() => _currentReceipt = updated);
        ref.read(salesReceiptsStateProvider.notifier).refresh();
        ref.invalidate(salesReceiptDetailsStateProvider(updated.id));
      case Failure(error: final error):
        _showError(error.message);
    }
  }

  void _reset() {
    setState(() {
      _customer = null;
      _activity = null;
      _preview = null;
      _currentReceipt = null;
      _depositAccount = null;
      _receiptDate = DateTime.now();
      _paymentMethod = 'Cash';
      _savedReceiptId = null;
      _notes = '';
      _loadingExisting = false;
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
    if (_readOnly) return;
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

  Future<void> _openNotesDialog() async {
    final receiptId = _savedReceiptId;
    if (receiptId != null && receiptId.trim().isNotEmpty) {
      await _loadReceiptNotes(receiptId);
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => NotesEditDialog(
        initialNotes: _notes,
        onSave: (newNotes) async {
          if (!mounted) return;
          setState(() => _notes = newNotes);
          final savedId = _savedReceiptId;
          if (savedId != null && savedId.trim().isNotEmpty) {
            await _saveReceiptNotes(savedId);
          }
        },
      ),
    );
  }

  Future<void> _loadReceiptNotes(String receiptId) async {
    try {
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '/api/sales-receipts/$receiptId/notes',
      );
      final data = response.data ?? const <String, dynamic>{};
      final notes = data['notes'] ?? data['Notes'];
      if (mounted) setState(() => _notes = notes?.toString() ?? '');
    } catch (_) {}
  }

  Future<void> _saveReceiptNotes(String receiptId) async {
    if (_notes.trim().isEmpty) return;
    try {
      await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/sales-receipts/$receiptId/notes',
        data: {'notes': _notes.trim()},
      );
    } catch (_) {}
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _goBack() => context.go(AppRoutes.salesReceipts);

  void _handleClearOrNew() {
    if (_isEdit) {
      context.go(AppRoutes.salesReceiptNew);
    } else {
      _reset();
    }
  }

  void _openAdjacentReceipt(int direction) {
    final currentId = widget.id;
    if (currentId == null || currentId.isEmpty) return;
    final receipts = ref
        .read(salesReceiptsStateProvider)
        .maybeWhen(
          data: (items) =>
              [...items]
                ..sort((a, b) => b.receiptDate.compareTo(a.receiptDate)),
          orElse: () => const <SalesReceiptModel>[],
        );
    final index = receipts.indexWhere((receipt) => receipt.id == currentId);
    final targetIndex = index + direction;
    if (index < 0 || targetIndex < 0 || targetIndex >= receipts.length) return;
    context.go(
      AppRoutes.salesReceiptDetails.replaceFirst(
        ':id',
        receipts[targetIndex].id,
      ),
    );
  }

  bool _hasAdjacentReceipt(int direction) {
    final currentId = widget.id;
    if (currentId == null || currentId.isEmpty) return false;
    final receipts = ref
        .watch(salesReceiptsStateProvider)
        .maybeWhen(
          data: (items) =>
              [...items]
                ..sort((a, b) => b.receiptDate.compareTo(a.receiptDate)),
          orElse: () => const <SalesReceiptModel>[],
        );
    final index = receipts.indexWhere((receipt) => receipt.id == currentId);
    final targetIndex = index + direction;
    return index >= 0 && targetIndex >= 0 && targetIndex < receipts.length;
  }

  void _openCustomerHistory() {
    final customer = _customer;
    if (customer == null) return;
    context.push(
      AppRoutes.customerTransactionHistory,
      extra: {'customerId': customer.id, 'customerName': customer.displayName},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingExisting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final customers = ref
        .watch(customersProvider)
        .maybeWhen(
          data: (items) =>
              items.where((customer) => customer.isActive).toList(),
          orElse: () => const <CustomerModel>[],
        );
    final accounts = ref
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

    return SalesReceiptShell(
      numberField: SalesReceiptFormField(
        label: 'Sales Receipt #',
        child: SalesReceiptReadonlyTextField(
          controller: _numberCtrl,
          hint: 'AUTO',
        ),
      ),
      dateField: SalesReceiptFormField(
        label: 'Receipt Date',
        child: SalesReceiptReadonlyTextField(
          controller: _dateCtrl,
          hint: 'dd/mm/yyyy',
          suffixIcon: Icons.calendar_today_outlined,
          enabled: !_readOnly,
          onTap: _pickDate,
        ),
      ),
      referenceField: SalesReceiptFormField(
        label: 'Reference / Memo',
        child: SalesReceiptMemoField(
          controller: _referenceCtrl,
          enabled: !_readOnly,
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
          enabled: !_readOnly,
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
          enabled: !_readOnly,
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
          enabled: !_readOnly,
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
      statusBadgeText: _statusBadgeText,
      statusMessage: _statusMessage,
      statusColor: _statusColor,
      referenceText: _notes.trim().isEmpty ? _referenceCtrl.text : _notes,
      saving: _saving,
      isEdit: _isEdit,
      readOnly: _readOnly,
      onAddLine: _addLine,
      onLinesChanged: () {
        if (_readOnly) return;
        setState(() => _preview = null);
        _schedulePreview();
      },
      onFind: () => context.go(AppRoutes.salesReceipts),
      onPrevious: _hasAdjacentReceipt(-1)
          ? () => _openAdjacentReceipt(-1)
          : null,
      onNext: _hasAdjacentReceipt(1) ? () => _openAdjacentReceipt(1) : null,
      onPrint: _handlePrint,
      onVoid: _currentReceipt != null && !_currentReceipt!.isVoid
          ? _handleVoid
          : null,
      onClear: _handleClearOrNew,
      onSaveAndNew: _readOnly ? null : _saveAndNew,
      onSaveAndClose: _readOnly ? null : _saveAndClose,
      onClose: _goBack,
      onViewAll: _customer == null ? null : _openCustomerHistory,
      onEditNotes: _openNotesDialog,
    );
  }

  void _addLine() {
    if (_readOnly) return;
    setState(() {
      _preview = null;
      _lines.add(TransactionLineEntry());
    });
    _schedulePreview();
  }
}

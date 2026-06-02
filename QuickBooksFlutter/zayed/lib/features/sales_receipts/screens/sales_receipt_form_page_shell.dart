import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_enums.dart' hide ItemType;
import '../../../core/api/api_result.dart';
import '../../../core/constants/api_enums.dart' as api;
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../companies/providers/company_registry_provider.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../invoices/data/models/sales_preview_contracts.dart';
import '../../invoices/providers/invoices_state.dart';
import '../../items/data/models/item_model.dart';
import '../../items/providers/items_provider.dart';
import '../../items/utils/item_barcode_utils.dart';
import '../../printing/widgets/document_print_preview_dialog.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/widgets/transaction_models.dart';
import '../../transactions/widgets/void_confirmation_dialog.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../providers/sales_receipts_state.dart';
import '../widgets/notes_edit_dialog.dart';
import '../widgets/sales_receipt_cashier_template.dart';
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
  SalesReceiptTemplateMode _templateMode = SalesReceiptTemplateMode.standard;
  Timer? _previewDebounce;
  String? _companyScopeKey;

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

  Future<SalesReceiptModel?> _save({bool skipAutoPrint = false}) async {
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

          if (!skipAutoPrint) {
            _triggerAutoPrint(doc.id, 'sales-receipt');
          }
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
    return _save(skipAutoPrint: true);
  }

  void _triggerAutoPrint(String documentId, String documentType) {
    Future.microtask(() async {
      try {
        if (!mounted) return;
        await printDocumentAfterSaveIfEnabled(
          context: context,
          ref: ref,
          documentType: documentType,
          documentId: documentId,
        );
      } catch (_) {}
    });
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

  void _syncCompanyScope(String? scopeKey) {
    if (_companyScopeKey == null) {
      _companyScopeKey = scopeKey;
      return;
    }
    if (_companyScopeKey == scopeKey) return;
    _companyScopeKey = scopeKey;
    _previewDebounce?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isEdit) {
        context.go(AppRoutes.salesReceiptNew);
      } else {
        _reset();
      }
    });
  }

  void _openCustomerHistory() {
    final customer = _customer;
    if (customer == null) return;
    context.push(
      AppRoutes.customerTransactionHistory,
      extra: {'customerId': customer.id, 'customerName': customer.displayName},
    );
  }

  void _setCustomer(CustomerModel customer) {
    setState(() {
      _customer = customer;
      _customerCtrl.text = customer.displayName;
      _activity = null;
      _preview = null;
    });
    _loadCustomerActivity(customer.id);
    _schedulePreview();
  }

  void _clearCustomer() {
    setState(() {
      _customer = null;
      _customerCtrl.clear();
      _activity = null;
      _preview = null;
    });
  }

  void _setDepositAccount(AccountModel account) {
    setState(() {
      _depositAccount = account;
      _depositCtrl.text = account.name;
      _preview = null;
    });
    _schedulePreview();
  }

  void _clearDepositAccount() {
    setState(() {
      _depositAccount = null;
      _depositCtrl.clear();
      _preview = null;
    });
  }

  void _applyCashierItem(ItemModel item) {
    if (_readOnly) return;
    if (item.isInventory && item.quantityOnHand <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} has no stock on hand.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    setState(() {
      final existing = _lines.where((line) => line.itemId == item.id).toList();
      if (existing.isNotEmpty) {
        final line = existing.first;
        line.qty += 1;
        line.qtyCtrl.text = line.qty.toString();
      } else {
        final empty = _lines.where((line) => line.itemId == null).toList();
        final line = empty.isNotEmpty ? empty.first : TransactionLineEntry();
        if (empty.isEmpty) _lines.add(line);
        line.itemId = item.id;
        line.itemName = item.name;
        line.qty = 1;
        line.rate = item.salesPrice;
        line.descCtrl.text = item.name;
        line.qtyCtrl.text = '1';
        line.rateCtrl.text = item.salesPrice.toString();
      }
      _preview = null;
    });
    _schedulePreview();
  }

  void _setCashierLineQty(TransactionLineEntry line, double qty) {
    if (_readOnly) return;
    if (qty <= 0) {
      _removeCashierLine(line);
      return;
    }
    setState(() {
      line.qty = qty;
      line.qtyCtrl.text = qty.toString();
      _preview = null;
    });
    _schedulePreview();
  }

  void _setCashierLineRate(TransactionLineEntry line, double rate) {
    if (_readOnly) return;
    setState(() {
      line.rate = rate < 0 ? 0 : rate;
      _preview = null;
    });
    _schedulePreview();
  }

  void _removeCashierLine(TransactionLineEntry line) {
    if (_readOnly) return;
    setState(() {
      if (_lines.length <= 1) {
        _clearLine(line);
      } else {
        _lines.remove(line);
        line.dispose();
      }
      if (_lines.isEmpty) _lines.add(TransactionLineEntry());
      _preview = null;
    });
    _schedulePreview();
  }

  void _clearLine(TransactionLineEntry line) {
    line.itemId = null;
    line.itemName = '';
    line.qty = 1;
    line.rate = 0;
    line.descCtrl.clear();
    line.qtyCtrl.text = '1';
    line.rateCtrl.text = '0';
  }

  String? _defaultAccountId(
    List<AccountModel> accounts,
    List<api.AccountType> types,
    List<String> keywords,
  ) {
    final pool = accounts
        .where(
          (account) => account.isActive && types.contains(account.accountType),
        )
        .toList();
    for (final keyword in keywords) {
      final match = pool.cast<AccountModel?>().firstWhere(
        (account) => account!.name.toLowerCase().contains(keyword),
        orElse: () => null,
      );
      if (match != null) return match.id;
    }
    return pool.isEmpty ? null : pool.first.id;
  }

  Future<void> _openQuickCustomerDialog() async {
    if (_readOnly) return;
    final draft = await showDialog<_QuickCustomerDraft>(
      context: context,
      builder: (_) => const _QuickCustomerDialog(),
    );
    if (draft == null || !mounted) return;
    setState(() => _saving = true);
    final result = await ref.read(customersProvider.notifier).createCustomer({
      'displayName': draft.displayName,
      if (draft.companyName.isNotEmpty) 'companyName': draft.companyName,
      if (draft.phone.isNotEmpty) 'phone': draft.phone,
      if (draft.email.isNotEmpty) 'email': draft.email,
      'currency': draft.currency,
      'openingBalance': 0,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (customer) {
        _setCustomer(customer);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${customer.displayName} created.')),
        );
      },
      failure: (error) => _showError(error.message),
    );
  }

  Future<void> _openQuickItemDialog(List<AccountModel> allAccounts) async {
    if (_readOnly) return;
    final existingItems = ref.read(itemsProvider).value ?? const <ItemModel>[];
    final defaults = _QuickItemAccountDefaults(
      incomeAccountId: _defaultAccountId(
        allAccounts,
        [api.AccountType.income, api.AccountType.otherIncome],
        ['sales income', 'income', 'sales'],
      ),
      inventoryAssetAccountId: _defaultAccountId(
        allAccounts,
        [api.AccountType.inventoryAsset, api.AccountType.otherCurrentAsset],
        ['inventory asset', 'inventory'],
      ),
      cogsAccountId: _defaultAccountId(
        allAccounts,
        [api.AccountType.costOfGoodsSold],
        ['cost of goods', 'cogs'],
      ),
      expenseAccountId: _defaultAccountId(
        allAccounts,
        [
          api.AccountType.expense,
          api.AccountType.otherExpense,
          api.AccountType.costOfGoodsSold,
        ],
        ['expense', 'cost'],
      ),
    );
    final draft = await showDialog<_QuickItemDraft>(
      context: context,
      builder: (_) => _QuickItemDialog(
        accounts: allAccounts.where((account) => account.isActive).toList(),
        defaults: defaults,
        suggestedBarcode: ItemBarcodeUtils.generateInStoreBarcode(
          existingItems,
        ),
      ),
    );
    if (draft == null || !mounted) return;
    final accountError = draft.validateAccounts();
    if (accountError != null) {
      _showError(accountError);
      return;
    }
    setState(() => _saving = true);
    final result = await ref
        .read(itemsProvider.notifier)
        .createItem(draft.toBody());
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (item) {
        _applyCashierItem(item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} created and added.')),
        );
      },
      failure: (error) => _showError(error.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncCompanyScope(ref.watch(activeCompanyScopeProvider));
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
    final allAccounts = ref
        .watch(accountsProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <AccountModel>[],
        );
    final sellableItems = ref
        .watch(itemsProvider)
        .maybeWhen(
          data: (items) => items
              .where(
                (item) => item.isActive && !item.isBundle && !item.isSubtotal,
              )
              .toList(),
          orElse: () => const <ItemModel>[],
        );

    final dateField = SalesReceiptFormField(
      label: 'Receipt Date',
      child: SalesReceiptReadonlyTextField(
        controller: _dateCtrl,
        hint: 'dd/mm/yyyy',
        suffixIcon: Icons.calendar_today_outlined,
        enabled: !_readOnly,
        onTap: _pickDate,
      ),
    );
    final referenceField = SalesReceiptFormField(
      label: 'Reference / Memo',
      child: SalesReceiptMemoField(
        controller: _referenceCtrl,
        enabled: !_readOnly,
        onChanged: (_) => setState(() {}),
      ),
    );
    final customerField = SalesReceiptFormField(
      label: 'Customer',
      required: true,
      child: SalesReceiptCustomerField(
        controller: _customerCtrl,
        customers: customers,
        selected: _customer,
        enabled: !_readOnly,
        onSelected: _setCustomer,
        onCleared: _clearCustomer,
      ),
    );
    final depositAccountField = SalesReceiptFormField(
      label: 'Deposit Account',
      required: true,
      child: SalesReceiptDepositAccountField(
        controller: _depositCtrl,
        accounts: accounts,
        selected: _depositAccount,
        enabled: !_readOnly,
        onSelected: _setDepositAccount,
        onCleared: _clearDepositAccount,
      ),
    );
    final paymentMethodField = SalesReceiptFormField(
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
    );
    final templateSwitcher = SalesReceiptTemplateSwitcher(
      mode: _templateMode,
      enabled: !_readOnly,
      onChanged: (mode) => setState(() => _templateMode = mode),
    );

    if (_templateMode == SalesReceiptTemplateMode.cashier) {
      return SalesReceiptCashierTemplate(
        mode: _templateMode,
        onModeChanged: (mode) => setState(() => _templateMode = mode),
        customerField: customerField,
        depositAccountField: depositAccountField,
        paymentMethodField: paymentMethodField,
        dateField: dateField,
        referenceField: referenceField,
        items: sellableItems,
        lines: _lines,
        totals: _totals,
        saving: _saving,
        readOnly: _readOnly,
        warning: _warning,
        onItemSelected: _applyCashierItem,
        onLineQtyChanged: _setCashierLineQty,
        onLineRateChanged: _setCashierLineRate,
        onRemoveLine: _removeCashierLine,
        onSaveAndNew: _readOnly ? null : _saveAndNew,
        onSaveAndClose: _readOnly ? null : _saveAndClose,
        onPrint: _handlePrint,
        onClear: _handleClearOrNew,
        onClose: _goBack,
        onQuickAddCustomer: _openQuickCustomerDialog,
        onQuickAddItem: () => _openQuickItemDialog(allAccounts),
      );
    }

    return SalesReceiptShell(
      numberField: SalesReceiptFormField(
        label: 'Sales Receipt #',
        child: SalesReceiptReadonlyTextField(
          controller: _numberCtrl,
          hint: 'AUTO',
        ),
      ),
      dateField: dateField,
      referenceField: referenceField,
      customerField: customerField,
      depositAccountField: depositAccountField,
      paymentMethodField: paymentMethodField,
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
      templateSwitcher: templateSwitcher,
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

class _QuickCustomerDraft {
  const _QuickCustomerDraft({
    required this.displayName,
    required this.companyName,
    required this.phone,
    required this.email,
    required this.currency,
  });

  final String displayName;
  final String companyName;
  final String phone;
  final String email;
  final String currency;
}

class _QuickCustomerDialog extends StatefulWidget {
  const _QuickCustomerDialog();

  @override
  State<_QuickCustomerDialog> createState() => _QuickCustomerDialogState();
}

class _QuickCustomerDialogState extends State<_QuickCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _currency = 'EGP';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Customer'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Customer name required'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 112,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'EGP', child: Text('EGP')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                      ],
                      onChanged: (value) =>
                          setState(() => _currency = value ?? 'EGP'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              _QuickCustomerDraft(
                displayName: _nameCtrl.text.trim(),
                companyName: _companyCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
                email: _emailCtrl.text.trim(),
                currency: _currency,
              ),
            );
          },
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Create'),
        ),
      ],
    );
  }
}

class _QuickItemAccountDefaults {
  const _QuickItemAccountDefaults({
    required this.incomeAccountId,
    required this.inventoryAssetAccountId,
    required this.cogsAccountId,
    required this.expenseAccountId,
  });

  final String? incomeAccountId;
  final String? inventoryAssetAccountId;
  final String? cogsAccountId;
  final String? expenseAccountId;
}

class _QuickItemDraft {
  const _QuickItemDraft({
    required this.name,
    required this.itemType,
    required this.salesPrice,
    required this.purchasePrice,
    required this.quantityOnHand,
    required this.sku,
    required this.barcode,
    required this.unit,
    required this.incomeAccountId,
    required this.inventoryAssetAccountId,
    required this.cogsAccountId,
    required this.expenseAccountId,
  });

  final String name;
  final ItemType itemType;
  final double salesPrice;
  final double purchasePrice;
  final double quantityOnHand;
  final String sku;
  final String barcode;
  final String unit;
  final String? incomeAccountId;
  final String? inventoryAssetAccountId;
  final String? cogsAccountId;
  final String? expenseAccountId;

  String? validateAccounts() {
    if (itemType == ItemType.inventory ||
        itemType == ItemType.inventoryAssembly) {
      if (incomeAccountId == null) return 'Income account required.';
      if (inventoryAssetAccountId == null) {
        return 'Inventory asset account required.';
      }
      if (cogsAccountId == null) return 'COGS account required.';
    }
    if ((itemType == ItemType.nonInventory ||
            itemType == ItemType.service ||
            itemType == ItemType.otherCharge ||
            itemType == ItemType.discount) &&
        incomeAccountId == null &&
        expenseAccountId == null) {
      return 'Income or expense account required.';
    }
    return null;
  }

  Map<String, dynamic> toBody() => {
    'name': name,
    'itemType': itemType.value,
    'salesPrice': salesPrice,
    'purchasePrice': purchasePrice,
    if (sku.isNotEmpty) 'sku': sku,
    if (barcode.isNotEmpty) 'barcode': barcode,
    if (unit.isNotEmpty) 'unit': unit,
    if (itemType == ItemType.inventory ||
        itemType == ItemType.inventoryAssembly)
      'quantityOnHand': quantityOnHand,
    if (incomeAccountId != null) 'incomeAccountId': incomeAccountId,
    if (inventoryAssetAccountId != null)
      'inventoryAssetAccountId': inventoryAssetAccountId,
    if (cogsAccountId != null) 'cogsAccountId': cogsAccountId,
    if (expenseAccountId != null) 'expenseAccountId': expenseAccountId,
  };
}

class _QuickItemDialog extends StatefulWidget {
  const _QuickItemDialog({
    required this.accounts,
    required this.defaults,
    required this.suggestedBarcode,
  });

  final List<AccountModel> accounts;
  final _QuickItemAccountDefaults defaults;
  final String suggestedBarcode;

  @override
  State<_QuickItemDialog> createState() => _QuickItemDialogState();
}

class _QuickItemDialogState extends State<_QuickItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'pcs');
  final _salesPriceCtrl = TextEditingController(text: '0');
  final _purchasePriceCtrl = TextEditingController(text: '0');
  final _qtyCtrl = TextEditingController(text: '0');
  ItemType _itemType = ItemType.inventory;
  String? _incomeAccountId;
  String? _inventoryAssetAccountId;
  String? _cogsAccountId;
  String? _expenseAccountId;

  @override
  void initState() {
    super.initState();
    _barcodeCtrl.text = widget.suggestedBarcode;
    _incomeAccountId = widget.defaults.incomeAccountId;
    _inventoryAssetAccountId = widget.defaults.inventoryAssetAccountId;
    _cogsAccountId = widget.defaults.cogsAccountId;
    _expenseAccountId = widget.defaults.expenseAccountId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _unitCtrl.dispose();
    _salesPriceCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  bool get _tracksInventory =>
      _itemType == ItemType.inventory ||
      _itemType == ItemType.inventoryAssembly;

  String? _numberValidator(String? value) {
    final number = double.tryParse(value ?? '');
    if (number == null) return 'Invalid number';
    if (number < 0) return 'Cannot be negative';
    return null;
  }

  List<AccountModel> _accountsFor(List<api.AccountType> types) => widget
      .accounts
      .where((account) => types.contains(account.accountType))
      .toList();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Item'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Item name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Item name required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<ItemType>(
                        initialValue: _itemType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ItemType.inventory,
                            child: Text('Inventory Part'),
                          ),
                          DropdownMenuItem(
                            value: ItemType.nonInventory,
                            child: Text('Non-inventory'),
                          ),
                          DropdownMenuItem(
                            value: ItemType.service,
                            child: Text('Service'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _itemType = value;
                            _unitCtrl.text = _tracksInventory ? 'pcs' : 'hr';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'Generate barcode',
                      onPressed: () => setState(
                        () => _barcodeCtrl.text = widget.suggestedBarcode,
                      ),
                      icon: const Icon(Icons.auto_awesome_outlined),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _skuCtrl,
                        decoration: const InputDecoration(
                          labelText: 'SKU',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _salesPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Sales price',
                          border: OutlineInputBorder(),
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _purchasePriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Purchase cost',
                          border: OutlineInputBorder(),
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (_tracksInventory) ...[
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        child: TextFormField(
                          controller: _qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'On hand',
                            border: OutlineInputBorder(),
                          ),
                          validator: _numberValidator,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _AccountDropdown(
                  label: 'Income account',
                  value: _incomeAccountId,
                  accounts: _accountsFor([
                    api.AccountType.income,
                    api.AccountType.otherIncome,
                  ]),
                  required: true,
                  onChanged: (value) =>
                      setState(() => _incomeAccountId = value),
                ),
                if (_tracksInventory) ...[
                  const SizedBox(height: 10),
                  _AccountDropdown(
                    label: 'Inventory asset account',
                    value: _inventoryAssetAccountId,
                    accounts: _accountsFor([
                      api.AccountType.inventoryAsset,
                      api.AccountType.otherCurrentAsset,
                    ]),
                    required: true,
                    onChanged: (value) =>
                        setState(() => _inventoryAssetAccountId = value),
                  ),
                  const SizedBox(height: 10),
                  _AccountDropdown(
                    label: 'COGS account',
                    value: _cogsAccountId,
                    accounts: _accountsFor([api.AccountType.costOfGoodsSold]),
                    required: true,
                    onChanged: (value) =>
                        setState(() => _cogsAccountId = value),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  _AccountDropdown(
                    label: 'Expense account',
                    value: _expenseAccountId,
                    accounts: _accountsFor([
                      api.AccountType.expense,
                      api.AccountType.otherExpense,
                      api.AccountType.costOfGoodsSold,
                    ]),
                    onChanged: (value) =>
                        setState(() => _expenseAccountId = value),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final draft = _QuickItemDraft(
              name: _nameCtrl.text.trim(),
              itemType: _itemType,
              salesPrice: double.tryParse(_salesPriceCtrl.text) ?? 0,
              purchasePrice: double.tryParse(_purchasePriceCtrl.text) ?? 0,
              quantityOnHand: double.tryParse(_qtyCtrl.text) ?? 0,
              sku: _skuCtrl.text.trim(),
              barcode: _barcodeCtrl.text.trim(),
              unit: _unitCtrl.text.trim(),
              incomeAccountId: _incomeAccountId,
              inventoryAssetAccountId: _inventoryAssetAccountId,
              cogsAccountId: _cogsAccountId,
              expenseAccountId: _expenseAccountId,
            );
            final accountError = draft.validateAccounts();
            if (accountError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(accountError),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.of(context).pop(draft);
          },
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Create & Add'),
        ),
      ],
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.label,
    required this.value,
    required this.accounts,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final String? value;
  final List<AccountModel> accounts;
  final ValueChanged<String?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final selected = accounts.any((account) => account.id == value)
        ? value
        : null;
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: accounts
          .map(
            (account) => DropdownMenuItem(
              value: account.id,
              child: Text(
                account.code.isEmpty
                    ? account.name
                    : '${account.code} - ${account.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: required
          ? (value) => value == null ? '$label required' : null
          : null,
    );
  }
}

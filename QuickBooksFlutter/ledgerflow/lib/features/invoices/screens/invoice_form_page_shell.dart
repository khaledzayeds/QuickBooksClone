import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_enums.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../transactions/printing/transaction_print_model.dart';
import '../../transactions/printing/transaction_print_service.dart';
import '../../transactions/widgets/transaction_models.dart';
import '../data/models/invoice_contracts.dart';
import '../data/models/sales_preview_contracts.dart';
import '../providers/invoices_state.dart';
import '../widgets/invoice_form_fields.dart';
import '../widgets/invoice_shell.dart';
import '../widgets/notes_edit_dialog.dart';

const _kInvoiceTerms = [
  'Due on receipt',
  'Net 7',
  'Net 14',
  'Net 30',
  'Net 45',
  'Net 60',
];

class InvoiceFormPageShell extends ConsumerStatefulWidget {
  const InvoiceFormPageShell({super.key, this.id});

  final String? id;

  @override
  ConsumerState<InvoiceFormPageShell> createState() =>
      _InvoiceFormPageShellState();
}

class _InvoiceFormPageShellState extends ConsumerState<InvoiceFormPageShell> {
  CustomerModel? _customer;
  CustomerSalesActivityModel? _activity;
  SalesPostingPreviewModel? _preview;
  InvoiceModel? _editingInvoice;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  String _terms = 'Net 14';
  bool _saving = false;
  bool _posting = false;
  bool _loadingActivity = false;
  bool _loadingExisting = false;
  Timer? _previewDebounce;

  // ── Notes & saved invoice id ──────────────────────────────────
  String? _savedInvoiceId;
  String _notes = '';

  bool get _isEdit => widget.id != null && widget.id!.isNotEmpty;

  final _numberCtrl = TextEditingController(text: 'AUTO');
  final _dateCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _lines = List.generate(5, (_) => TransactionLineEntry());

  @override
  void initState() {
    super.initState();
    _syncDateControllers();
    if (_isEdit) Future.microtask(_loadExistingInvoice);
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _numberCtrl.dispose();
    _dateCtrl.dispose();
    _dueDateCtrl.dispose();
    _memoCtrl.dispose();
    _customerCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  String _fmtDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  void _syncDateControllers() {
    _dateCtrl.text = _fmtDate(_invoiceDate);
    _dueDateCtrl.text = _fmtDate(_dueDate);
  }

  void _resetForm({bool showSavedMessage = false}) {
    _previewDebounce?.cancel();
    for (final line in _lines) {
      line.dispose();
    }
    setState(() {
      _customer = null;
      _activity = null;
      _preview = null;
      _editingInvoice = null;
      _savedInvoiceId = null;
      _notes = '';
      _invoiceDate = DateTime.now();
      _dueDate = DateTime.now().add(const Duration(days: 14));
      _terms = 'Net 14';
      _saving = false;
      _posting = false;
      _loadingActivity = false;
      _numberCtrl.text = 'AUTO';
      _customerCtrl.clear();
      _memoCtrl.clear();
      _lines
        ..clear()
        ..addAll(List.generate(5, (_) => TransactionLineEntry()));
      _syncDateControllers();
    });

    if (showSavedMessage && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved. Ready for a new invoice.')),
      );
    }
  }

  void _handleClearOrNew() {
    if (_isEdit) {
      context.go(AppRoutes.invoiceNew);
      return;
    }
    _resetForm();
  }

  Future<void> _saveAndNew() async {
    await _saveWithMode(_saveModeForDraft(), resetAfterSave: true);
  }

  double get _localSubtotal => _lines.fold(0, (sum, line) => sum + line.amount);

  TransactionTotalsUiModel get _totals => TransactionTotalsUiModel(
    subtotal: _preview?.subtotal ?? _editingInvoice?.subtotal ?? _localSubtotal,
    discountTotal:
        _preview?.discountTotal ?? _editingInvoice?.discountAmount ?? 0,
    taxTotal: _preview?.taxTotal ?? _editingInvoice?.taxAmount ?? 0,
    total: _preview?.total ?? _editingInvoice?.totalAmount ?? _localSubtotal,
    paid: _preview?.paidAmount ?? _editingInvoice?.paidAmount ?? 0,
    balanceDue:
        _preview?.balanceDue ?? _editingInvoice?.balanceDue ?? _localSubtotal,
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
          icon: Icons.receipt_long_outlined,
        ),
      if (_customer != null)
        TransactionContextMetric(
          label: 'Credits',
          value:
              '${fmt.format(_activity?.creditBalance ?? _customer!.creditBalance)} $currency',
          icon: Icons.credit_score_outlined,
        ),
      TransactionContextMetric(
        label: _isEdit ? 'Editing invoice' : 'Current invoice',
        value: '${fmt.format(_totals.total)} ${_totals.currency}',
        icon: Icons.description_outlined,
      ),
      if (_preview != null && _preview!.taxTotal > 0)
        TransactionContextMetric(
          label: 'Tax',
          value: '${fmt.format(_preview!.taxTotal)} ${_totals.currency}',
          icon: Icons.percent_outlined,
        ),
    ];
  }

  List<TransactionContextActivity> get _activities {
    final activity = _activity;
    if (activity == null) return const [];
    final rows = <TransactionContextActivity>[];
    rows.addAll(
      activity.recentInvoices.map(
        (invoice) => TransactionContextActivity(
          title: 'Invoice ${invoice.number}',
          subtitle: _fmtDate(invoice.date),
          amount:
              '${invoice.balanceDue.toStringAsFixed(2)} ${activity.currency}',
          status: 'Balance',
        ),
      ),
    );
    rows.addAll(
      activity.recentSalesReceipts.map(
        (receipt) => TransactionContextActivity(
          title: 'Receipt ${receipt.number}',
          subtitle: _fmtDate(receipt.date),
          amount:
              '${receipt.totalAmount.toStringAsFixed(2)} ${activity.currency}',
          status: 'Paid',
        ),
      ),
    );
    rows.addAll(
      activity.recentPayments.map(
        (payment) => TransactionContextActivity(
          title: 'Payment ${payment.number}',
          subtitle:
              '${_fmtDate(payment.paymentDate)} • ${payment.paymentMethod}',
          amount: '${payment.amount.toStringAsFixed(2)} ${activity.currency}',
          status: 'Payment',
        ),
      ),
    );
    return rows.take(8).toList();
  }

  String? get _warning {
    if (_customer == null) return 'No customer selected yet.';
    final warnings = <String>[...?_activity?.warnings, ...?_preview?.warnings];
    return warnings.isEmpty ? null : warnings.take(4).join('\n');
  }

  int _saveModeForDraft() => 1;
  int _saveModeForPost() => 2;

  Future<void> _loadExistingInvoice() async {
    final id = widget.id;
    if (id == null || id.isEmpty) return;
    setState(() => _loadingExisting = true);
    final result = await ref.read(invoicesRepoProvider).getById(id);
    if (!mounted) return;
    setState(() => _loadingExisting = false);
    result.when(
      success: (invoice) async {
        if (!invoice.isDraft) {
          _showError('Only draft invoices can be edited.');
          context.go('/sales/invoices/${invoice.id}');
          return;
        }
        for (final line in _lines) {
          line.dispose();
        }
        final loadedLines = invoice.lines.map((line) {
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
          _editingInvoice = invoice;
          _savedInvoiceId = invoice.id;
          _invoiceDate = invoice.invoiceDate;
          _dueDate = invoice.dueDate;
          _numberCtrl.text = invoice.invoiceNumber;
          _customer = CustomerModel(
            id: invoice.customerId,
            displayName: invoice.customerName,
            isActive: true,
            balance: invoice.balanceDue,
            creditBalance: invoice.creditAppliedAmount,
          );
          _customerCtrl.text = invoice.customerName;
          _lines
            ..clear()
            ..addAll(
              loadedLines.isEmpty ? [TransactionLineEntry()] : loadedLines,
            );
          _preview = null;
          _syncDateControllers();
        });
        await _loadCustomerActivity(invoice.customerId);
      },
      failure: (error) => _showError(error.message),
    );
  }

  Future<void> _loadCustomerActivity(String customerId) async {
    setState(() => _loadingActivity = true);
    final result = await ref
        .read(invoicesRepoProvider)
        .getCustomerActivity(customerId, limit: 5);
    if (!mounted) return;
    setState(() => _loadingActivity = false);
    result.when(
      success: (activity) => setState(() => _activity = activity),
      failure: (error) => _showError(error.message),
    );
  }

  Future<void> _runPreview() async {
    if (_customer == null || _validLines().isEmpty) return;
    final dto = PreviewInvoiceDto(
      customerId: _customer!.id,
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
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
    final result = await ref.read(invoicesRepoProvider).preview(dto);
    if (!mounted) return;
    result.when(
      success: (preview) => setState(() {
        _preview = preview;
        _editingInvoice = null;
      }),
      failure: (_) {},
    );
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 550), _runPreview);
  }

  Future<void> _saveWithMode(int saveMode, {bool resetAfterSave = false}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_customer == null) {
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

    final lines = validLines
        .map(
          (line) => CreateInvoiceLineDto(
            itemId: line.itemId!,
            description: line.descCtrl.text.trim().isEmpty
                ? line.itemName
                : line.descCtrl.text.trim(),
            quantity: line.qty,
            unitPrice: line.rate,
          ),
        )
        .toList();

    final isPosting = saveMode == _saveModeForPost();
    setState(() {
      _saving = !isPosting;
      _posting = isPosting;
    });

    try {
      if (_isEdit) {
        final dto = UpdateInvoiceDto(
          customerId: _customer!.id,
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          lines: lines,
        );
        final result = await ref
            .read(invoicesRepoProvider)
            .update(widget.id!, dto);
        if (!mounted) return;
        result.when(
          success: (updated) {
            ref.read(invoicesStateProvider.notifier).refresh();
            ref.invalidate(invoiceDetailsStateProvider(updated.id));
            if (resetAfterSave) {
              context.go(AppRoutes.invoiceNew);
            } else {
              context.go('/sales/invoices/${updated.id}');
            }
          },
          failure: (error) => _showError(error.message),
        );
        return;
      }

      final dto = CreateInvoiceDto(
        customerId: _customer!.id,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        saveMode: saveMode,
        lines: lines,
      );
      final result = await ref.read(invoicesRepoProvider).create(dto);
      if (!mounted) return;
      result.when(
        success: (invoice) {
          ref.read(invoicesStateProvider.notifier).refresh();
          if (resetAfterSave) {
            _resetForm(showSavedMessage: true);
          } else {
            setState(() => _savedInvoiceId = invoice.id);
            context.go('/sales/invoices/${invoice.id}');
          }
        },
        failure: (error) => _showError(error.message),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _posting = false;
        });
      }
    }
  }

  Future<void> _pickInvoiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _invoiceDate = picked;
      if (_dueDate.isBefore(_invoiceDate))
        _dueDate = _invoiceDate.add(const Duration(days: 14));
      _preview = null;
      _editingInvoice = null;
      _syncDateControllers();
    });
    _schedulePreview();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dueDate = picked;
      _preview = null;
      _editingInvoice = null;
      _syncDateControllers();
    });
    _schedulePreview();
  }

  void _addLine() {
    setState(() {
      _preview = null;
      _editingInvoice = null;
      _lines.add(TransactionLineEntry());
    });
    _schedulePreview();
  }

  Future<void> _handlePrint() async {
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
      documentTitle: 'Invoice',
      documentNumber: _numberCtrl.text.trim().isEmpty
          ? 'Preview'
          : _numberCtrl.text.trim(),
      documentDate: _invoiceDate,
      dueDate: _dueDate,
      partyLabel: 'Customer',
      partyName: _customer!.displayName,
      reference: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      lines: validLines
          .map(
            (line) => TransactionPrintLine(
              itemName: line.itemName.trim().isEmpty
                  ? 'Item'
                  : line.itemName.trim(),
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

  void _handleVoid() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Void is available from saved invoice details.'),
      ),
    );
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

  void _goBack() {
    if (_isEdit && widget.id != null) {
      context.go('/sales/invoices/${widget.id}');
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.invoices);
    }
  }

  // ── Notes dialog ──────────────────────────────────────────────
  Future<void> _openNotesDialog() async {
    final invoiceId =
        _savedInvoiceId ?? (widget.id?.isNotEmpty == true ? widget.id : null);
    if (invoiceId == null || invoiceId.trim().isEmpty) {
      _showError('Save the invoice before adding notes.');
      return;
    }
    try {
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '/api/invoices/$invoiceId/notes',
      );
      final notes = response.data?['notes']?.toString() ?? _notes;
      if (!mounted) return;
      setState(() => _notes = notes);
    } catch (_) {}
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => NotesEditDialog(
        initialNotes: _notes,
        onSave: (newNotes) async {
          final response = await ApiClient.instance.post<Map<String, dynamic>>(
            '/api/invoices/$invoiceId/notes',
            data: {'notes': newNotes},
          );
          final saved = response.data?['notes']?.toString() ?? newNotes;
          if (mounted) setState(() => _notes = saved);
        },
      ),
    );
  }

  // ── View All customer transactions ────────────────────────────
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
    if (_loadingExisting)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final l10n = AppLocalizations.of(context)!;
    final customers = ref
        .watch(customersProvider)
        .maybeWhen(
          data: (items) =>
              items.where((customer) => customer.isActive).toList(),
          orElse: () => const <CustomerModel>[],
        );

    return InvoiceShell(
      customerField: InvoiceFormField(
        label: l10n.customer,
        required: true,
        child: InvoiceCustomerField(
          controller: _customerCtrl,
          customers: customers,
          selected: _customer,
          onSelected: (customer) {
            setState(() {
              _customer = customer;
              _customerCtrl.text = customer.displayName;
              _activity = null;
              _preview = null;
              _editingInvoice = null;
            });
            _loadCustomerActivity(customer.id);
            _schedulePreview();
          },
          onCleared: () => setState(() {
            _customer = null;
            _customerCtrl.clear();
            _activity = null;
            _preview = null;
            _editingInvoice = null;
          }),
        ),
      ),
      invoiceNumberField: InvoiceFormField(
        label: 'Invoice #',
        child: InvoiceReadonlyTextField(controller: _numberCtrl, hint: 'AUTO'),
      ),
      invoiceDateField: InvoiceFormField(
        label: 'Invoice Date',
        child: InvoiceReadonlyTextField(
          controller: _dateCtrl,
          hint: 'dd/mm/yyyy',
          suffixIcon: Icons.calendar_today_outlined,
          onTap: _pickInvoiceDate,
        ),
      ),
      dueDateField: InvoiceFormField(
        label: l10n.dueDate,
        child: InvoiceReadonlyTextField(
          controller: _dueDateCtrl,
          hint: 'dd/mm/yyyy',
          suffixIcon: Icons.event_available_outlined,
          onTap: _pickDueDate,
        ),
      ),
      billingTermsField: InvoiceFormField(
        label: 'Terms',
        child: InvoiceTermsField(
          value: _terms,
          terms: _kInvoiceTerms,
          onChanged: (terms) {
            setState(() => _terms = terms);
          },
        ),
      ),
      memoField: InvoiceFormField(
        label: 'Memo / Reference',
        child: InvoiceMemoField(
          controller: _memoCtrl,
          onChanged: (_) => setState(() {}),
        ),
      ),
      lines: _lines,
      totals: _totals,
      customer: _customer,
      metrics: _metrics,
      activities: _activities,
      loadingActivity: _loadingActivity,
      warning: _warning,
      memoText: _memoCtrl.text,
      saving: _saving,
      posting: _posting,
      isEdit: _isEdit,
      onAddLine: _addLine,
      onLinesChanged: () {
        setState(() {
          _preview = null;
          _editingInvoice = null;
        });
        _schedulePreview();
      },
      onSaveDraft: () => _saveWithMode(_saveModeForDraft()),
      onSave: () => _saveWithMode(_saveModeForDraft()),
      onSaveAndNew: _saveAndNew,
      onPost: () => _saveWithMode(_saveModeForPost()),
      onPrint: _handlePrint,
      onVoid: _handleVoid,
      onClear: _handleClearOrNew,
      onClose: _goBack,
      onViewAll: _customer == null ? null : _openCustomerHistory,
      onEditNotes: _openNotesDialog,
    );
  }
}

// sales_receipt_form_page_redesign.dart
// Professional QuickBooks-style Sales Receipt form.
// Layout: header fields → line table → totals footer | sidebar.
//
// Added on top of last commit:
//   • F2  = Save & New  (keyboard shortcut)
//   • F4  = Save & Close
//   • Ctrl+P = Print
//   • Clear button in AppBar
//   • Print icon in AppBar
//   • 5 default blank rows (instead of 1)
//   • Post-save dialog with Print / New / Close actions

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
import '../../transactions/widgets/transaction_context_sidebar.dart';
import '../../transactions/widgets/transaction_models.dart';
import '../../transactions/widgets/transaction_totals_footer.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../providers/sales_receipts_state.dart';

const _kPaymentMethods = ['Cash', 'Card', 'Bank Transfer', 'Check', 'Other'];

// ─────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────

class SalesReceiptFormPageRedesign extends ConsumerStatefulWidget {
  const SalesReceiptFormPageRedesign({super.key});

  @override
  ConsumerState<SalesReceiptFormPageRedesign> createState() =>
      _SalesReceiptFormPageRedesignState();
}

class _SalesReceiptFormPageRedesignState
    extends ConsumerState<SalesReceiptFormPageRedesign> {
  // ── State ──────────────────────────────────────────────
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

  // ── Controllers ───────────────────────────────────────
  final _numberCtrl = TextEditingController(text: 'AUTO');
  final _dateCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();

  // 5 blank rows — feels ready, not empty (like QuickBooks)
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
    for (final l in _lines) l.dispose();
    super.dispose();
  }

  // ── Derived ───────────────────────────────────────────
  String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  double get _localSubtotal => _lines.fold(0, (s, l) => s + l.amount);

  TransactionTotalsUiModel get _totals => TransactionTotalsUiModel(
    subtotal: _preview?.subtotal ?? _localSubtotal,
    discountTotal: _preview?.discountTotal ?? 0,
    taxTotal: _preview?.taxTotal ?? 0,
    total: _preview?.total ?? _localSubtotal,
    paid: _preview?.paidAmount ?? _localSubtotal,
    balanceDue: _preview?.balanceDue ?? 0,
    currency: _activity?.currency ?? _customer?.currency ?? 'EGP',
  );

  List<TransactionLineEntry> _validLines() => _lines
      .where((l) => l.itemId != null && l.qty > 0 && l.rate >= 0)
      .toList();

  List<TransactionContextMetric> get _metrics {
    final cur = _activity?.currency ?? _customer?.currency ?? 'EGP';
    final fmt = NumberFormat('#,##0.00');
    return [
      if (_customer != null)
        TransactionContextMetric(
          label: 'Open balance',
          value:
              '${fmt.format(_activity?.openBalance ?? _customer!.balance)} $cur',
          icon: Icons.account_balance_wallet_outlined,
        ),
      if (_customer != null)
        TransactionContextMetric(
          label: 'Credits available',
          value:
              '${fmt.format(_activity?.creditBalance ?? _customer!.creditBalance)} $cur',
          icon: Icons.credit_score_outlined,
        ),
      TransactionContextMetric(
        label: 'Receipt total',
        value: '${fmt.format(_totals.total)} $cur',
        icon: Icons.receipt_long_outlined,
      ),
      if (_preview != null && _preview!.taxTotal > 0)
        TransactionContextMetric(
          label: 'Tax',
          value: '${fmt.format(_preview!.taxTotal)} $cur',
          icon: Icons.percent_outlined,
        ),
    ];
  }

  List<TransactionContextActivity> get _activities {
    final a = _activity;
    if (a == null) return const [];
    return [
      ...a.recentSalesReceipts.map(
        (x) => TransactionContextActivity(
          title: 'Receipt ${x.number}',
          subtitle: _fmtDate(x.date),
          amount:
              '${NumberFormat('#,##0.00').format(x.totalAmount)} ${a.currency}',
          status: 'Receipt',
        ),
      ),
      ...a.recentInvoices.map(
        (x) => TransactionContextActivity(
          title: 'Invoice ${x.number}',
          subtitle: _fmtDate(x.date),
          amount:
              '${NumberFormat('#,##0.00').format(x.balanceDue)} ${a.currency}',
          status: 'Invoice',
        ),
      ),
      ...a.recentPayments.map(
        (x) => TransactionContextActivity(
          title: 'Payment ${x.number}',
          subtitle: '${_fmtDate(x.paymentDate)} \u2022 ${x.paymentMethod}',
          amount: '${NumberFormat('#,##0.00').format(x.amount)} ${a.currency}',
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

  // ── API ───────────────────────────────────────────────
  Future<void> _loadCustomerActivity(String id) async {
    setState(() => _loadingActivity = true);
    final result = await ref
        .read(invoicesRepoProvider)
        .getCustomerActivity(id, limit: 5);
    if (!mounted) return;
    setState(() => _loadingActivity = false);
    result.when(
      success: (data) => setState(() => _activity = data),
      failure: (e) => _showError(e.message),
    );
  }

  Future<void> _runPreview() async {
    if (_customer == null || _depositAccount == null || _validLines().isEmpty)
      return;
    setState(() => _previewing = true);
    final dto = PreviewSalesReceiptDto(
      customerId: _customer!.id,
      receiptDate: _receiptDate,
      depositAccountId: _depositAccount!.id,
      paymentMethod: _paymentMethod,
      lines: _validLines()
          .map(
            (l) => PreviewSalesLineDto(
              itemId: l.itemId!,
              description: l.descCtrl.text.trim().isEmpty
                  ? l.itemName
                  : l.descCtrl.text.trim(),
              quantity: l.qty,
              unitPrice: l.rate,
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

  // ── Save ──────────────────────────────────────────────
  // Returns saved receipt number, or null on error.
  Future<String?> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_customer == null) {
      _showError(l10n.selectCustomerFirst);
      return null;
    }
    if (_depositAccount == null) {
      _showError(l10n.selectDepositAccountFirst);
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
            (l) => CreateSalesReceiptLineDto(
              itemId: l.itemId!,
              description: l.descCtrl.text.trim().isEmpty
                  ? l.itemName
                  : l.descCtrl.text.trim(),
              quantity: l.qty,
              unitPrice: l.rate,
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
        failure: (e) => _showError(e.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    return savedNumber;
  }

  Future<void> _saveAndClose() async {
    final num = await _save();
    if (num != null && mounted) _showPostSaveDialog(num, closeAfter: true);
  }

  Future<void> _saveAndNew() async {
    final num = await _save();
    if (num != null && mounted) {
      _reset();
      _showPostSaveDialog(num, closeAfter: false);
    }
  }

  void _showPostSaveDialog(String docNumber, {required bool closeAfter}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PostSaveDialog(
        docNumber: docNumber,
        onPrint: _handlePrint,
        onNew: () {
          Navigator.of(ctx).pop();
          if (!closeAfter) _reset();
        },
        onClose: () {
          Navigator.of(ctx).pop();
          if (closeAfter) _goBack();
        },
      ),
    );
  }

  void _handlePrint() {
    // TODO: connect to print/preview service
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Print coming soon…')));
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
      for (final l in _lines) l.dispose();
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

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _goBack() =>
      context.canPop() ? context.pop() : context.go('/sales/receipts');

  // ── Keyboard shortcuts ────────────────────────────────
  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final isCtrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (event.logicalKey == LogicalKeyboardKey.f2) {
      if (!_saving) _saveAndNew();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.f4) {
      if (!_saving) _saveAndClose();
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyP) {
      _handlePrint();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _goBack();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final customers = ref
        .watch(customersProvider)
        .maybeWhen(
          data: (items) => items.where((c) => c.isActive).toList(),
          orElse: () => const <CustomerModel>[],
        );
    final accounts = ref
        .watch(accountsProvider)
        .maybeWhen(
          data: (items) => items
              .where(
                (a) =>
                    a.isActive &&
                    (a.accountType == AccountType.bank ||
                        a.accountType == AccountType.otherCurrentAsset),
              )
              .toList(),
          orElse: () => const <AccountModel>[],
        );

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: _buildAppBar(l10n, theme, cs),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final showSidebar = constraints.maxWidth >= 1100;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildMainArea(context, l10n, customers, accounts),
                ),
                if (showSidebar) ...[
                  VerticalDivider(width: 1, color: cs.outlineVariant),
                  TransactionContextSidebar(
                    title: _customer?.displayName ?? '',
                    subtitle:
                        _customer?.companyName ?? _customer?.primaryContact,
                    initials: _customer?.initials,
                    emptyTitle: 'Select a customer',
                    emptyMessage:
                        'Choose a customer to see balances, credits, and recent activity.',
                    metrics: _metrics,
                    activities: _activities,
                    warning: _warning,
                    isLoading: _loadingActivity,
                    totals: _totals,
                    notes: _referenceCtrl.text.trim().isEmpty
                        ? null
                        : 'Ref: ${_referenceCtrl.text.trim()}',
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return AppBar(
      toolbarHeight: 48,
      backgroundColor: cs.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: 'Back (Esc)',
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.newSalesReceipt,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Sales / Receipts / New',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Print
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: _handlePrint,
          icon: const Icon(Icons.print_outlined, size: 20),
          tooltip: 'Print (Ctrl+P)',
        ),
        const SizedBox(width: 4),
        // Clear
        TextButton.icon(
          onPressed: _saving ? null : _reset,
          icon: const Icon(Icons.refresh_outlined, size: 16),
          label: const Text('Clear'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Save & New  F2
        OutlinedButton.icon(
          onPressed: _saving ? null : _saveAndNew,
          icon: const Icon(Icons.add_circle_outline, size: 16),
          label: const Text('Save & New  F2'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            side: BorderSide(color: cs.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Save & Close  F4
        FilledButton.icon(
          onPressed: _saving ? null : _saveAndClose,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined, size: 16),
          label: const Text('Save & Close  F4'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: _goBack,
          icon: const Icon(Icons.close, size: 20),
          tooltip: 'Close (Esc)',
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: cs.outlineVariant),
      ),
    );
  }

  // ── Main area ─────────────────────────────────────────
  Widget _buildMainArea(
    BuildContext context,
    AppLocalizations l10n,
    List<CustomerModel> customers,
    List<AccountModel> accounts,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        // Header fields card
        Container(
          color: cs.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Row 1: Receipt # | Date | Reference
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: _FormFieldWrapper(
                      label: '${l10n.salesReceipt} #',
                      child: TextFormField(
                        controller: _numberCtrl,
                        readOnly: true,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        decoration: _inputDeco(cs, hint: 'AUTO'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: _FormFieldWrapper(
                      label: l10n.receiptDate,
                      child: TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        onTap: _pickDate,
                        style: theme.textTheme.bodySmall,
                        decoration: _inputDeco(
                          cs,
                          hint: 'dd/mm/yyyy',
                          suffixIcon: Icons.calendar_today_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormFieldWrapper(
                      label: 'Reference / Memo',
                      child: TextFormField(
                        controller: _referenceCtrl,
                        style: theme.textTheme.bodySmall,
                        decoration: _inputDeco(cs, hint: 'Optional'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Row 2: Customer | Deposit Account | Payment Method
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _FormFieldWrapper(
                      label: l10n.customer,
                      required: true,
                      child: _CustomerTypeahead(
                        controller: _customerCtrl,
                        customers: customers,
                        selected: _customer,
                        onSelected: (c) {
                          setState(() {
                            _customer = c;
                            _customerCtrl.text = c.displayName;
                            _activity = null;
                            _preview = null;
                          });
                          _loadCustomerActivity(c.id);
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _FormFieldWrapper(
                      label: l10n.depositAccount,
                      required: true,
                      child: _AccountTypeahead(
                        controller: _depositCtrl,
                        accounts: accounts,
                        selected: _depositAccount,
                        hint: l10n.selectDepositAccount,
                        onSelected: (a) {
                          setState(() {
                            _depositAccount = a;
                            _depositCtrl.text = a.name;
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
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: _FormFieldWrapper(
                      label: l10n.paymentMethod,
                      child: DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        isDense: true,
                        decoration: _inputDeco(cs),
                        style: theme.textTheme.bodySmall,
                        items: _kPaymentMethods
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _paymentMethod = v;
                            _preview = null;
                          });
                          _schedulePreview();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),

        // Add-line toolbar
        Container(
          color: cs.surfaceContainerLowest,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Row(
            children: [
              Text(
                'Products and services',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\u2022 Tab through cells  \u2022  Enter adds a new line',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add line'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Line table + totals
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TransactionLineTable(
                    lines: _lines,
                    priceMode: TransactionLinePriceMode.sales,
                    fillWidth: true,
                    compact: true,
                    showAddLineFooter: false,
                    onChanged: () {
                      setState(() => _preview = null);
                      _schedulePreview();
                    },
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(top: BorderSide(color: cs.outlineVariant)),
                ),
                child: TransactionTotalsFooter(totals: _totals),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addLine() {
    setState(() {
      _preview = null;
      _lines.add(TransactionLineEntry());
    });
    _schedulePreview();
  }

  // ── Input decoration ──────────────────────────────────
  InputDecoration _inputDeco(
    ColorScheme cs, {
    String? hint,
    IconData? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
    filled: true,
    fillColor: cs.surface,
    suffixIcon: suffixIcon != null
        ? Icon(suffixIcon, size: 16, color: cs.onSurfaceVariant)
        : null,
  );
}

// ─────────────────────────────────────────────────────────
// Post-Save Dialog
// ─────────────────────────────────────────────────────────

class _PostSaveDialog extends StatelessWidget {
  const _PostSaveDialog({
    required this.docNumber,
    required this.onNew,
    required this.onClose,
    required this.onPrint,
  });

  final String docNumber;
  final VoidCallback onNew;
  final VoidCallback onClose;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 340,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 32,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sales Receipt Saved!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              // Doc number chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tag, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      docNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Print
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPrint();
                  },
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Print'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onNew,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New  F2'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _FormFieldWrapper
// ─────────────────────────────────────────────────────────

class _FormFieldWrapper extends StatelessWidget {
  const _FormFieldWrapper({
    required this.label,
    required this.child,
    this.required = false,
  });
  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: cs.error),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// _CustomerTypeahead
// ─────────────────────────────────────────────────────────

class _CustomerTypeahead extends StatelessWidget {
  const _CustomerTypeahead({
    required this.controller,
    required this.customers,
    required this.selected,
    required this.onSelected,
    required this.onCleared,
  });
  final TextEditingController controller;
  final List<CustomerModel> customers;
  final CustomerModel? selected;
  final void Function(CustomerModel) onSelected;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return TypeAheadField<CustomerModel>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        style: theme.textTheme.bodySmall,
        decoration: InputDecoration(
          hintText: 'Search customers...',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          prefixIcon: const Icon(Icons.person_search_outlined, size: 16),
          suffixIcon: selected != null
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: onCleared,
                  icon: const Icon(Icons.close, size: 16),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
          filled: true,
          fillColor: cs.surface,
        ),
      ),
      suggestionsCallback: (pattern) {
        final q = pattern.toLowerCase().trim();
        return customers
            .where(
              (c) =>
                  q.isEmpty ||
                  c.displayName.toLowerCase().contains(q) ||
                  (c.companyName?.toLowerCase().contains(q) ?? false) ||
                  (c.email?.toLowerCase().contains(q) ?? false),
            )
            .take(12)
            .toList();
      },
      itemBuilder: (context, c) => ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: cs.primaryContainer,
          child: Text(
            c.initials,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          c.displayName,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: c.companyName != null
            ? Text(c.companyName!, style: theme.textTheme.labelSmall)
            : null,
      ),
      onSuggestionSelected: onSelected,
      noItemsFoundBuilder: (context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No customers found',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// _AccountTypeahead
// ─────────────────────────────────────────────────────────

class _AccountTypeahead extends StatelessWidget {
  const _AccountTypeahead({
    required this.controller,
    required this.accounts,
    required this.selected,
    required this.hint,
    required this.onSelected,
    required this.onCleared,
  });
  final TextEditingController controller;
  final List<AccountModel> accounts;
  final AccountModel? selected;
  final String hint;
  final void Function(AccountModel) onSelected;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return TypeAheadField<AccountModel>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        style: theme.textTheme.bodySmall,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          prefixIcon: const Icon(Icons.account_balance_outlined, size: 16),
          suffixIcon: selected != null
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: onCleared,
                  icon: const Icon(Icons.close, size: 16),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
          filled: true,
          fillColor: cs.surface,
        ),
      ),
      suggestionsCallback: (pattern) {
        final q = pattern.toLowerCase().trim();
        return accounts
            .where(
              (a) =>
                  q.isEmpty ||
                  a.name.toLowerCase().contains(q) ||
                  a.code.toLowerCase().contains(q),
            )
            .take(12)
            .toList();
      },
      itemBuilder: (context, a) => ListTile(
        dense: true,
        leading: Icon(
          Icons.account_balance_outlined,
          size: 18,
          color: cs.primary,
        ),
        title: Text(
          a.name,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: a.code.isNotEmpty
            ? Text(a.code, style: theme.textTheme.labelSmall)
            : null,
      ),
      onSuggestionSelected: onSelected,
      noItemsFoundBuilder: (context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No accounts found',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

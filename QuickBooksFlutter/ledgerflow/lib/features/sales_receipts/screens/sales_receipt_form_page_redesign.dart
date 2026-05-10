// sales_receipt_form_page_redesign.dart
//
// Uses TransactionFormShell — this file now contains ONLY:
//   - Business logic (save, preview, customer activity)
//   - Header fields (Receipt#, Date, Reference, Customer, DepositAccount, PaymentMethod)
//
// Everything else (AppBar, layout, table, sidebar, totals, F2/F4, print dialog)
// is handled by TransactionFormShell.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../core/constants/api_enums.dart';
import '../../../core/widgets/transaction_form_shell.dart';
import '../../../core/widgets/transaction_line_table_v2.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../invoices/data/models/sales_preview_contracts.dart';
import '../../invoices/providers/invoices_state.dart';

import '../../transactions/widgets/transaction_models.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../providers/sales_receipts_state.dart';

const _kPaymentMethods = ['Cash', 'Card', 'Bank Transfer', 'Check', 'Other'];

class SalesReceiptFormPageRedesign extends ConsumerStatefulWidget {
  const SalesReceiptFormPageRedesign({super.key});

  @override
  ConsumerState<SalesReceiptFormPageRedesign> createState() =>
      _SalesReceiptFormState();
}

class _SalesReceiptFormState
    extends ConsumerState<SalesReceiptFormPageRedesign> {
  // ── Business state ─────────────────────────────────────────────────────────
  CustomerModel? _customer;
  CustomerSalesActivityModel? _activity;
  SalesPostingPreviewModel? _preview;
  AccountModel? _depositAccount;
  DateTime _receiptDate = DateTime.now();
  String _paymentMethod = 'Cash';
  bool _saving = false;
  bool _loadingActivity = false;
  Timer? _previewDebounce;

  // ── Form controllers ───────────────────────────────────────────────────────
  final _numberCtrl = TextEditingController(text: 'AUTO');
  final _dateCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _lines = <TransactionLineEntry>[];

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = _fmt(_receiptDate);
    // Start with 5 blank rows — feels ready, not empty
    for (var i = 0; i < 5; i++) {
      _lines.add(TransactionLineEntry());
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
    for (final l in _lines) l.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

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

  List<TransactionLineEntry> get _validLines => _lines
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
    ];
  }

  List<TransactionContextActivity> get _activities {
    final a = _activity;
    if (a == null) return const [];
    return [
      ...a.recentSalesReceipts.map(
        (x) => TransactionContextActivity(
          title: 'Receipt ${x.number}',
          subtitle: _fmt(x.date),
          amount:
              '${NumberFormat('#,##0.00').format(x.totalAmount)} ${a.currency}',
          status: 'Receipt',
        ),
      ),
      ...a.recentInvoices.map(
        (x) => TransactionContextActivity(
          title: 'Invoice ${x.number}',
          subtitle: _fmt(x.date),
          amount:
              '${NumberFormat('#,##0.00').format(x.balanceDue)} ${a.currency}',
          status: 'Invoice',
        ),
      ),
    ];
  }

  String? get _warning {
    if (_customer == null) return null;
    final w = <String>[
      ...?_activity?.warnings,
      ...?_preview?.warnings,
      if (_depositAccount == null) 'Select a deposit account.',
    ];
    return w.isEmpty ? null : w.join('\n');
  }

  // ── API calls ──────────────────────────────────────────────────────────────
  Future<void> _loadActivity(String id) async {
    setState(() => _loadingActivity = true);
    final r = await ref
        .read(invoicesRepoProvider)
        .getCustomerActivity(id, limit: 5);
    if (!mounted) return;
    setState(() => _loadingActivity = false);
    r.when(
      success: (d) => setState(() => _activity = d),
      failure: (e) => _err(e.message),
    );
  }

  Future<void> _runPreview() async {
    if (_customer == null || _depositAccount == null || _validLines.isEmpty)
      return;
    final dto = PreviewSalesReceiptDto(
      customerId: _customer!.id,
      receiptDate: _receiptDate,
      depositAccountId: _depositAccount!.id,
      paymentMethod: _paymentMethod,
      lines: _validLines
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
    final r = await ref.read(salesReceiptsRepoProvider).preview(dto);
    if (!mounted) return;
    r.when(success: (d) => setState(() => _preview = d), failure: (_) {});
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 550), _runPreview);
  }

  // Returns saved doc number or null on error
  Future<String?> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_customer == null) {
      _err(l10n.selectCustomerFirst);
      return null;
    }
    if (_depositAccount == null) {
      _err(l10n.selectDepositAccountFirst);
      return null;
    }
    if (_validLines.isEmpty) {
      _err('Add at least one valid line.');
      return null;
    }

    setState(() => _saving = true);
    final dto = CreateSalesReceiptDto(
      customerId: _customer!.id,
      receiptDate: _receiptDate,
      depositAccountId: _depositAccount!.id,
      paymentMethod: _paymentMethod,
      lines: _validLines
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
      final r = await ref.read(salesReceiptsRepoProvider).create(dto);
      if (!mounted) return null;
      r.when(
        success: (doc) {
          savedNumber = doc.number;
          ref.read(salesReceiptsStateProvider.notifier).refresh();
        },
        failure: (e) => _err(e.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    return savedNumber;
  }

  Future<String?> _saveAndClose() async => _save();

  Future<String?> _saveAndNew() async {
    final num = await _save();
    if (num != null) _reset();
    return num;
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
      _dateCtrl.text = _fmt(_receiptDate);
      _referenceCtrl.clear();
      _customerCtrl.clear();
      _depositCtrl.clear();
      for (final l in _lines) l.dispose();
      _lines.clear();
      for (var i = 0; i < 5; i++) _lines.add(TransactionLineEntry());
    });
  }

  void _err(String msg) {
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final customers = ref
        .watch(customersProvider)
        .maybeWhen(
          data: (d) => d.where((c) => c.isActive).toList(),
          orElse: () => const <CustomerModel>[],
        );
    final accounts = ref
        .watch(accountsProvider)
        .maybeWhen(
          data: (d) => d
              .where(
                (a) =>
                    a.isActive &&
                    (a.accountType == AccountType.bank ||
                        a.accountType == AccountType.otherCurrentAsset),
              )
              .toList(),
          orElse: () => const <AccountModel>[],
        );

    return TransactionFormShell(
      config: const TransactionFormConfig(
        kind: TransactionScreenKind.salesReceipt,
        title: 'New Sales Receipt',
        breadcrumb: 'Sales / Receipts / New',
        emptyPartyTitle: 'Select a customer',
        emptyPartyMessage:
            'Choose a customer to see balances, credits, and recent activity.',
        priceMode: TransactionLinePriceMode.sales,
      ),
      lines: _lines,
      totals: _totals,
      isSaving: _saving,
      onSaveAndClose: _saveAndClose,
      onSaveAndNew: _saveAndNew,
      onClear: _reset,
      onBack: _goBack,
      onLinesChanged: () => setState(() {
        _preview = null;
        _schedulePreview();
      }),
      // Sidebar
      partyTitle: _customer?.displayName ?? '',
      partySubtitle: _customer?.companyName ?? _customer?.primaryContact,
      partyInitials: _customer?.initials,
      metrics: _metrics,
      activities: _activities,
      warning: _warning,
      notes: _referenceCtrl.text.trim().isEmpty
          ? null
          : 'Ref: ${_referenceCtrl.text.trim()}',
      isPartyLoading: _loadingActivity,
      // Header fields — the only thing unique to this screen
      headerFields: _buildHeaderFields(context, customers, accounts),
    );
  }

  // ── Header fields ──────────────────────────────────────────────────────────
  Widget _buildHeaderFields(
    BuildContext context,
    List<CustomerModel> customers,
    List<AccountModel> accounts,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Row 1 — Receipt # | Date | Reference
        Row(
          children: [
            SizedBox(
              width: 130,
              child: _field(
                label: '${l10n.salesReceipt} #',
                child: TextFormField(
                  controller: _numberCtrl,
                  readOnly: true,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  decoration: _deco(cs, hint: 'AUTO'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 150,
              child: _field(
                label: l10n.receiptDate,
                child: TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  style: theme.textTheme.bodySmall,
                  decoration: _deco(
                    cs,
                    hint: 'dd/mm/yyyy',
                    suffix: Icons.calendar_today_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                label: 'Reference / Memo',
                child: TextFormField(
                  controller: _referenceCtrl,
                  style: theme.textTheme.bodySmall,
                  decoration: _deco(cs, hint: 'Optional'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2 — Customer | Deposit Account | Payment Method
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _field(
                label: l10n.customer,
                required: true,
                child: _CustomerTA(
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
                    _loadActivity(c.id);
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
              child: _field(
                label: l10n.depositAccount,
                required: true,
                child: _AccountTA(
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
              child: _field(
                label: l10n.paymentMethod,
                child: DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  isDense: true,
                  decoration: _deco(cs),
                  style: Theme.of(context).textTheme.bodySmall,
                  items: _kPaymentMethods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
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
    );
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _receiptDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (p == null || !mounted) return;
    setState(() {
      _receiptDate = p;
      _dateCtrl.text = _fmt(p);
      _preview = null;
    });
    _schedulePreview();
  }

  // ── Shared decoration helpers ──────────────────────────────────────────────
  Widget _field({
    required String label,
    required Widget child,
    bool required = false,
  }) {
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

  InputDecoration _deco(ColorScheme cs, {String? hint, IconData? suffix}) =>
      InputDecoration(
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
        suffixIcon: suffix != null
            ? Icon(suffix, size: 16, color: cs.onSurfaceVariant)
            : null,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer TypeAhead
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerTA extends StatelessWidget {
  const _CustomerTA({
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
      suggestionsCallback: (q) {
        final s = q.toLowerCase().trim();
        return customers
            .where(
              (c) =>
                  s.isEmpty ||
                  c.displayName.toLowerCase().contains(s) ||
                  (c.companyName?.toLowerCase().contains(s) ?? false) ||
                  (c.email?.toLowerCase().contains(s) ?? false),
            )
            .take(12)
            .toList();
      },
      itemBuilder: (_, c) => ListTile(
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
      noItemsFoundBuilder: (_) => const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No customers found',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account TypeAhead
// ─────────────────────────────────────────────────────────────────────────────

class _AccountTA extends StatelessWidget {
  const _AccountTA({
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
      suggestionsCallback: (q) {
        final s = q.toLowerCase().trim();
        return accounts
            .where(
              (a) =>
                  s.isEmpty ||
                  a.name.toLowerCase().contains(s) ||
                  (a.code?.toLowerCase().contains(s) ?? false),
            )
            .take(12)
            .toList();
      },
      itemBuilder: (_, a) => ListTile(
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
        subtitle: a.code != null
            ? Text(a.code!, style: theme.textTheme.labelSmall)
            : null,
      ),
      onSuggestionSelected: onSelected,
      noItemsFoundBuilder: (_) => const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No accounts found',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}

// estimate_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../../../core/widgets/qb/qb_transaction_line_grid.dart';
import '../../../core/widgets/qb/transaction_line_price_mode.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../data/models/estimate_model.dart';
import '../providers/estimates_provider.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
import '../../transactions/widgets/transaction_context_sidebar.dart';
import '../../transactions/widgets/transaction_models.dart';

class EstimateFormScreen extends ConsumerStatefulWidget {
  const EstimateFormScreen({super.key, this.id});

  final String? id;

  @override
  ConsumerState<EstimateFormScreen> createState() => _EstimateFormScreenState();
}

class _EstimateFormScreenState extends ConsumerState<EstimateFormScreen> {
  CustomerModel? _customer;
  EstimateModel? _editingEstimate;
  DateTime _estimateDate = DateTime.now();
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 30));
  final List<TransactionLineEntry> _lines = List.generate(
    5,
    (_) => TransactionLineEntry(),
  );
  bool _saving = false;
  bool _loadingExisting = false;

  bool get _isEdit => widget.id != null && widget.id!.isNotEmpty;
  double get _draftSubtotal => _lines.fold(0, (sum, line) => sum + line.amount);
  double get _total => _draftSubtotal > 0
      ? _draftSubtotal
      : (_editingEstimate?.totalAmount ?? _draftSubtotal);

  @override
  void initState() {
    super.initState();
    if (_isEdit) Future.microtask(_loadExistingOrder);
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingOrder() async {
    final id = widget.id;
    if (id == null || id.isEmpty) return;
    setState(() => _loadingExisting = true);
    try {
      final result = await ref.read(estimatesRepositoryProvider).getById(id);
      if (!mounted) return;
      result.when(
        success: (order) {
          setState(() {
            _editingEstimate = order;
            _customer = CustomerModel(
              id: order.customerId,
              displayName: order.customerName ?? 'Customer',
              isActive: true,
              balance: 0,
              creditBalance: 0,
            );
            _estimateDate = order.estimateDate;
            _expirationDate = order.expirationDate;
            for (final line in _lines) {
              line.dispose();
            }
            _lines
              ..clear()
              ..addAll(
                order.lines.isEmpty
                    ? List.generate(5, (_) => TransactionLineEntry())
                    : [
                        ...order.lines.map((line) {
                          final entry = TransactionLineEntry(
                            itemId: line.itemId,
                            itemName: line.description,
                            qty: line.quantity,
                            rate: line.unitPrice,
                          );
                          entry.descCtrl.text = line.description;
                          entry.qtyCtrl.text = line.quantity.toStringAsFixed(2);
                          entry.rateCtrl.text = line.unitPrice.toStringAsFixed(
                            2,
                          );
                          return entry;
                        }),
                        for (var i = order.lines.length; i < 5; i++)
                          TransactionLineEntry(),
                      ],
              );
          });
        },
        failure: (error) => _showError(error.message),
      );
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    if (_customer == null) {
      _showError(l10n.selectCustomerFirst);
      return;
    }

    final validLines = _lines
        .where((line) => line.itemId != null && line.qty > 0)
        .toList();
    if (validLines.isEmpty) {
      _showError(l10n.selectAtLeastOneLine);
      return;
    }

    final dto = CreateEstimateDto(
      customerId: _customer!.id,
      estimateDate: _estimateDate,
      expirationDate: _expirationDate,
      saveMode: 1,
      lines: validLines
          .map(
            (line) => CreateEstimateLineDto(
              itemId: line.itemId!,
              description: line.descCtrl.text,
              quantity: line.qty,
              unitPrice: line.rate,
            ),
          )
          .toList(),
    );

    setState(() => _saving = true);
    final result = await ref.read(estimatesProvider.notifier).create(dto);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        ref.read(estimatesProvider.notifier).refresh();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Estimate saved.')));
        context.go(AppRoutes.estimates);
      },
      failure: (error) => _showError(error.message),
    );
  }

  void _clear() {
    for (final line in _lines) {
      line.dispose();
    }
    setState(() {
      _customer = null;
      _editingEstimate = null;
      _estimateDate = DateTime.now();
      _expirationDate = DateTime.now().add(const Duration(days: 30));
      _lines
        ..clear()
        ..addAll(List.generate(5, (_) => TransactionLineEntry()));
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customers = ref
        .watch(customersProvider)
        .maybeWhen(
          data: (items) =>
              items.where((customer) => customer.isActive).toList(),
          orElse: () => const <CustomerModel>[],
        );

    if (_loadingExisting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return TransactionWorkspaceShell(
      workspaceName: 'Estimate workspace',
      saving: _saving,
      posting: false,
      isEdit: _isEdit,
      readOnly: false,
      onFind: () => context.go(AppRoutes.estimates),
      onPrevious: null, // TODO: Implement previous
      onNext: null, // TODO: Implement next
      onNew: () => context.go(AppRoutes.estimateNew),
      onSaveDraft: null, // TODO: Implement draft
      onSave: _saving ? null : _save,
      onClear: _clear,
      onPrint: null, // TODO: Implement print
      onEmail: null, // TODO: Implement email
      onClose: () => context.go(AppRoutes.estimates),
      formContent: Column(
        children: [
          _EstimateHeader(
            customers: customers,
            selectedCustomer: _customer,
            estimateDate: _estimateDate,
            expirationDate: _expirationDate,
            estimateNumber: _editingEstimate?.estimateNumber ?? 'AUTO',
            onCustomerChanged: (customer) =>
                setState(() => _customer = customer),
            onEstimateDateChanged: (date) =>
                setState(() => _estimateDate = date),
            onExpirationDateChanged: (date) =>
                setState(() => _expirationDate = date),
          ),
          _LinesHeader(
            onAddLine: () => setState(
              () => _lines.add(TransactionLineEntry()),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: QbTransactionLineGrid(
                lines: _lines,
                onChanged: () => setState(() {}),
                priceMode: TransactionLinePriceMode.sales,
                fillWidth: true,
                compact: true,
                showAddLineFooter: false,
              ),
            ),
          ),
          _EstimateFooter(
            l10n: l10n,
            total: _total,
            saving: _saving,
            onSave: _saving ? null : _save,
            onClear: _clear,
          ),
        ],
      ),
      contextPanel: _EstimateContextPanel(
        customer: _customer,
        estimate: _editingEstimate,
        total: _total,
        currency: l10n.egp,
        onViewAll: _customer == null
            ? null
            : () => context.go(AppRoutes.estimates),
      ),
    );
  }
}

class _EstimateHeader extends StatelessWidget {
  const _EstimateHeader({
    required this.customers,
    required this.selectedCustomer,
    required this.estimateDate,
    required this.expirationDate,
    required this.estimateNumber,
    required this.onCustomerChanged,
    required this.onEstimateDateChanged,
    required this.onExpirationDateChanged,
  });

  final List<CustomerModel> customers;
  final CustomerModel? selectedCustomer;
  final DateTime estimateDate;
  final DateTime expirationDate;
  final String estimateNumber;
  final ValueChanged<CustomerModel?> onCustomerChanged;
  final ValueChanged<DateTime> onEstimateDateChanged;
  final ValueChanged<DateTime> onExpirationDateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF264D5B),
              border: Border(bottom: BorderSide(color: Color(0xFF183642))),
            ),
            child: Row(
              children: [
                const _StripLabel('CUSTOMER:JOB'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: _InlineCustomerField(
                    customers: customers,
                    selected: selectedCustomer,
                    onSelected: onCustomerChanged,
                  ),
                ),
                const SizedBox(width: 16),
                const _StripLabel('TEMPLATE'),
                const SizedBox(width: 8),
                const Expanded(
                  flex: 3,
                  child: _StaticBox(text: 'Standard Estimate'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 110,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 260,
                    child: Text(
                      'Estimate',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF243E4A),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: Column(
                      children: [
                        _HorizontalField(
                          label: 'DATE',
                          child: _DateBox(
                            value: estimateDate,
                            onChanged: onEstimateDateChanged,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _HorizontalField(
                          label: 'ESTIMATE #',
                          child: _StaticBox(text: estimateNumber),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  SizedBox(
                    width: 240,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('EXPIRATION DATE'),
                        const SizedBox(height: 4),
                        _DateBox(
                          value: expirationDate,
                          onChanged: onExpirationDateChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineCustomerField extends StatelessWidget {
  const _InlineCustomerField({
    required this.customers,
    required this.selected,
    required this.onSelected,
  });

  final List<CustomerModel> customers;
  final CustomerModel? selected;
  final ValueChanged<CustomerModel?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<CustomerModel>(
      key: ValueKey(selected?.id ?? 'estimate-customer'),
      displayStringForOption: (customer) => customer.displayName,
      initialValue: TextEditingValue(text: selected?.displayName ?? ''),
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return customers.take(20);
        return customers
            .where(
              (customer) => customer.displayName.toLowerCase().contains(query),
            )
            .take(20);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return SizedBox(
          height: 30,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.search, size: 16),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              border: OutlineInputBorder(),
              hintText: 'Select a customer...',
            ),
          ),
        );
      },
    );
  }
}

class _LinesHeader extends StatelessWidget {
  const _LinesHeader({required this.onAddLine});

  final VoidCallback onAddLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFE9EFF2),
        border: Border(
          top: BorderSide(color: Color(0xFFB7C3CB)),
          bottom: BorderSide(color: Color(0xFFB7C3CB)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Products and Services',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF233F4C),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Tab moves across cells • Enter commits row',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF596B74),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onAddLine,
            icon: const Icon(Icons.add, size: 15),
            label: const Text('Add Line'),
          ),
        ],
      ),
    );
  }
}

class _EstimateFooter extends StatelessWidget {
  const _EstimateFooter({
    required this.l10n,
    required this.total,
    required this.saving,
    required this.onClear,
    this.onSave,
  });

  final AppLocalizations l10n;
  final double total;
  final bool saving;
  final VoidCallback onClear;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F9),
        border: Border(top: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('CUSTOMER MESSAGE'),
                const SizedBox(height: 4),
                Container(
                  height: 30,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFB7C3CB)),
                  ),
                  child: Text(
                    'Thank you for your business.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                const _FieldLabel('MEMO'),
                const SizedBox(height: 4),
                Container(
                  height: 30,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFB7C3CB)),
                  ),
                  child: const Text('Optional'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 310,
            child: Column(
              children: [
                _AmountRow(label: 'TOTAL', amount: total, currency: l10n.egp),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F1F4),
                    border: Border.all(color: const Color(0xFF9DB2BC)),
                  ),
                  child: _AmountRow(
                    label: 'OPEN AMOUNT',
                    amount: total,
                    currency: l10n.egp,
                    strong: true,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: onSave,
                      style: _smallButton(),
                      child: Text(saving ? 'Saving...' : 'Save & Close'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: onClear,
                      style: _smallButton(),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _smallButton() => OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    side: const BorderSide(color: Color(0xFF8FA1AB)),
  );
}

class _EstimateContextPanel extends StatelessWidget {
  const _EstimateContextPanel({
    required this.customer,
    required this.estimate,
    required this.total,
    required this.currency,
    this.onViewAll,
  });

  final CustomerModel? customer;
  final EstimateModel? estimate;
  final double total;
  final String currency;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return TransactionContextSidebar(
      title: c?.displayName ?? '',
      subtitle: c?.companyName,
      initials: c?.initials,
      emptyTitle: 'Select a customer',
      emptyMessage:
          'Choose a customer to see balances, estimates, and recent activity.',
      warning: c == null
          ? null
          : estimate == null
          ? 'New estimate.'
          : _status(estimate!),
      metrics: [
        TransactionContextMetric(
          label: 'Open balance',
          value: '${(c?.balance ?? 0).toStringAsFixed(2)} $currency',
          icon: Icons.account_balance_wallet_outlined,
        ),
        TransactionContextMetric(
          label: 'Credits',
          value: '${(c?.creditBalance ?? 0).toStringAsFixed(2)} $currency',
          icon: Icons.credit_score_outlined,
        ),
        TransactionContextMetric(
          label: 'Current estimate',
          value: '${total.toStringAsFixed(2)} $currency',
          icon: Icons.request_quote_outlined,
        ),
      ],
      activities: [
        if (estimate != null)
          TransactionContextActivity(
            title: estimate!.estimateNumber.isEmpty
                ? 'Estimate'
                : estimate!.estimateNumber,
            subtitle: _status(estimate!),
            amount: '${estimate!.totalAmount.toStringAsFixed(2)} $currency',
          ),
      ],
      notes: '',
      totals: TransactionTotalsUiModel(
        subtotal: total,
        total: total,
        paid: 0,
        balanceDue: total,
        currency: currency,
      ),
      onViewAll: onViewAll,
    );
  }

  static String _status(EstimateModel estimate) {
    if (estimate.isCancelled) return 'Cancelled';
    if (estimate.isDeclined) return 'Declined';
    if (estimate.isAccepted) return 'Accepted';
    if (estimate.sentAt != null) return 'Sent';
    return 'Draft';
  }
}

class _StripLabel extends StatelessWidget {
  const _StripLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: const Color(0xFF53656E),
      fontWeight: FontWeight.w900,
    ),
  );
}

class _StaticBox extends StatelessWidget {
  const _StaticBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFB7C3CB)),
    ),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 34,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFB7C3CB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${value.day}/${value.month}/${value.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 15),
          ],
        ),
      ),
    );
  }
}

class _HorizontalField extends StatelessWidget {
  const _HorizontalField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 82, child: _FieldLabel(label)),
      Expanded(child: child),
    ],
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    required this.currency,
    this.strong = false,
  });

  final String label;
  final double amount;
  final String currency;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
      Text(
        '${amount.toStringAsFixed(2)} $currency',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    ],
  );
}

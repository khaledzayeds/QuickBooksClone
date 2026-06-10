// customer_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/customer_model.dart';
import '../providers/customers_provider.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  bool _includeInactive = false;
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final cs = Theme.of(context).colorScheme;
    final text = _CustomerText.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _CenterToolbar(
            title: text.customerCenter,
            primaryLabel: text.newCustomer,
            primaryIcon: Icons.person_add_outlined,
            onRefresh: () => ref.read(customersProvider.notifier).refresh(),
            onPrimary: () => context.go(AppRoutes.customerNew),
            onAction: _showActionNotice,
          ),
          Expanded(
            child: customers.when(
              loading: () => const SkeletonList(),
              error: (e, _) => EmptyStateWidget(
                icon: Icons.error_outline,
                message: text.couldNotLoadCustomers,
                description: e.toString(),
                actionLabel: text.retry,
                onAction: () => ref.read(customersProvider.notifier).refresh(),
              ),
              data: (list) => _buildCenter(context, list),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenter(BuildContext context, List<CustomerModel> customers) {
    final cs = Theme.of(context).colorScheme;
    final text = _CustomerText.of(context);
    final active = customers.where((c) => c.isActive).length;
    final openBalance = customers.fold<double>(0, (sum, c) => sum + c.balance);
    final credits = customers.fold<double>(
      0,
      (sum, c) => sum + c.creditBalance,
    );
    final missing = customers.where((c) => !c.hasContactInfo).length;
    final sorted = [...customers]
      ..sort((a, b) {
        final bucket = _bucket(a).compareTo(_bucket(b));
        return bucket == 0 ? a.displayName.compareTo(b.displayName) : bucket;
      });
    final selected = sorted.isEmpty
        ? null
        : sorted.firstWhere(
            (c) => c.id == _selectedId,
            orElse: () => sorted.first,
          );
    if (selected != null && _selectedId != selected.id) {
      _selectedId = selected.id;
    }

    return Column(
      children: [
        _MetricStrip(
          chips: [
            _MetricChip(
              Icons.people_outline,
              text.customers,
              '${customers.length}',
            ),
            _MetricChip(Icons.check_circle_outline, text.active, '$active'),
            _MetricChip(
              Icons.receipt_long_outlined,
              text.openBalance,
              '${openBalance.toStringAsFixed(2)} EGP',
            ),
            _MetricChip(
              Icons.credit_score_outlined,
              text.credits,
              '${credits.toStringAsFixed(2)} EGP',
            ),
            _MetricChip(
              Icons.warning_amber_outlined,
              text.noContact,
              '$missing',
              warn: missing > 0,
            ),
          ],
        ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 330,
                child: _CustomerListPane(
                  customers: sorted,
                  selectedId: selected?.id,
                  includeInactive: _includeInactive,
                  onSearch: (v) =>
                      ref.read(customersProvider.notifier).setSearch(v),
                  onIncludeInactive: (v) {
                    setState(() => _includeInactive = v);
                    ref.read(customersProvider.notifier).setIncludeInactive(v);
                  },
                  onSelect: (customer) =>
                      setState(() => _selectedId = customer.id),
                ),
              ),
              VerticalDivider(width: 1, color: cs.outlineVariant),
              Expanded(
                child: selected == null
                    ? EmptyStateWidget(
                        icon: Icons.people_outline,
                        message: text.noCustomersFound,
                        description: text.createCustomerHint,
                        actionLabel: text.newCustomer,
                        onAction: () => context.go(AppRoutes.customerNew),
                      )
                    : _CustomerDetailPane(
                        customer: selected,
                        onEdit: () => context.go(
                          AppRoutes.customerEdit.replaceFirst(
                            ':id',
                            selected.id,
                          ),
                        ),
                        onOpen: () => context.go(
                          AppRoutes.customerDetails.replaceFirst(
                            ':id',
                            selected.id,
                          ),
                        ),
                        onToggleActive: () => _toggleActive(selected),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _bucket(CustomerModel customer) {
    if (customer.balance > 0) return 0;
    if (customer.creditBalance > 0) return 1;
    return 2;
  }

  void _showActionNotice(String title) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(title)));
  }

  Future<void> _toggleActive(CustomerModel customer) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: customer.isActive
          ? _CustomerText.of(context).makeCustomerInactive
          : _CustomerText.of(context).makeCustomerActive,
      message: customer.isActive
          ? _CustomerText.of(
              context,
            ).confirmCustomerInactive(customer.displayName)
          : _CustomerText.of(
              context,
            ).confirmCustomerActive(customer.displayName),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(customersProvider.notifier)
        .toggleActive(customer.id, !customer.isActive);
    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            customer.isActive
                ? _CustomerText.of(context).customerMadeInactive
                : _CustomerText.of(context).customerMadeActive,
          ),
        ),
      ),
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}

class _CustomerListPane extends StatelessWidget {
  const _CustomerListPane({
    required this.customers,
    required this.selectedId,
    required this.includeInactive,
    required this.onSearch,
    required this.onIncludeInactive,
    required this.onSelect,
  });

  final List<CustomerModel> customers;
  final String? selectedId;
  final bool includeInactive;
  final ValueChanged<String> onSearch;
  final ValueChanged<bool> onIncludeInactive;
  final ValueChanged<CustomerModel> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = _CustomerText.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 30,
                child: TextField(
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: text.searchNamePhoneEmail,
                    prefixIcon: const Icon(Icons.search, size: 16),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      text.activeCustomers,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(text.inactive, style: const TextStyle(fontSize: 11)),
                  Transform.scale(
                    scale: 0.65,
                    child: Switch(
                      value: includeInactive,
                      onChanged: onIncludeInactive,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          height: 28,
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(flex: 5, child: _Head(text.name)),
              Expanded(flex: 3, child: _Head(text.balance, end: true)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              final selected = customer.id == selectedId;
              return _CustomerListRow(
                customer: customer,
                selected: selected,
                onTap: () => onSelect(customer),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomerListRow extends StatelessWidget {
  const _CustomerListRow({
    required this.customer,
    required this.selected,
    required this.onTap,
  });
  final CustomerModel customer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: selected ? cs.primary.withValues(alpha: 0.16) : null,
        child: Row(
          children: [
            Icon(
              customer.balance > 0
                  ? Icons.receipt_long_outlined
                  : Icons.person_outline,
              size: 15,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 5,
              child: Text(
                customer.displayName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                customer.netReceivable.toStringAsFixed(2),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  color: customer.netReceivable > 0
                      ? cs.primary
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerDetailPane extends StatelessWidget {
  const _CustomerDetailPane({
    required this.customer,
    required this.onEdit,
    required this.onOpen,
    required this.onToggleActive,
  });

  final CustomerModel customer;
  final VoidCallback onEdit;
  final VoidCallback onOpen;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = _CustomerText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text.customerInformation,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                tooltip: text.open,
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_outlined),
              ),
              IconButton(
                tooltip: text.edit,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(42, 22, 22, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(text.customerName, customer.displayName),
                _InfoLine(text.company, customer.companyName ?? '-'),
                _InfoLine(text.phone, customer.phone ?? '-'),
                _InfoLine(text.email, customer.email ?? '-'),
                _InfoLine(text.currency, customer.currency),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ValueBox(
                      text.openBalance,
                      '${customer.balance.toStringAsFixed(2)} ${customer.currency}',
                    ),
                    _ValueBox(
                      text.credits,
                      '${customer.creditBalance.toStringAsFixed(2)} ${customer.currency}',
                    ),
                    _ValueBox(
                      text.netReceivable,
                      '${customer.netReceivable.toStringAsFixed(2)} ${customer.currency}',
                      highlight: customer.netReceivable > 0,
                    ),
                    _ValueBox(
                      text.status,
                      customer.isActive ? text.active : text.inactive,
                    ),
                  ],
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(text.editCustomer),
                    ),
                    OutlinedButton.icon(
                      onPressed: onToggleActive,
                      icon: const Icon(Icons.toggle_on_outlined, size: 16),
                      label: Text(
                        customer.isActive ? text.makeInactive : text.makeActive,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.customerTransactionHistory,
                        extra: {
                          'customerId': customer.id,
                          'customerName': customer.displayName,
                        },
                      ),
                      icon: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: Text(text.statement),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: _ActivityTable(
            title: text.transactions,
            rows: [
              _ActivityRow(
                text.openBalance,
                '-',
                '-',
                'Accounts Receivable',
                customer.balance,
              ),
              if (customer.creditBalance > 0)
                _ActivityRow(
                  text.credit,
                  '-',
                  '-',
                  text.customerCredits,
                  -customer.creditBalance,
                ),
            ],
            currency: customer.currency,
          ),
        ),
      ],
    );
  }
}

class _CenterToolbar extends StatelessWidget {
  const _CenterToolbar({
    required this.title,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onRefresh,
    required this.onPrimary,
    required this.onAction,
  });

  final String title;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onRefresh;
  final VoidCallback onPrimary;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = _CustomerText.of(context);
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(
            tooltip: text.refresh,
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: text.actions,
            icon: const Icon(Icons.more_vert),
            onSelected: onAction,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: text.importCustomers,
                child: _MenuRow(
                  icon: Icons.upload_file_outlined,
                  label: text.importCustomers,
                ),
              ),
              PopupMenuItem(
                value: text.exportCustomers,
                child: _MenuRow(
                  icon: Icons.download_outlined,
                  label: text.exportCustomers,
                ),
              ),
              PopupMenuItem(
                value: text.downloadImportTemplate,
                child: _MenuRow(
                  icon: Icons.description_outlined,
                  label: text.downloadImportTemplate,
                ),
              ),
              PopupMenuItem(
                value: text.customerStatementBatch,
                child: _MenuRow(
                  icon: Icons.summarize_outlined,
                  label: text.customerStatementBatch,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          FilledButton.icon(
            onPressed: onPrimary,
            icon: Icon(primaryIcon, size: 17),
            label: Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.chips});
  final List<_MetricChip> chips;
  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, i) => chips[i],
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: chips.length,
    ),
  );
}

class _MetricChip extends StatelessWidget {
  const _MetricChip(this.icon, this.label, this.value, {this.warn = false});
  final IconData icon;
  final String label;
  final String value;
  final bool warn;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: warn ? cs.errorContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: warn ? cs.onErrorContainer : cs.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _ValueBox extends StatelessWidget {
  const _ValueBox(this.label, this.value, {this.highlight = false});
  final String label;
  final String value;
  final bool highlight;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ActivityTable extends StatelessWidget {
  const _ActivityTable({
    required this.title,
    required this.rows,
    required this.currency,
  });
  final String title;
  final List<_ActivityRow> rows;
  final String currency;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = _CustomerText.of(context);
    return Column(
      children: [
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          color: cs.surfaceContainerHighest,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(child: _Head(text.type)),
              Expanded(child: _Head(text.num)),
              Expanded(child: _Head(text.date)),
              Expanded(child: _Head(text.account)),
              Expanded(child: _Head(text.amount, end: true)),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    text.noActivityToShow,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final row = rows[i];
                    return Container(
                      height: 30,
                      color: i.isEven
                          ? cs.primaryContainer.withValues(alpha: 0.25)
                          : cs.surfaceContainerLowest,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.type,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              row.num,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              row.date,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              row.account,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${row.amount.toStringAsFixed(2)} $currency',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ActivityRow {
  const _ActivityRow(this.type, this.num, this.date, this.account, this.amount);
  final String type;
  final String num;
  final String date;
  final String account;
  final double amount;
}

class _Head extends StatelessWidget {
  const _Head(this.label, {this.end = false});
  final String label;
  final bool end;
  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: end ? TextAlign.end : TextAlign.start,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
    overflow: TextOverflow.ellipsis,
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)],
  );
}

class _CustomerText {
  const _CustomerText(this.ar);
  final bool ar;

  static _CustomerText of(BuildContext context) =>
      _CustomerText(Localizations.localeOf(context).languageCode == 'ar');

  String get customerCenter => ar ? 'مركز العملاء' : 'Customer Center';
  String get newCustomer => ar ? 'عميل جديد' : 'New Customer';
  String get couldNotLoadCustomers =>
      ar ? 'تعذر تحميل العملاء' : 'Could not load customers';
  String get retry => ar ? 'إعادة المحاولة' : 'Retry';
  String get customers => ar ? 'العملاء' : 'Customers';
  String get active => ar ? 'نشط' : 'Active';
  String get inactive => ar ? 'غير نشط' : 'Inactive';
  String get openBalance => ar ? 'الرصيد المفتوح' : 'Open balance';
  String get credits => ar ? 'الأرصدة الدائنة' : 'Credits';
  String get noContact => ar ? 'بدون بيانات اتصال' : 'No contact';
  String get noCustomersFound => ar ? 'لا يوجد عملاء' : 'No customers found';
  String get createCustomerHint => ar
      ? 'أنشئ عميلًا لبدء متابعة المبيعات والمديونيات.'
      : 'Create a customer to start tracking sales and receivables.';
  String get makeCustomerInactive =>
      ar ? 'جعل العميل غير نشط' : 'Make customer inactive';
  String get makeCustomerActive =>
      ar ? 'جعل العميل نشط' : 'Make customer active';
  String confirmCustomerInactive(String name) =>
      ar ? 'جعل "$name" غير نشط؟' : 'Make "$name" inactive?';
  String confirmCustomerActive(String name) =>
      ar ? 'جعل "$name" نشط؟' : 'Make "$name" active?';
  String get customerMadeInactive =>
      ar ? 'تم جعل العميل غير نشط' : 'Customer made inactive';
  String get customerMadeActive =>
      ar ? 'تم جعل العميل نشط' : 'Customer made active';
  String get searchNamePhoneEmail =>
      ar ? 'بحث بالاسم أو الهاتف أو البريد...' : 'Search name, phone, email...';
  String get activeCustomers => ar ? 'العملاء النشطون' : 'Active Customers';
  String get name => ar ? 'الاسم' : 'Name';
  String get balance => ar ? 'الرصيد' : 'Balance';
  String get customerInformation =>
      ar ? 'معلومات العميل' : 'Customer Information';
  String get open => ar ? 'فتح' : 'Open';
  String get edit => ar ? 'تعديل' : 'Edit';
  String get customerName => ar ? 'اسم العميل' : 'Customer Name';
  String get company => ar ? 'الشركة' : 'Company';
  String get phone => ar ? 'الهاتف' : 'Phone';
  String get email => ar ? 'البريد' : 'Email';
  String get currency => ar ? 'العملة' : 'Currency';
  String get netReceivable => ar ? 'صافي المستحقات' : 'Net receivable';
  String get status => ar ? 'الحالة' : 'Status';
  String get editCustomer => ar ? 'تعديل العميل' : 'Edit Customer';
  String get makeInactive => ar ? 'جعله غير نشط' : 'Make Inactive';
  String get makeActive => ar ? 'جعله نشط' : 'Make Active';
  String get statement => ar ? 'كشف حساب' : 'Statement';
  String get transactions => ar ? 'المعاملات' : 'Transactions';
  String get credit => ar ? 'رصيد دائن' : 'Credit';
  String get customerCredits => ar ? 'أرصدة العملاء' : 'Customer Credits';
  String get refresh => ar ? 'تحديث' : 'Refresh';
  String get actions => ar ? 'إجراءات' : 'Actions';
  String get importCustomers =>
      ar ? 'استيراد العملاء من Excel/CSV' : 'Import Customers from Excel/CSV';
  String get exportCustomers =>
      ar ? 'تصدير العملاء إلى Excel/CSV' : 'Export Customers to Excel/CSV';
  String get downloadImportTemplate =>
      ar ? 'تحميل قالب الاستيراد' : 'Download Import Template';
  String get customerStatementBatch =>
      ar ? 'طباعة كشوف العملاء دفعة واحدة' : 'Customer Statement Batch';
  String get type => ar ? 'النوع' : 'Type';
  String get num => ar ? 'الرقم' : 'Num';
  String get date => ar ? 'التاريخ' : 'Date';
  String get account => ar ? 'الحساب' : 'Account';
  String get amount => ar ? 'المبلغ' : 'Amount';
  String get noActivityToShow =>
      ar ? 'لا يوجد نشاط للعرض' : 'No activity to show';
}

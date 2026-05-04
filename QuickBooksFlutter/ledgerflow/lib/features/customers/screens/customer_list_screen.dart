// customer_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/customer_model.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_search_bar.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  bool _includeInactive = false;

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Center'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(customersProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          _CustomerActionsMenu(onComingSoon: _showComingSoon),
          AppButton(
            label: 'New Customer',
            icon: Icons.person_add_outlined,
            onPressed: () => context.go(AppRoutes.customerNew),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: customers.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          message: 'Could not load customers',
          description: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.read(customersProvider.notifier).refresh(),
        ),
        data: (list) {
          final active = list.where((c) => c.isActive).length;
          final inactive = list.length - active;
          final openBalance = list.fold<double>(0, (sum, c) => sum + c.balance);
          final creditBalance = list.fold<double>(0, (sum, c) => sum + c.creditBalance);
          final missingContact = list.where((c) => !c.hasContactInfo).length;
          final owing = list.where((c) => c.balance > 0).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer Center', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      'Manage customer profiles, balances, credits, and sales workflow entry points before polishing invoices and payments.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SummaryChip(icon: Icons.people_outline, label: 'Customers', value: list.length.toString()),
                        _SummaryChip(icon: Icons.check_circle_outline, label: 'Active', value: active.toString()),
                        _SummaryChip(icon: Icons.block_outlined, label: 'Inactive', value: inactive.toString()),
                        _SummaryChip(icon: Icons.receipt_long_outlined, label: 'Open balance', value: '${openBalance.toStringAsFixed(2)} EGP'),
                        _SummaryChip(icon: Icons.credit_score_outlined, label: 'Credits', value: '${creditBalance.toStringAsFixed(2)} EGP'),
                        _SummaryChip(icon: Icons.warning_amber_outlined, label: 'No contact', value: missingContact.toString()),
                        _SummaryChip(icon: Icons.account_balance_wallet_outlined, label: 'Owing customers', value: owing.toString()),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 820;
                    final search = CustomerSearchBar(onChanged: (v) => ref.read(customersProvider.notifier).setSearch(v));
                    final inactiveSwitch = SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includeInactive,
                      title: const Text('Include inactive'),
                      onChanged: (v) {
                        setState(() => _includeInactive = v);
                        ref.read(customersProvider.notifier).setIncludeInactive(v);
                      },
                    );
                    if (!wide) return Column(children: [search, inactiveSwitch]);
                    return Row(children: [Expanded(child: search), const SizedBox(width: 12), SizedBox(width: 230, child: inactiveSwitch)]);
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: list.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.people_outline,
                        message: 'No customers found',
                        description: 'Create the first customer or import a customer list later.',
                        actionLabel: 'New Customer',
                        onAction: () => context.go(AppRoutes.customerNew),
                      )
                    : _CustomerGroupedList(customers: list, onToggleActive: _toggleActive),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title is scheduled in the Customers productivity backlog.')));
  }

  Future<void> _toggleActive(CustomerModel customer) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: customer.isActive ? 'Make customer inactive' : 'Make customer active',
      message: customer.isActive ? 'Make "${customer.displayName}" inactive?' : 'Make "${customer.displayName}" active?',
    );
    if (confirmed != true || !mounted) return;

    final result = await ref.read(customersProvider.notifier).toggleActive(customer.id, !customer.isActive);

    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(customer.isActive ? 'Customer made inactive' : 'Customer made active')),
      ),
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}

class _CustomerGroupedList extends StatelessWidget {
  const _CustomerGroupedList({required this.customers, required this.onToggleActive});
  final List<CustomerModel> customers;
  final Future<void> Function(CustomerModel customer) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final owing = customers.where((c) => c.balance > 0).toList()..sort((a, b) => b.balance.compareTo(a.balance));
    final credit = customers.where((c) => c.balance <= 0 && c.creditBalance > 0).toList()..sort((a, b) => b.creditBalance.compareTo(a.creditBalance));
    final normal = customers.where((c) => c.balance <= 0 && c.creditBalance <= 0).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

    final groups = <_CustomerGroup>[
      if (owing.isNotEmpty) _CustomerGroup('Open balances', owing, Icons.receipt_long_outlined),
      if (credit.isNotEmpty) _CustomerGroup('Credits available', credit, Icons.credit_score_outlined),
      if (normal.isNotEmpty) _CustomerGroup('No open balance', normal, Icons.people_outline),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final total = group.customers.fold<double>(0, (sum, c) => sum + c.netReceivable);
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: Icon(group.icon),
            title: Text(group.title, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text('${group.customers.length} customers • ${total.toStringAsFixed(2)} EGP net'),
            children: group.customers
                .map((customer) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: CustomerCard(
                        customer: customer,
                        onTap: () => context.go(AppRoutes.customerDetails.replaceFirst(':id', customer.id)),
                        onEdit: () => context.go(AppRoutes.customerEdit.replaceFirst(':id', customer.id)),
                        onToggleActive: () => onToggleActive(customer),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _CustomerGroup {
  const _CustomerGroup(this.title, this.customers, this.icon);
  final String title;
  final List<CustomerModel> customers;
  final IconData icon;
}

class _CustomerActionsMenu extends StatelessWidget {
  const _CustomerActionsMenu({required this.onComingSoon});
  final ValueChanged<String> onComingSoon;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Customer actions',
      onSelected: onComingSoon,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'Import Customers from Excel/CSV', child: _MenuRow(icon: Icons.upload_file_outlined, label: 'Import Customers from Excel/CSV')),
        PopupMenuItem(value: 'Export Customers to Excel/CSV', child: _MenuRow(icon: Icons.download_outlined, label: 'Export Customers to Excel/CSV')),
        PopupMenuItem(value: 'Download Import Template', child: _MenuRow(icon: Icons.description_outlined, label: 'Download Import Template')),
        PopupMenuItem(value: 'Customer Statement Batch', child: _MenuRow(icon: Icons.summarize_outlined, label: 'Customer Statement Batch')),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [Icon(Icons.more_vert), SizedBox(width: 4), Text('Actions')]),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)]);
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18, color: cs.primary), const SizedBox(width: 8), Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)), Text(value)]),
    );
  }
}

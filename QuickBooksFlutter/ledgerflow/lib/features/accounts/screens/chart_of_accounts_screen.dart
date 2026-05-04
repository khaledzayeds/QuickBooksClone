// chart_of_accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/api_enums.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../settings/providers/setup_provider.dart';
import '../data/models/account_model.dart';
import '../providers/accounts_provider.dart';
import '../widgets/account_card.dart';

class ChartOfAccountsScreen extends ConsumerStatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  ConsumerState<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends ConsumerState<ChartOfAccountsScreen> {
  final _searchCtrl = TextEditingController();
  int? _selectedType;
  bool _includeInactive = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final setupState = ref.watch(setupProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    ref.listen(setupProvider, (previous, next) {
      if (next.successMessage != null && previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.successMessage!)));
        ref.read(accountsProvider.notifier).refresh();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart of Accounts'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(accountsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          TextButton.icon(
            onPressed: setupState.submitting ? null : ref.read(setupProvider.notifier).seedDefaultAccounts,
            icon: setupState.submitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.account_tree_outlined),
            label: const Text('Seed Defaults'),
          ),
          AppButton(
            label: 'New Account',
            icon: Icons.add,
            onPressed: () => context.go(AppRoutes.accountNew),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: accounts.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          message: 'Could not load accounts',
          description: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.read(accountsProvider.notifier).refresh(),
        ),
        data: (list) {
          final active = list.where((a) => a.isActive).length;
          final inactive = list.length - active;
          final debitBalance = list.where((a) => a.isDebitNormal).fold<double>(0, (sum, a) => sum + a.balance);
          final creditBalance = list.where((a) => !a.isDebitNormal).fold<double>(0, (sum, a) => sum + a.balance);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Financial foundation', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      'Review account codes, account types, activity status, and posting balances before polishing invoices, purchases, and reports.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SummaryChip(icon: Icons.account_tree_outlined, label: 'Accounts', value: list.length.toString()),
                        _SummaryChip(icon: Icons.check_circle_outline, label: 'Active', value: active.toString()),
                        _SummaryChip(icon: Icons.block_outlined, label: 'Inactive', value: inactive.toString()),
                        _SummaryChip(icon: Icons.south_west_outlined, label: 'Debit-normal', value: '${debitBalance.toStringAsFixed(2)} EGP'),
                        _SummaryChip(icon: Icons.north_east_outlined, label: 'Credit-normal', value: '${creditBalance.toStringAsFixed(2)} EGP'),
                      ],
                    ),
                    if (setupState.defaultAccountsSeed != null) ...[
                      const SizedBox(height: 12),
                      _SeedResultBanner(
                        created: setupState.defaultAccountsSeed!.createdCount,
                        skipped: setupState.defaultAccountsSeed!.skippedCount,
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 860;
                    final search = TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        hintText: 'Code or account name...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => ref.read(accountsProvider.notifier).setSearch(v),
                    );
                    final type = DropdownButtonFormField<int?>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder(), isDense: true),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All types')),
                        ...AccountType.values.map((t) => DropdownMenuItem(
                              value: t.value,
                              child: Text(AccountModel(id: '', code: '', name: '', accountType: t, balance: 0, isActive: true).accountTypeName),
                            )),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedType = v);
                        ref.read(accountsProvider.notifier).setTypeFilter(v);
                      },
                    );
                    final inactiveSwitch = SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includeInactive,
                      title: const Text('Include inactive'),
                      onChanged: (v) {
                        setState(() => _includeInactive = v);
                        ref.read(accountsProvider.notifier).setIncludeInactive(v);
                      },
                    );

                    if (!wide) {
                      return Column(children: [search, const SizedBox(height: 10), type, inactiveSwitch]);
                    }
                    return Row(
                      children: [
                        Expanded(flex: 2, child: search),
                        const SizedBox(width: 12),
                        SizedBox(width: 280, child: type),
                        const SizedBox(width: 12),
                        SizedBox(width: 210, child: inactiveSwitch),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: list.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.account_tree_outlined,
                        message: 'No accounts found',
                        description: 'Create a new account or seed the default chart of accounts.',
                        actionLabel: 'New Account',
                        onAction: () => context.go(AppRoutes.accountNew),
                      )
                    : _GroupedAccountsList(accounts: list, onToggleActive: _toggleActive),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleActive(AccountModel account) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: account.isActive ? 'Deactivate account' : 'Activate account',
      message: account.isActive ? 'Deactivate "${account.name}"?' : 'Activate "${account.name}"?',
    );
    if (confirmed != true || !mounted) return;

    final result = await ref.read(accountsProvider.notifier).toggleActive(account.id, !account.isActive);

    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(account.isActive ? 'Account deactivated' : 'Account activated')),
      ),
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}

class _GroupedAccountsList extends StatelessWidget {
  const _GroupedAccountsList({required this.accounts, required this.onToggleActive});

  final List<AccountModel> accounts;
  final Future<void> Function(AccountModel account) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final grouped = <AccountType, List<AccountModel>>{};
    for (final account in accounts) {
      grouped.putIfAbsent(account.accountType, () => []).add(account);
    }

    final ordered = AccountType.values.where(grouped.containsKey).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ordered.length,
      itemBuilder: (context, groupIndex) {
        final type = ordered[groupIndex];
        final items = grouped[type]!..sort((a, b) => a.code.compareTo(b.code));
        final title = AccountModel(id: '', code: '', name: '', accountType: type, balance: 0, isActive: true).accountTypeName;
        final total = items.fold<double>(0, (sum, item) => sum + item.balance);

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text('${items.length} accounts • ${total.toStringAsFixed(2)} EGP'),
            children: items
                .map((account) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: AccountCard(
                        account: account,
                        onTap: () => context.go(AppRoutes.accountEdit.replaceFirst(':id', account.id)),
                        onToggleActive: () => onToggleActive(account),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
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
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(value),
        ],
      ),
    );
  }
}

class _SeedResultBanner extends StatelessWidget {
  const _SeedResultBanner({required this.created, required this.skipped});
  final int created;
  final int skipped;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: cs.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Default accounts seed completed. Created: $created • Already existing: $skipped',
              style: TextStyle(color: cs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// chart_of_accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/api_enums.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/providers/setup_provider.dart';
import '../data/models/account_model.dart';
import '../providers/accounts_provider.dart';
import '../widgets/account_card.dart';

class ChartOfAccountsScreen extends ConsumerStatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  ConsumerState<ChartOfAccountsScreen> createState() =>
      _ChartOfAccountsScreenState();
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
    final l10n = AppLocalizations.of(context)!;

    ref.listen(setupProvider, (previous, next) {
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!)));
        ref.read(accountsProvider.notifier).refresh();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Tools Bar
            Container(
              height: 74,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6F7),
                border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  _Tool(
                    icon: Icons.add,
                    label: l10n.newText,
                    onTap: () => context.go(AppRoutes.accountNew),
                  ),
                  _Tool(
                    icon: Icons.refresh,
                    label: l10n.refresh,
                    onTap: () => ref.read(accountsProvider.notifier).refresh(),
                  ),
                  _Tool(
                    icon: setupState.submitting ? Icons.hourglass_empty : Icons.account_tree_outlined,
                    label: l10n.seedDefaults,
                    onTap: setupState.submitting
                        ? null
                        : ref.read(setupProvider.notifier).seedDefaultAccounts,
                  ),
                  const Spacer(),
                  _Tool(
                    icon: Icons.close,
                    label: l10n.close,
                    onTap: () => context.go(AppRoutes.dashboard),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // 2. Filter Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  
                  final title = SizedBox(
                    width: wide ? 200 : double.infinity,
                    child: Text(
                      l10n.chartOfAccounts,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF243E4A),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  );

                  final search = TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => ref.read(accountsProvider.notifier).setSearch(v),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: l10n.searchCodeOrName,
                      border: const OutlineInputBorder(),
                    ),
                  );

                  final typeFilter = SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<int?>(
                      initialValue: _selectedType,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: l10n.typeFilter,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem<int?>(value: null, child: Text(l10n.allTypes)),
                        ...AccountType.values.map(
                          (t) => DropdownMenuItem<int?>(
                            value: t.value,
                            child: Text(
                              AccountModel(
                                id: '', code: '', name: '',
                                accountType: t, balance: 0, isActive: true,
                              ).accountTypeName,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedType = v);
                        ref.read(accountsProvider.notifier).setTypeFilter(v);
                      },
                    ),
                  );

                  final inactiveToggle = SizedBox(
                    width: 200,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includeInactive,
                      title: Text(l10n.includeInactive, style: theme.textTheme.labelSmall),
                      onChanged: (v) {
                        setState(() => _includeInactive = v);
                        ref.read(accountsProvider.notifier).setIncludeInactive(v);
                      },
                    ),
                  );

                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 10),
                        search,
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: typeFilter),
                            const SizedBox(width: 10),
                            inactiveToggle,
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      title,
                      const SizedBox(width: 20),
                      Expanded(child: search),
                      const SizedBox(width: 12),
                      typeFilter,
                      const SizedBox(width: 12),
                      inactiveToggle,
                    ],
                  );
                },
              ),
            ),

            // 3. Metrics/Summary Strip
            accounts.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) {
                final active = list.where((a) => a.isActive).length;
                final debitBalance = list.where((a) => a.isDebitNormal).fold<double>(0, (sum, a) => sum + a.balance);
                final creditBalance = list.where((a) => !a.isDebitNormal).fold<double>(0, (sum, a) => sum + a.balance);

                return Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F6F7),
                    border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _SmallMetric(label: l10n.accounts, value: list.length.toString()),
                        _vDivider(),
                        _SmallMetric(label: l10n.active, value: active.toString()),
                        _vDivider(),
                        _SmallMetric(label: l10n.totalDebit, value: '${debitBalance.toStringAsFixed(2)} ${l10n.egp}'),
                        _vDivider(),
                        _SmallMetric(label: l10n.totalCredit, value: '${creditBalance.toStringAsFixed(2)} ${l10n.egp}'),
                        if (setupState.defaultAccountsSeed != null) ...[
                          _vDivider(),
                          Text(
                            l10n.seedCreated(setupState.defaultAccountsSeed!.createdCount),
                            style: theme.textTheme.labelSmall?.copyWith(color: cs.primary),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            Expanded(
              child: accounts.when(
                loading: () => const SkeletonList(),
                error: (e, _) => EmptyStateWidget(
                  icon: Icons.error_outline,
                  message: 'Could not load accounts',
                  description: e.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.read(accountsProvider.notifier).refresh(),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.account_tree_outlined,
                      message: l10n.noAccountsFound,
                      description: l10n.createOrSeedHint,
                      actionLabel: l10n.newText,
                      onAction: () => context.go(AppRoutes.accountNew),
                    );
                  }
                  return _GroupedAccountsList(
                    accounts: list,
                    onToggleActive: _toggleActive,
                  );
                },
              ),
            ),

            // Status Bar
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                color: Color(0xFFD4DDE3),
                border: Border(top: BorderSide(color: Color(0xFFAFBBC4))),
              ),
              child: Text(
                l10n.coaShortcutHint,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF33434C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _vDivider() => const VerticalDivider(width: 24, indent: 12, endIndent: 12, color: Color(0xFFB7C3CB));

  Future<void> _toggleActive(AccountModel account) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: account.isActive ? 'Deactivate account' : 'Activate account',
      message: account.isActive
          ? 'Deactivate "${account.name}"?'
          : 'Activate "${account.name}"?',
    );
    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(accountsProvider.notifier)
        .toggleActive(account.id, !account.isActive);

    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            account.isActive ? 'Account deactivated' : 'Account activated',
          ),
        ),
      ),
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}

class _GroupedAccountsList extends StatelessWidget {
  const _GroupedAccountsList({
    required this.accounts,
    required this.onToggleActive,
  });

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
        final title = AccountModel(
          id: '',
          code: '',
          name: '',
          accountType: type,
          balance: 0,
          isActive: true,
        ).accountTypeName;
        final total = items.fold<double>(0, (sum, item) => sum + item.balance);
        final l10n = AppLocalizations.of(context)!;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              '${items.length} ${l10n.accounts.toLowerCase()} • ${total.toStringAsFixed(2)} ${l10n.egp}',
            ),
            children: items
                .map(
                  (account) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: AccountCard(
                      account: account,
                      onTap: () => context.go(
                        AppRoutes.accountEdit.replaceFirst(':id', account.id),
                      ),
                      onToggleActive: () => onToggleActive(account),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? const Color(0xFF234C5D) : const Color(0xFF7D8B93);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        height: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: enabled ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFF53656E),
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFF243E4A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

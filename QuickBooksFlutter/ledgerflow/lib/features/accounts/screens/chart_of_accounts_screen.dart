// chart_of_accounts_screen.dart
// chart_of_accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_result.dart';
import '../../../core/constants/api_enums.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../app/router.dart';
import '../data/models/account_model.dart';
import '../providers/accounts_provider.dart';
import '../widgets/account_card.dart';


class ChartOfAccountsScreen extends ConsumerStatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  ConsumerState<ChartOfAccountsScreen> createState() =>
      _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState
    extends ConsumerState<ChartOfAccountsScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل الحسابات'),
        actions: [
          AppButton(
            label: 'حساب جديد',
            icon: Icons.add,
            onPressed: () => context.go(AppRoutes.accountNew),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // ── Filters ─────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Search
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'بحث باسم أو كود الحساب...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        ref.read(accountsProvider.notifier).setSearch(v),
                  ),
                ),
                const SizedBox(width: 12),

                // Type filter
                DropdownButton<int?>(
                  value: _selectedType,
                  hint: const Text('كل الأنواع'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('كل الأنواع')),
                    ...AccountType.values.map((t) => DropdownMenuItem(
                          value: t.value,
                          child: Text(AccountModel(
                            id: '', code: '', name: '',
                            accountType: t, balance: 0,
                            isActive: true,
                          ).accountTypeName),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedType = v);
                    ref
                        .read(accountsProvider.notifier)
                        .setTypeFilter(v);
                  },
                ),
                const SizedBox(width: 12),

                // Include inactive
                Row(
                  children: [
                    Checkbox(
                      value: _includeInactive,
                      onChanged: (v) {
                        setState(() => _includeInactive = v!);
                        ref
                            .read(accountsProvider.notifier)
                            .setIncludeInactive(v!);
                      },
                    ),
                    const Text('غير نشط'),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── List ────────────────────────────────
          Expanded(
            child: accounts.when(
              loading: () => const SkeletonList(),
              error: (e, _) => EmptyStateWidget(
                icon: Icons.error_outline,
                message: 'تعذر تحميل الحسابات',
                description: e.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () =>
                    ref.read(accountsProvider.notifier).refresh(),
              ),
              data: (list) => list.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.account_tree_outlined,
                      message: 'لا توجد حسابات',
                      description: 'ابدأ بإضافة حساب جديد',
                      actionLabel: 'حساب جديد',
                      onAction: () => context.go(AppRoutes.accountNew),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) => AccountCard(
                        account: list[i],
                        onTap: () => context.go(
                            AppRoutes.accountEdit
                                .replaceFirst(':id', list[i].id)),
                        onToggleActive: () =>
                            _toggleActive(list[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(AccountModel account) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: account.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب',
      message: account.isActive
          ? 'هل تريد تعطيل حساب "${account.name}"؟'
          : 'هل تريد تفعيل حساب "${account.name}"؟',
    );
    if (!confirmed! || !mounted) return;

    final result = await ref
        .read(accountsProvider.notifier)
        .toggleActive(account.id, !account.isActive);

    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(account.isActive
              ? 'تم تعطيل الحساب'
              : 'تم تفعيل الحساب'),
        ),
      ),
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}
// customer_list_screen.dart
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
  ConsumerState<CustomerListScreen> createState() =>
      _CustomerListScreenState();
}

class _CustomerListScreenState
    extends ConsumerState<CustomerListScreen> {
  bool _includeInactive = false;

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('العملاء'),
        actions: [
          AppButton(
            label: 'عميل جديد',
            icon: Icons.person_add_outlined,
            onPressed: () => context.go(AppRoutes.customerNew),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter ─────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: CustomerSearchBar(
                    onChanged: (v) =>
                        ref.read(customersProvider.notifier).setSearch(v),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _includeInactive,
                      onChanged: (v) {
                        setState(() => _includeInactive = v!);
                        ref
                            .read(customersProvider.notifier)
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
            child: customers.when(
              loading: () => const SkeletonList(),
              error: (e, _) => EmptyStateWidget(
                icon: Icons.error_outline,
                message: 'تعذر تحميل العملاء',
                description: e.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () =>
                    ref.read(customersProvider.notifier).refresh(),
              ),
              data: (list) => list.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.people_outline,
                      message: 'لا يوجد عملاء',
                      description: 'ابدأ بإضافة عميل جديد',
                      actionLabel: 'عميل جديد',
                      onAction: () => context.go(AppRoutes.customerNew),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) => CustomerCard(
                        customer: list[i],
                        onTap: () => context.go(
                          AppRoutes.customerDetails
                              .replaceFirst(':id', list[i].id),
                        ),
                        onEdit: () => context.go(
                          AppRoutes.customerEdit
                              .replaceFirst(':id', list[i].id),
                        ),
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

  Future<void> _toggleActive(CustomerModel customer) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: customer.isActive ? 'تعطيل العميل' : 'تفعيل العميل',
      message: customer.isActive
          ? 'هل تريد تعطيل "${customer.displayName}"؟'
          : 'هل تريد تفعيل "${customer.displayName}"؟',
    );
    if (!confirmed! || !mounted) return;

    final result = await ref
        .read(customersProvider.notifier)
        .toggleActive(customer.id, !customer.isActive);

    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(customer.isActive ? 'تم تعطيل العميل' : 'تم تفعيل العميل'),
        ),
      ),
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}
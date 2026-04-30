// customer_details_screen.dart
// customer_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../providers/customers_provider.dart';

class CustomerDetailsScreen extends ConsumerWidget {
  const CustomerDetailsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العميل'),
        actions: [
          customerAsync.whenData((c) => AppButton(
                label: 'تعديل',
                icon: Icons.edit_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go(
                  AppRoutes.customerEdit.replaceFirst(':id', id),
                ),
              )).value ??
              const SizedBox.shrink(),
          const SizedBox(width: 12),
        ],
      ),
      body: customerAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (customer) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Avatar + Name ──────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    child: Text(
                      customer.initials,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(customer.displayName,
                      style:
                          Theme.of(context).textTheme.headlineMedium),
                  if (customer.companyName != null)
                    Text(
                      customer.companyName!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.6)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Balance Cards ──────────────────────
            Row(
              children: [
                Expanded(
                  child: _BalanceCard(
                    label: 'الرصيد المستحق',
                    amount: customer.balance,
                    color: customer.balance > 0
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BalanceCard(
                    label: 'رصيد الإشعارات',
                    amount: customer.creditBalance,
                    color: customer.creditBalance > 0
                        ? Colors.orange
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Info ──────────────────────────────
            _InfoTile(
                icon: Icons.email_outlined,
                label: 'البريد الإلكتروني',
                value: customer.email ?? '—'),
            _InfoTile(
                icon: Icons.phone_outlined,
                label: 'الهاتف',
                value: customer.phone ?? '—'),
            _InfoTile(
                icon: Icons.attach_money_outlined,
                label: 'العملة',
                value: customer.currency),
            _InfoTile(
                icon: Icons.circle,
                label: 'الحالة',
                value: customer.isActive ? 'نشط' : 'غير نشط'),

            const SizedBox(height: 32),

            // ── Quick Actions ─────────────────────
            Text('إجراءات سريعة',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  label: 'فاتورة جديدة',
                  icon: Icons.description_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.go(
                    '${AppRoutes.invoiceNew}?customerId=$id',
                  ),
                ),
                AppButton(
                  label: 'استلام دفعة',
                  icon: Icons.account_balance_wallet_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.go(
                    '${AppRoutes.paymentNew}?customerId=$id',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.amount,
    this.color,
  });
  final String label;
  final double amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(2)} ج.م',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.4)),
          const SizedBox(width: 12),
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.6),
                  )),
          const Spacer(),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
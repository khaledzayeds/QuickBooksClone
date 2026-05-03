// vendor_payment_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/vendor_payment_model.dart';
import '../providers/vendor_payments_provider.dart';

class VendorPaymentListScreen extends ConsumerWidget {
  const VendorPaymentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(vendorPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدفوعات الموردين'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => ref.read(vendorPaymentsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: () => context.go('/purchases/vendor-payments/new'),
              icon: const Icon(Icons.add),
              label: const Text('دفع جديد'),
            ),
          ),
        ],
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(vendorPaymentsProvider.notifier).refresh(),
        ),
        data: (payments) {
          if (payments.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            onRefresh: () => ref.read(vendorPaymentsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _VendorPaymentCard(payment: payments[index]),
            ),
          );
        },
      ),
    );
  }
}

class _VendorPaymentCard extends StatelessWidget {
  const _VendorPaymentCard({required this.payment});

  final VendorPaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isVoid = payment.status == 3;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isVoid ? cs.errorContainer : cs.primaryContainer,
                child: Icon(
                  isVoid ? Icons.block : Icons.account_balance_wallet_outlined,
                  color: isVoid ? cs.onErrorContainer : cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.paymentNumber.isEmpty ? 'دفع بدون رقم' : payment.paymentNumber,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(payment.vendorName),
                    const SizedBox(height: 4),
                    Text(
                      '${_date(payment.paymentDate)} • ${payment.paymentMethod}',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'حساب الدفع: ${payment.paymentAccountName}',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${payment.amount.toStringAsFixed(2)} ج.م',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isVoid ? 'ملغي' : 'مرحل',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isVoid ? cs.error : cs.primary,
                      fontWeight: FontWeight.w700,
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

  static String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 56),
            const SizedBox(height: 16),
            Text('لا توجد مدفوعات موردين', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('ابدأ بتسجيل دفع لفواتير شراء مستحقة.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/purchases/vendor-payments/new'),
              icon: const Icon(Icons.add),
              label: const Text('دفع جديد'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

// purchase_return_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../data/models/purchase_return_model.dart';
import '../providers/purchase_returns_provider.dart';

class PurchaseReturnListScreen extends ConsumerWidget {
  const PurchaseReturnListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnsAsync = ref.watch(purchaseReturnsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مرتجعات الشراء'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () =>
                ref.read(purchaseReturnsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.purchaseReturnNew),
              icon: const Icon(Icons.add),
              label: const Text('مرتجع شراء جديد'),
            ),
          ),
        ],
      ),
      body: returnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(purchaseReturnsProvider.notifier).refresh(),
        ),
        data: (returns) {
          if (returns.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(purchaseReturnsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: returns.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _PurchaseReturnCard(purchaseReturn: returns[index]),
            ),
          );
        },
      ),
    );
  }
}

class _PurchaseReturnCard extends StatelessWidget {
  const _PurchaseReturnCard({required this.purchaseReturn});
  final PurchaseReturnModel purchaseReturn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.purchaseReturnDetails.replaceFirst(
            ':id',
            purchaseReturn.id,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: purchaseReturn.isVoid
                    ? cs.errorContainer
                    : cs.secondaryContainer,
                child: Icon(
                  purchaseReturn.isVoid
                      ? Icons.block
                      : Icons.keyboard_return_outlined,
                  color: purchaseReturn.isVoid
                      ? cs.onErrorContainer
                      : cs.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchaseReturn.returnNumber.isEmpty
                          ? 'مرتجع بدون رقم'
                          : purchaseReturn.returnNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(purchaseReturn.vendorName ?? 'مورد غير محدد'),
                    const SizedBox(height: 4),
                    Text(
                      '${_date(purchaseReturn.returnDate)} • ${purchaseReturn.billNumber ?? 'فاتورة شراء'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${purchaseReturn.totalAmount.toStringAsFixed(2)} ج.م',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    purchaseReturn.isVoid ? 'ملغي' : 'مرحل',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: purchaseReturn.isVoid ? cs.error : cs.primary,
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

  static String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
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
            const Icon(Icons.keyboard_return_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'لا توجد مرتجعات شراء',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'ابدأ بإنشاء مرتجع من فاتورة شراء مرحلة.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.purchaseReturnNew),
              icon: const Icon(Icons.add),
              label: const Text('مرتجع شراء جديد'),
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
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
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

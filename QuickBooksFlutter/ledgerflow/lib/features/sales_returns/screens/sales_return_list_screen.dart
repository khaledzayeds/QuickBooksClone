// sales_return_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../data/models/sales_return_model.dart';
import '../providers/sales_returns_provider.dart';

class SalesReturnListScreen extends ConsumerWidget {
  const SalesReturnListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnsAsync = ref.watch(salesReturnsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مرتجعات البيع'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => ref.read(salesReturnsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.salesReturnNew),
              icon: const Icon(Icons.add),
              label: const Text('مرتجع جديد'),
            ),
          ),
        ],
      ),
      body: returnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(salesReturnsProvider.notifier).refresh(),
        ),
        data: (returns) {
          if (returns.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(salesReturnsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: returns.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _SalesReturnCard(salesReturn: returns[index]),
            ),
          );
        },
      ),
    );
  }
}

class _SalesReturnCard extends StatelessWidget {
  const _SalesReturnCard({required this.salesReturn});

  final SalesReturnModel salesReturn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.salesReturnDetails.replaceFirst(':id', salesReturn.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: salesReturn.isVoid
                    ? cs.errorContainer
                    : cs.tertiaryContainer,
                child: Icon(
                  salesReturn.isVoid
                      ? Icons.block
                      : Icons.assignment_return_outlined,
                  color: salesReturn.isVoid
                      ? cs.onErrorContainer
                      : cs.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salesReturn.returnNumber.isEmpty
                          ? 'مرتجع بدون رقم'
                          : salesReturn.returnNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(salesReturn.customerName ?? 'عميل غير محدد'),
                    const SizedBox(height: 4),
                    Text(
                      '${_date(salesReturn.returnDate)} • ${salesReturn.invoiceNumber ?? 'فاتورة'}',
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
                    '${salesReturn.totalAmount.toStringAsFixed(2)} ج.م',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    salesReturn.isVoid ? 'ملغي' : 'مرحل',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: salesReturn.isVoid ? cs.error : cs.primary,
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
            const Icon(Icons.assignment_return_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'لا توجد مرتجعات بيع',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'ابدأ بإنشاء مرتجع من فاتورة بيع مرحلة.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.salesReturnNew),
              icon: const Icon(Icons.add),
              label: const Text('مرتجع جديد'),
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

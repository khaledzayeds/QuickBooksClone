// sales_order_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../data/models/sales_order_model.dart';
import '../providers/sales_orders_provider.dart';

class SalesOrderListScreen extends ConsumerWidget {
  const SalesOrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(salesOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salesOrders),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => ref.read(salesOrdersProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: () => context.go('/sales/orders/new'),
              icon: const Icon(Icons.add),
              label: Text('${l10n.newText} ${l10n.salesOrders}'),
            ),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(salesOrdersProvider.notifier).refresh(),
        ),
        data: (orders) {
          if (orders.isEmpty) return const _EmptyState();

          return RefreshIndicator(
            onRefresh: () => ref.read(salesOrdersProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _SalesOrderCard(order: orders[index]),
            ),
          );
        },
      ),
    );
  }
}

class _SalesOrderCard extends StatelessWidget {
  const _SalesOrderCard({required this.order});

  final SalesOrderModel order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final statusLabel = order.isCancelled
        ? l10n.statusCancelled
        : order.isClosed
            ? l10n.statusClosed
            : order.isOpen
                ? l10n.statusOpen
                : l10n.statusDraft;
    final isBad = order.isCancelled;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isBad ? cs.errorContainer : cs.primaryContainer,
                child: Icon(
                  isBad ? Icons.block : Icons.shopping_cart_checkout_outlined,
                  color: isBad ? cs.onErrorContainer : cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber.isEmpty ? '-' : order.orderNumber,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(order.customerName ?? '-'),
                    const SizedBox(height: 4),
                    Text(
                      '${_date(order.orderDate)} • ${l10n.expectedDate}: ${_date(order.expectedDate)}',
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
                    '${order.totalAmount.toStringAsFixed(2)} ${l10n.egp}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isBad ? cs.error : cs.primary,
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
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_checkout_outlined, size: 56),
            const SizedBox(height: 16),
            Text(l10n.salesOrders, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.underDevelopment, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/sales/orders/new'),
              icon: const Icon(Icons.add),
              label: Text('${l10n.newText} ${l10n.salesOrders}'),
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
    final l10n = AppLocalizations.of(context)!;

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
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

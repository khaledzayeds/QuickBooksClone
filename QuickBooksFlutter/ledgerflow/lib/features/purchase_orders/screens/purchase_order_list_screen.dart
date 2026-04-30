import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/purchase_orders_provider.dart';
import '../data/models/purchase_order_model.dart';
import '../widgets/order_status_badge.dart';
import '../../../app/router.dart';

class PurchaseOrderListScreen extends ConsumerStatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  ConsumerState<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState
    extends ConsumerState<PurchaseOrderListScreen> {
  String? _selectedStatus;

  static const _statuses = [
    (null, 'الكل'),
    ('Draft', 'مسودة'),
    ('Open', 'مفتوح'),
    ('Closed', 'مغلق'),
    ('Cancelled', 'ملغي'),
  ];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(purchaseOrdersProvider);
    final cs          = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('أوامر الشراء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(purchaseOrdersProvider.notifier).refresh(),
          ),
        ],
      ),

      // ── Filter Chips ──────────────────────────────────────────────
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _statuses.map((s) {
                final isSelected = _selectedStatus == s.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s.$2),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedStatus = s.$1);
                      ref
                          .read(purchaseOrdersProvider.notifier)
                          .setStatus(s.$1);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // ── List ───────────────────────────────────────────────────
          Expanded(
            child: ordersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: cs.error),
                    const SizedBox(height: 12),
                    Text(e.toString(),
                        style: TextStyle(color: cs.error)),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                      onPressed: () => ref
                          .read(purchaseOrdersProvider.notifier)
                          .refresh(),
                    ),
                  ],
                ),
              ),
              data: (orders) => orders.isEmpty
                  ? _EmptyState(
                      onNew: () => context.push(AppRoutes.purchaseOrderNew))
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(purchaseOrdersProvider.notifier)
                          .refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _PoCard(
                          order: orders[i],
                          onTap: () => context.push(
                              AppRoutes.purchaseOrderDetails
                                  .replaceFirst(':id', orders[i].id)),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('أمر جديد'),
        onPressed: () => context.push(AppRoutes.purchaseOrderNew),
      ),
    );
  }
}

// ─── PO Card ──────────────────────────────────────────────────────────
class _PoCard extends StatelessWidget {
  const _PoCard({required this.order, required this.onTap});
  final PurchaseOrderModel order;
  final VoidCallback        onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.receipt_long_outlined,
              color: theme.colorScheme.primary, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(order.orderNumber,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            OrderStatusBadge(status: order.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(order.vendorName,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7))),
            const SizedBox(height: 2),
            Text(
              '${order.totalAmount.toStringAsFixed(2)} ج.م',
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('لا توجد أوامر شراء',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('ابدأ بإنشاء أمر شراء جديد',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('أمر جديد'),
              onPressed: onNew,
            ),
          ],
        ),
      );
}
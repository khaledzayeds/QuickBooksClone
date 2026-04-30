import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/purchase_orders_provider.dart';
import '../data/models/purchase_order_model.dart';
import '../widgets/order_status_badge.dart';
import '../../../../core/widgets/confirm_dialog.dart';

class PurchaseOrderDetailsScreen extends ConsumerWidget {
  const PurchaseOrderDetailsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(purchaseOrderProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل أمر الشراء'),
        actions: [
          orderAsync.whenOrNull(
            data: (o) => PopupMenuButton<_Action>(
              onSelected: (a) => _handleAction(context, ref, o, a),
              itemBuilder: (_) => [
                if (o.canEdit)
                  const PopupMenuItem(
                    value: _Action.open,
                    child: ListTile(
                      leading: Icon(Icons.lock_open_outlined),
                      title: Text('فتح الأمر'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (o.canCancel)
                  const PopupMenuItem(
                    value: _Action.cancel,
                    child: ListTile(
                      leading: Icon(Icons.cancel_outlined),
                      title: Text('إلغاء الأمر'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (o.isOpen)
                  const PopupMenuItem(
                    value: _Action.close,
                    child: ListTile(
                      leading: Icon(Icons.lock_outline),
                      title: Text('إغلاق الأمر'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(e.toString()),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                onPressed: () => ref.invalidate(purchaseOrderProvider(id)),
              ),
            ],
          ),
        ),
        data: (order) => _OrderDetails(order: order),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    PurchaseOrderModel order,
    _Action action,
  ) async {
    final repo = ref.read(purchaseOrdersRepoProvider);

    // Confirm for destructive actions
    if (action == _Action.cancel) {
      final confirmed = await showConfirmDialog(
        context: context,
        title: 'إلغاء الأمر',
        message: 'هل أنت متأكد من إلغاء أمر الشراء ${order.orderNumber}؟',
        confirmLabel: 'إلغاء الأمر',
        isDangerous: true,
      );
      if (confirmed != true) return;
    }

    final result = switch (action) {
      _Action.open   => await repo.openOrder(order.id),
      _Action.close  => await repo.closeOrder(order.id),
      _Action.cancel => await repo.cancelOrder(order.id),
    };

    result.when(
      success: (_) {
        ref.invalidate(purchaseOrderProvider(id));
        ref.read(purchaseOrdersProvider.notifier).refresh();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_successMsg(action))),
          );
        }
      },
      failure: (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );
  }

  String _successMsg(_Action a) => switch (a) {
        _Action.open   => 'تم فتح الأمر ✅',
        _Action.close  => 'تم إغلاق الأمر ✅',
        _Action.cancel => 'تم إلغاء الأمر',
      };
}

enum _Action { open, close, cancel }

// ─── Details Body ─────────────────────────────────────────────────────
class _OrderDetails extends StatelessWidget {
  const _OrderDetails({required this.order});
  final PurchaseOrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt   = DateFormat('yyyy/MM/dd');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.orderNumber,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(
                    icon: Icons.business_outlined,
                    label: 'المورد',
                    value: order.vendorName),
                _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'تاريخ الأمر',
                    value: fmt.format(order.orderDate)),
                if (order.expectedDate != null)
                  _InfoRow(
                      icon: Icons.event_outlined,
                      label: 'تاريخ التسليم',
                      value: fmt.format(order.expectedDate!)),
                if (order.notes != null && order.notes!.isNotEmpty)
                  _InfoRow(
                      icon: Icons.notes_outlined,
                      label: 'ملاحظات',
                      value: order.notes!),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Lines
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الأصناف (${order.lines.length})',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Divider(height: 24),
                ...order.lines.map((l) => _LineRow(line: l)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Total
        Card(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي الكلي',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                Text(
                  '${order.totalAmount.toStringAsFixed(2)} ج.م',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
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
                style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.6))),
            const Spacer(),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});
  final PurchaseOrderLine line;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.itemName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (line.description != null)
                    Text(line.description!,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.6))),
                  Text(
                    '${line.quantity.toStringAsFixed(0)} × ${line.unitCost.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${line.lineTotal.toStringAsFixed(2)} ج.م',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary),
                ),
                if (line.receivedQuantity > 0)
                  Text(
                    'استُلم: ${line.receivedQuantity.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.green),
                  ),
              ],
            ),
          ],
        ),
      );
}
// purchase_order_details_screen.dart
// Aligned with backend PurchaseOrderDto contract.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/purchase_orders_provider.dart';
import '../data/models/purchase_order_model.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../app/router.dart';

class PurchaseOrderDetailsScreen extends ConsumerWidget {
  const PurchaseOrderDetailsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(purchaseOrderProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل أمر الشراء | PO Details'),
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
                      title: Text('فتح الأمر | Open'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (o.canReceive)
                  PopupMenuItem(
                    value: _Action.receive,
                    child: const ListTile(
                      leading: Icon(Icons.inventory_2_outlined),
                      title: Text('استلام مخزون | Receive'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (o.isOpen)
                  const PopupMenuItem(
                    value: _Action.close,
                    child: ListTile(
                      leading: Icon(Icons.lock_outline),
                      title: Text('إغلاق الأمر | Close'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (o.canCancel)
                  const PopupMenuItem(
                    value: _Action.cancel,
                    child: ListTile(
                      leading: Icon(Icons.cancel_outlined, color: Colors.red),
                      title: Text('إلغاء الأمر | Cancel'),
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
                label: const Text('إعادة المحاولة | Retry'),
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
    // Receive inventory → navigate
    if (action == _Action.receive) {
      context.push('${AppRoutes.receiveInventoryNew}?purchaseOrderId=${order.id}');
      return;
    }

    final repo = ref.read(purchaseOrdersRepoProvider);

    if (action == _Action.cancel) {
      final confirmed = await showConfirmDialog(
        context: context,
        title: 'إلغاء الأمر | Cancel Order',
        message: 'هل أنت متأكد من إلغاء أمر الشراء ${order.orderNumber}؟',
        confirmLabel: 'إلغاء الأمر | Cancel',
        isDangerous: true,
      );
      if (confirmed != true) return;
    }

    final result = switch (action) {
      _Action.open    => await repo.openOrder(order.id),
      _Action.close   => await repo.closeOrder(order.id),
      _Action.cancel  => await repo.cancelOrder(order.id),
      _Action.receive => throw StateError('handled above'),
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
        _Action.open    => 'تم فتح الأمر ✅',
        _Action.close   => 'تم إغلاق الأمر ✅',
        _Action.cancel  => 'تم إلغاء الأمر',
        _Action.receive => '',
      };
}

enum _Action { open, close, cancel, receive }

// ─── Details Body ─────────────────────────────────────────────────────
class _OrderDetails extends StatelessWidget {
  const _OrderDetails({required this.order});
  final PurchaseOrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final fmt   = DateFormat('dd/MM/yyyy');

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
                    _StatusChip(status: order.status),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(
                    icon: Icons.business_outlined,
                    label: 'المورد | Vendor',
                    value: order.vendorName),
                _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'تاريخ الأمر | Date',
                    value: fmt.format(order.orderDate)),
                _InfoRow(
                    icon: Icons.event_outlined,
                    label: 'تاريخ التسليم | Expected',
                    value: fmt.format(order.expectedDate)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Lines table
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الأصناف | Items (${order.lines.length})',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Divider(height: 24),
                // Table header
                Row(
                  children: [
                    Expanded(flex: 3, child: Text('الصنف | Item',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.outline))),
                    Expanded(child: Text('الكمية', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.outline))),
                    Expanded(child: Text('السعر', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.outline))),
                    Expanded(child: Text('الإجمالي', textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.outline))),
                  ],
                ),
                const Divider(height: 12),
                ...order.lines.map((l) => _LineRow(line: l)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Summary Card
        Card(
          color: cs.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SummaryRow('المبلغ الفرعي | Subtotal',
                    '${order.subtotal.toStringAsFixed(2)} ج.م'),
                if (order.taxAmount > 0)
                  _SummaryRow('الضريبة | Tax',
                      '${order.taxAmount.toStringAsFixed(2)} ج.م'),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الإجمالي الكلي | Total',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(
                      '${order.totalAmount.toStringAsFixed(2)} ج.م',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: cs.primary),
                    ),
                  ],
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final PurchaseOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      PurchaseOrderStatus.draft     => (Colors.grey.shade200, Colors.grey.shade700),
      PurchaseOrderStatus.open      => (Colors.green.shade100, Colors.green.shade800),
      PurchaseOrderStatus.closed    => (Colors.blue.shade100, Colors.blue.shade800),
      PurchaseOrderStatus.cancelled => (Colors.red.shade100, Colors.red.shade800),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.labelAr,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
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
            Icon(icon, size: 18,
                color: Theme.of(context).hintColor),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: Theme.of(context).hintColor)),
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(line.description,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Text(line.quantity.toStringAsFixed(0),
                  textAlign: TextAlign.center),
            ),
            Expanded(
              child: Text(line.unitCost.toStringAsFixed(2),
                  textAlign: TextAlign.center),
            ),
            Expanded(
              child: Text(
                '${line.lineTotal.toStringAsFixed(2)}',
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).hintColor)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
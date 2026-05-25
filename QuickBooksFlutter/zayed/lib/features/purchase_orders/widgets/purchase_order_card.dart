// purchase_order_card.dart
// Shared PO card widget — aligned with updated model.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/purchase_order_model.dart';
import 'order_status_badge.dart';

class PurchaseOrderCard extends StatelessWidget {
  const PurchaseOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onCancel,
  });

  final PurchaseOrderModel order;
  final VoidCallback?      onTap;
  final VoidCallback?      onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt   = DateFormat('dd/MM/yyyy');

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width:  44,
          height: 44,
          decoration: BoxDecoration(
            color:        theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.shopping_cart_outlined,
            size:  20,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(order.orderNumber,
                  style: theme.textTheme.titleMedium),
            ),
            OrderStatusBadge(status: order.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              order.vendorName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.6),
              ),
            ),
            Text(
              fmt.format(order.orderDate),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${order.totalAmount.toStringAsFixed(2)} ج.م',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color:      theme.colorScheme.primary,
              ),
            ),
            Text(
              '${order.lines.length} صنف',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
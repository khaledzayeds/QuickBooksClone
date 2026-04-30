// customer_card.dart
// customer_card.dart

import 'package:flutter/material.dart';
import '../data/models/customer_model.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
    this.onEdit,
    this.onToggleActive,
  });

  final CustomerModel customer;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            customer.initials,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          customer.displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            color: customer.isActive ? null : theme.disabledColor,
          ),
        ),
        subtitle: Text(
          customer.phone ?? customer.email ?? customer.currency,
          style: theme.textTheme.bodyMedium?.copyWith(
            color:
                theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Balance
            if (customer.hasBalance)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${customer.balance.toStringAsFixed(0)} ج.م',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                tooltip: 'تعديل',
              ),
            if (onToggleActive != null)
              IconButton(
                icon: Icon(
                  customer.isActive
                      ? Icons.toggle_on_outlined
                      : Icons.toggle_off_outlined,
                  color: customer.isActive
                      ? theme.colorScheme.primary
                      : theme.disabledColor,
                ),
                onPressed: onToggleActive,
                tooltip: customer.isActive ? 'تعطيل' : 'تفعيل',
              ),
          ],
        ),
      ),
    );
  }
}
// vendor_card.dart
// vendor_card.dart

import 'package:flutter/material.dart';
import '../data/models/vendor_model.dart';

class VendorCard extends StatelessWidget {
  const VendorCard({
    super.key,
    required this.vendor,
    this.onTap,
    this.onEdit,
    this.onToggleActive,
  });

  final VendorModel    vendor;
  final VoidCallback?  onTap;
  final VoidCallback?  onEdit;
  final VoidCallback?  onToggleActive;

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
            vendor.initials,
            style: theme.textTheme.titleMedium?.copyWith(
              color:       theme.colorScheme.primary,
              fontWeight:  FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          vendor.displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            color: vendor.isActive ? null : theme.disabledColor,
          ),
        ),
        subtitle: Text(
          vendor.phone ?? vendor.email ?? vendor.currency,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vendor.hasBalance)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${vendor.balance.toStringAsFixed(0)} ج.م',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:      theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (onEdit != null)
              IconButton(
                icon:    const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                tooltip: 'تعديل',
              ),
            if (onToggleActive != null)
              IconButton(
                icon: Icon(
                  vendor.isActive
                      ? Icons.toggle_on_outlined
                      : Icons.toggle_off_outlined,
                  color: vendor.isActive
                      ? theme.colorScheme.primary
                      : theme.disabledColor,
                ),
                onPressed: onToggleActive,
                tooltip: vendor.isActive ? 'تعطيل' : 'تفعيل',
              ),
          ],
        ),
      ),
    );
  }
}
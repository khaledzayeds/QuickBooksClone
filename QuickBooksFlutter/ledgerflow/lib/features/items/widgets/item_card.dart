// item_card.dart
// item_card.dart

import 'package:flutter/material.dart';
import '../data/models/item_model.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onEdit,
    this.onToggleActive,
  });

  final ItemModel      item;
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
        leading: Container(
          width:  44,
          height: 44,
          decoration: BoxDecoration(
            color:         theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius:  BorderRadius.circular(10),
          ),
          child: Icon(
            _itemIcon(item.itemType),
            size:  20,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          item.name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: item.isActive ? null : theme.disabledColor,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              item.itemType.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.5),
              ),
            ),
            if (item.sku != null) ...[
              Text(
                ' · ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.3),
                ),
              ),
              Text(
                item.sku!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.salesPrice.toStringAsFixed(2)} ج.م',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (item.isInventory)
                  Text(
                    'مخزون: ${item.quantityOnHand.toStringAsFixed(0)} ${item.unit ?? 'قطعة'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: item.quantityOnHand > 0
                          ? Colors.green
                          : theme.colorScheme.error,
                    ),
                  ),
              ],
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
                  item.isActive
                      ? Icons.toggle_on_outlined
                      : Icons.toggle_off_outlined,
                  color: item.isActive
                      ? theme.colorScheme.primary
                      : theme.disabledColor,
                ),
                onPressed: onToggleActive,
                tooltip: item.isActive ? 'تعطيل' : 'تفعيل',
              ),
          ],
        ),
      ),
    );
  }

  IconData _itemIcon(ItemType type) => switch (type) {
        ItemType.inventory    => Icons.inventory_2_outlined,
        ItemType.nonInventory => Icons.category_outlined,
        ItemType.service      => Icons.design_services_outlined,
        ItemType.bundle       => Icons.widgets_outlined,
      };
}
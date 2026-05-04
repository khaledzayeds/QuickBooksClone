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

  final ItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_itemIcon(item.itemType), size: 22, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: item.isActive ? null : theme.disabledColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.hasRequiredPostingAccounts)
                          Tooltip(
                            message: 'Missing required posting accounts',
                            child: Icon(Icons.warning_amber_outlined, color: cs.error, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniChip(label: item.itemType.label, icon: _itemIcon(item.itemType)),
                        if (item.sku?.isNotEmpty == true) _MiniChip(label: 'SKU ${item.sku}', icon: Icons.tag_outlined),
                        if (item.barcode?.isNotEmpty == true) _MiniChip(label: 'Barcode', icon: Icons.qr_code_outlined),
                        _MiniChip(label: item.isActive ? 'Active' : 'Inactive', icon: item.isActive ? Icons.check_circle_outline : Icons.block_outlined),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _Metric(label: 'Sales', value: '${item.salesPrice.toStringAsFixed(2)} EGP'),
                        _Metric(label: 'Cost', value: '${item.purchasePrice.toStringAsFixed(2)} EGP'),
                        _Metric(label: 'Margin', value: '${item.grossMargin.toStringAsFixed(2)} EGP'),
                        if (item.isInventory) _Metric(label: 'On hand', value: '${item.quantityOnHand.toStringAsFixed(2)} ${item.unit ?? ''}'),
                        if (item.isInventory) _Metric(label: 'Value', value: '${item.inventoryValue.toStringAsFixed(2)} EGP'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                  if (onToggleActive != null)
                    IconButton(
                      icon: Icon(
                        item.isActive ? Icons.toggle_on_outlined : Icons.toggle_off_outlined,
                        color: item.isActive ? cs.primary : theme.disabledColor,
                      ),
                      onPressed: onToggleActive,
                      tooltip: item.isActive ? 'Make inactive' : 'Make active',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _itemIcon(ItemType type) => switch (type) {
        ItemType.inventory => Icons.inventory_2_outlined,
        ItemType.nonInventory => Icons.category_outlined,
        ItemType.service => Icons.design_services_outlined,
        ItemType.bundle => Icons.widgets_outlined,
      };
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(text: '$label: ', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// item_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/item_model.dart';
import '../providers/items_provider.dart';

class ItemDetailsScreen extends ConsumerWidget {
  const ItemDetailsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailProvider(id));
    final theme = Theme.of(context);

    final l10n = AppLocalizations.of(context)!;
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // Tool Strip
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                _ToolBtn(
                  icon: Icons.arrow_back,
                  label: l10n.close,
                  onPressed: () => context.go(AppRoutes.items),
                ),
                const Spacer(),
                itemAsync.whenData((item) => _ToolBtn(
                      icon: Icons.edit_outlined,
                      label: l10n.edit,
                      onPressed: () => context.go(
                        AppRoutes.itemEdit.replaceFirst(':id', id),
                      ),
                    )).value ?? const SizedBox.shrink(),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(
            child:
            itemAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (item) => ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _HeaderCard(item: item),
                  const SizedBox(height: 16),
                  if (!item.hasRequiredPostingAccounts) ...[
                    _WarningCard(item: item),
                    const SizedBox(height: 16),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 980;
                      final left = Column(
                        children: [
                          _PriceAndStockCard(item: item),
                          const SizedBox(height: 16),
                          _IdentifiersCard(item: item),
                        ],
                      );
                      final right = Column(
                        children: [
                          _PostingAccountsCard(item: item),
                          const SizedBox(height: 16),
                          _QuickActionsCard(item: item),
                        ],
                      );

                      if (!wide) {
                        return Column(
                          children: [
                            left,
                            const SizedBox(height: 16),
                            right,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 16),
                          Expanded(child: right),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _FutureActivityCard(item: item),
                  const SizedBox(height: 16),
                  Text(
                    'QuickBooks-style note: item activity will later show related invoices, sales receipts, purchase orders, bills, receive inventory documents, and inventory adjustments.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(18)),
              child: Icon(_itemIcon(item.itemType), color: cs.onPrimaryContainer, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(item.itemType.label), avatar: Icon(_itemIcon(item.itemType), size: 18)),
                      Chip(label: Text(item.isActive ? 'Active' : 'Inactive'), avatar: Icon(item.isActive ? Icons.check_circle_outline : Icons.block_outlined, size: 18)),
                      if (item.sku?.isNotEmpty == true) Chip(label: Text('SKU: ${item.sku}')),
                      if (!item.hasRequiredPostingAccounts) const Chip(label: Text('Needs account setup'), avatar: Icon(Icons.warning_amber_outlined, size: 18)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(_typeDescription(item.itemType), style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _missingAccountText(item),
              style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceAndStockCard extends StatelessWidget {
  const _PriceAndStockCard({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.price_change_outlined,
      title: 'Sales, purchase, and stock',
      children: [
        _MetricGrid(metrics: [
          _MetricData('Sales price', '${item.salesPrice.toStringAsFixed(2)} EGP', Icons.sell_outlined),
          _MetricData('Purchase cost', '${item.purchasePrice.toStringAsFixed(2)} EGP', Icons.shopping_cart_outlined),
          _MetricData('Gross margin', '${item.grossMargin.toStringAsFixed(2)} EGP', Icons.trending_up_outlined),
          if (item.isInventory) _MetricData('Quantity on hand', '${item.quantityOnHand.toStringAsFixed(2)} ${item.unit ?? ''}', Icons.inventory_outlined),
          if (item.isInventory) _MetricData('Inventory value', '${item.inventoryValue.toStringAsFixed(2)} EGP', Icons.warehouse_outlined),
        ]),
        if (item.isInventory && item.quantityOnHand <= 0) ...[
          const SizedBox(height: 12),
          const _InfoBox(icon: Icons.inventory_outlined, text: 'This inventory item has zero or negative quantity on hand. Use Inventory Adjustment, Receive Inventory, or Bills to update stock correctly.'),
        ],
      ],
    );
  }
}

class _IdentifiersCard extends StatelessWidget {
  const _IdentifiersCard({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.qr_code_2_outlined,
      title: 'Identifiers',
      children: [
        _InfoRow(label: 'Item ID', value: item.id),
        _InfoRow(label: 'SKU / Part No.', value: item.sku ?? '-'),
        _InfoRow(label: 'Barcode', value: item.barcode ?? '-'),
        _InfoRow(label: 'Unit', value: item.unit ?? '-'),
      ],
    );
  }
}

class _PostingAccountsCard extends StatelessWidget {
  const _PostingAccountsCard({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.account_tree_outlined,
      title: 'Posting accounts',
      children: [
        _InfoRow(label: 'Income account', value: _accountValue(item.incomeAccountName, item.incomeAccountId)),
        if (item.isInventory) _InfoRow(label: 'Inventory asset account', value: _accountValue(item.inventoryAssetAccountName, item.inventoryAssetAccountId)),
        if (item.isInventory) _InfoRow(label: 'COGS account', value: _accountValue(item.cogsAccountName, item.cogsAccountId)),
        if (item.isService || item.isNonInventory) _InfoRow(label: 'Expense / purchase account', value: _accountValue(item.expenseAccountName, item.expenseAccountId)),
        if (item.isBundle) const _InfoBox(icon: Icons.widgets_outlined, text: 'Bundle/group items should not post directly. Component items will control income, COGS, and inventory behavior later.'),
      ],
    );
  }

  static String _accountValue(String? name, String? id) {
    if (name?.isNotEmpty == true) return name!;
    if (id?.isNotEmpty == true) return id!;
    return '-';
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.flash_on_outlined,
      title: 'Quick actions',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go('${AppRoutes.invoiceNew}?itemId=${item.id}'),
              icon: const Icon(Icons.description_outlined, size: 16),
              label: const Text('Create invoice'),
            ),
            if (item.isInventory)
              OutlinedButton.icon(
                onPressed: () => context.go('${AppRoutes.inventoryAdjustmentNew}?itemId=${item.id}'),
                icon: const Icon(Icons.tune_outlined, size: 16),
                label: const Text('Inventory adjustment'),
              ),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.itemEdit.replaceFirst(':id', item.id)),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit item'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FutureActivityCard extends StatelessWidget {
  const _FutureActivityCard({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.history_outlined,
      title: 'Related activity',
      children: const [
        _InfoBox(
          icon: Icons.pending_actions_outlined,
          text: 'Activity history is scheduled after invoice, purchase, receive inventory, and adjustment screens are polished. This area will become the item activity center.',
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.children});
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: cs.primaryContainer, child: Icon(icon, color: cs.onPrimaryContainer)),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: metrics.map((metric) => _MetricCard(metric: metric)).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(metric.icon, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metric.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(metric.value, style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 190, child: Text(label, style: TextStyle(color: cs.onSurfaceVariant))),
          Expanded(child: SelectableText(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: cs.onSecondaryContainer), const SizedBox(width: 10), Expanded(child: Text(text, style: TextStyle(color: cs.onSecondaryContainer)))]),
    );
  }
}

IconData _itemIcon(ItemType type) => switch (type) {
      ItemType.inventory => Icons.inventory_2_outlined,
      ItemType.nonInventory => Icons.category_outlined,
      ItemType.service => Icons.design_services_outlined,
      ItemType.bundle => Icons.widgets_outlined,
    };

String _typeDescription(ItemType type) => switch (type) {
      ItemType.inventory => 'Tracks quantity on hand and posts to Inventory Asset and COGS.',
      ItemType.nonInventory => 'Used for goods you buy or sell but do not track as stock.',
      ItemType.service => 'Used for services you sell, purchase, or charge back to customers.',
      ItemType.bundle => 'Groups multiple items; component-driven posting will be added later.',
    };

String _missingAccountText(ItemModel item) {
  if (item.isInventory) return 'Inventory Part requires Income, Inventory Asset, and COGS accounts before it is safe for posting.';
  if (item.isService || item.isNonInventory) return 'This item needs at least an Income account or Expense/Purchase account before it is safe for posting.';
  if (item.isBundle) return 'Bundle/group items should not have direct income posting. Posting should come from component items later.';
  return 'This item has incomplete posting setup.';
}

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
                itemAsync
                        .whenData(
                          (item) => _ToolBtn(
                            icon: Icons.edit_outlined,
                            label: l10n.edit,
                            onPressed: () => context.go(
                              AppRoutes.itemEdit.replaceFirst(':id', id),
                            ),
                          ),
                        )
                        .value ??
                    const SizedBox.shrink(),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(
            child: itemAsync.when(
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
                          children: [left, const SizedBox(height: 16), right],
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
                  _ActivityCard(item: item),
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                _itemIcon(item.itemType),
                color: cs.onPrimaryContainer,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(_itemTypeLabel(item.itemType, l10n)),
                        avatar: Icon(_itemIcon(item.itemType), size: 18),
                      ),
                      Chip(
                        label: Text(
                          item.isActive ? l10n.active : l10n.inactive,
                        ),
                        avatar: Icon(
                          item.isActive
                              ? Icons.check_circle_outline
                              : Icons.block_outlined,
                          size: 18,
                        ),
                      ),
                      if (item.barcode?.isNotEmpty == true)
                        Chip(label: Text(l10n.barcodeValue(item.barcode!))),
                      if (item.sku?.isNotEmpty == true)
                        Chip(label: Text(l10n.partNoValue(item.sku!))),
                      if (!item.hasRequiredPostingAccounts)
                        Chip(
                          label: Text(l10n.needsAccountSetup),
                          avatar: const Icon(
                            Icons.warning_amber_outlined,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _typeDescription(item.itemType, l10n),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _missingAccountText(item, l10n),
              style: TextStyle(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
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
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.price_change_outlined,
      title: l10n.salesPurchaseAndStock,
      children: [
        _MetricGrid(
          metrics: [
            _MetricData(
              l10n.salesPrice,
              '${item.salesPrice.toStringAsFixed(2)} ${l10n.egp}',
              Icons.sell_outlined,
            ),
            _MetricData(
              l10n.purchaseCost,
              '${item.purchasePrice.toStringAsFixed(2)} ${l10n.egp}',
              Icons.shopping_cart_outlined,
            ),
            _MetricData(
              l10n.grossMargin,
              '${item.grossMargin.toStringAsFixed(2)} ${l10n.egp}',
              Icons.trending_up_outlined,
            ),
            if (item.isInventory)
              _MetricData(
                l10n.quantityOnHand,
                '${item.quantityOnHand.toStringAsFixed(2)} ${item.unit ?? ''}',
                Icons.inventory_outlined,
              ),
            if (item.isInventory)
              _MetricData(
                l10n.inventoryValue,
                '${item.inventoryValue.toStringAsFixed(2)} ${l10n.egp}',
                Icons.warehouse_outlined,
              ),
          ],
        ),
        if (item.isInventory && item.quantityOnHand <= 0) ...[
          const SizedBox(height: 12),
          _InfoBox(
            icon: Icons.inventory_outlined,
            text: l10n.zeroNegativeStockHint,
          ),
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
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.qr_code_2_outlined,
      title: l10n.identifiers,
      children: [
        _InfoRow(label: l10n.itemId, value: item.id),
        _InfoRow(label: l10n.barcode, value: item.barcode ?? '-'),
        _InfoRow(label: l10n.partNoSku, value: item.sku ?? '-'),
        _InfoRow(label: l10n.unit, value: item.unit ?? '-'),
      ],
    );
  }
}

class _PostingAccountsCard extends StatelessWidget {
  const _PostingAccountsCard({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.account_tree_outlined,
      title: l10n.postingAccountsLower,
      children: [
        _InfoRow(
          label: l10n.incomeAccountLower,
          value: _accountValue(item.incomeAccountName, item.incomeAccountId),
        ),
        if (item.isInventory)
          _InfoRow(
            label: l10n.inventoryAssetAccount,
            value: _accountValue(
              item.inventoryAssetAccountName,
              item.inventoryAssetAccountId,
            ),
          ),
        if (item.isInventory)
          _InfoRow(
            label: l10n.cogsAccount,
            value: _accountValue(item.cogsAccountName, item.cogsAccountId),
          ),
        if (item.isService || item.isNonInventory)
          _InfoRow(
            label: l10n.expensePurchaseAccountLower,
            value: _accountValue(
              item.expenseAccountName,
              item.expenseAccountId,
            ),
          ),
        if (item.isBundle)
          _InfoBox(
            icon: Icons.widgets_outlined,
            text: l10n.bundleDirectPostingHint,
          ),
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
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.flash_on_outlined,
      title: l10n.quickActions,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  context.go('${AppRoutes.invoiceNew}?itemId=${item.id}'),
              icon: const Icon(Icons.description_outlined, size: 16),
              label: Text(l10n.createInvoice),
            ),
            if (item.isInventory)
              OutlinedButton.icon(
                onPressed: () => context.go(
                  '${AppRoutes.inventoryAdjustmentNew}?itemId=${item.id}',
                ),
                icon: const Icon(Icons.tune_outlined, size: 16),
                label: Text(l10n.inventoryAdjustment),
              ),
            OutlinedButton.icon(
              onPressed: () =>
                  context.go(AppRoutes.itemEdit.replaceFirst(':id', item.id)),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(l10n.editItemLower),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.history_outlined,
      title: l10n.relatedActivity,
      children: [
        _InfoBox(
          icon: Icons.receipt_long_outlined,
          text: item.isInventory
              ? l10n.itemInventoryActivityTrail
              : l10n.itemSalesPurchaseActivityTrail,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });
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
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(icon, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
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
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(metric.icon, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.value,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
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
          SizedBox(
            width: 190,
            child: Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
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
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: cs.onSecondaryContainer)),
          ),
        ],
      ),
    );
  }
}

IconData _itemIcon(ItemType type) => switch (type) {
  ItemType.inventory => Icons.inventory_2_outlined,
  ItemType.nonInventory => Icons.category_outlined,
  ItemType.service => Icons.design_services_outlined,
  ItemType.bundle => Icons.widgets_outlined,
  ItemType.inventoryAssembly => Icons.precision_manufacturing_outlined,
  ItemType.fixedAsset => Icons.business_center_outlined,
  ItemType.otherCharge => Icons.add_card_outlined,
  ItemType.subtotal => Icons.functions_outlined,
  ItemType.group => Icons.view_module_outlined,
  ItemType.discount => Icons.percent_outlined,
  ItemType.payment => Icons.payments_outlined,
};

String _typeDescription(ItemType type, AppLocalizations l10n) => switch (type) {
  ItemType.inventory => l10n.typeHintInventory,
  ItemType.nonInventory => l10n.typeHintNonInventory,
  ItemType.service => l10n.typeHintService,
  ItemType.bundle => l10n.typeHintBundle,
  ItemType.inventoryAssembly => l10n.typeHintInventoryAssembly,
  ItemType.fixedAsset => l10n.typeHintFixedAsset,
  ItemType.otherCharge => l10n.typeHintOtherCharge,
  ItemType.subtotal => l10n.typeHintSubtotal,
  ItemType.group => l10n.typeHintGroup,
  ItemType.discount => l10n.typeHintDiscount,
  ItemType.payment => l10n.typeHintPayment,
};

String _itemTypeLabel(ItemType type, AppLocalizations l10n) => switch (type) {
  ItemType.inventory => l10n.typeInventoryPart,
  ItemType.nonInventory => l10n.typeNonInventoryPart,
  ItemType.service => l10n.typeService,
  ItemType.bundle => l10n.typeBundle,
  ItemType.inventoryAssembly => l10n.typeInventoryAssembly,
  ItemType.fixedAsset => l10n.typeFixedAsset,
  ItemType.otherCharge => l10n.typeOtherCharge,
  ItemType.subtotal => l10n.typeSubtotal,
  ItemType.group => l10n.typeGroup,
  ItemType.discount => l10n.typeDiscount,
  ItemType.payment => l10n.typePayment,
};

String _missingAccountText(ItemModel item, AppLocalizations l10n) {
  if (item.isInventory) return l10n.missingAccountInventory;
  if (item.isService ||
      item.isNonInventory ||
      item.isOtherCharge ||
      item.isDiscount) {
    return l10n.missingAccountSalesPurchase;
  }
  if (item.isFixedAsset) return l10n.missingAccountFixedAsset;
  if (item.isPayment) return l10n.missingAccountPayment;
  if (item.isBundle || item.isSubtotal) return l10n.missingAccountComponent;
  return l10n.missingAccountGeneric;
}

// item_details_screen.dart
// item_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/item_model.dart';
import '../providers/items_provider.dart';

class ItemDetailsScreen extends ConsumerWidget {
  const ItemDetailsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الصنف'),
        actions: [
          itemAsync.whenData((item) => AppButton(
                label:   'تعديل',
                icon:    Icons.edit_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go(
                  AppRoutes.itemEdit.replaceFirst(':id', id),
                ),
              )).value ??
              const SizedBox.shrink(),
          const SizedBox(width: 12),
        ],
      ),
      body: itemAsync.when(
        loading: () => const LoadingWidget(),
        error:   (e, _) => Center(child: Text(e.toString())),
        data: (item) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Type Badge + Name ──────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width:  80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _itemIcon(item.itemType),
                      size:  36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(item.name,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Chip(
                    label:   Text(item.itemType.label),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Price Cards ────────────────────────
            Row(
              children: [
                Expanded(
                  child: _PriceCard(
                    label:  'سعر البيع',
                    amount: item.salesPrice,
                    color:  Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PriceCard(
                    label:  'سعر الشراء',
                    amount: item.purchasePrice,
                  ),
                ),
                if (item.isInventory) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PriceCard(
                      label:  'الكمية',
                      amount: item.quantityOnHand,
                      unit:   item.unit ?? 'قطعة',
                      color:  item.quantityOnHand > 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // ── Info ──────────────────────────────
            if (item.sku != null)
              _InfoTile(
                  icon:  Icons.qr_code_outlined,
                  label: 'كود الصنف (SKU)',
                  value: item.sku!),
            if (item.barcode != null)
              _InfoTile(
                  icon:  Icons.barcode_reader,
                  label: 'الباركود',
                  value: item.barcode!),
            if (item.unit != null)
              _InfoTile(
                  icon:  Icons.scale_outlined,
                  label: 'وحدة القياس',
                  value: item.unit!),
            _InfoTile(
                icon:  Icons.circle,
                label: 'الحالة',
                value: item.isActive ? 'نشط' : 'غير نشط'),

            // ── Accounts ──────────────────────────
            if (item.incomeAccountName != null ||
                item.inventoryAssetAccountName != null ||
                item.cogsAccountName != null ||
                item.expenseAccountName != null) ...[
              const SizedBox(height: 16),
              Text('الحسابات المرتبطة',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (item.incomeAccountName != null)
                _InfoTile(
                    icon:  Icons.trending_up_outlined,
                    label: 'حساب الإيرادات',
                    value: item.incomeAccountName!),
              if (item.inventoryAssetAccountName != null)
                _InfoTile(
                    icon:  Icons.inventory_2_outlined,
                    label: 'حساب أصول المخزون',
                    value: item.inventoryAssetAccountName!),
              if (item.cogsAccountName != null)
                _InfoTile(
                    icon:  Icons.price_change_outlined,
                    label: 'حساب تكلفة المبيعات',
                    value: item.cogsAccountName!),
              if (item.expenseAccountName != null)
                _InfoTile(
                    icon:  Icons.receipt_long_outlined,
                    label: 'حساب المصروفات',
                    value: item.expenseAccountName!),
            ],

            const SizedBox(height: 32),

            // ── Quick Actions ─────────────────────
            Text('إجراءات سريعة',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing:    8,
              runSpacing: 8,
              children: [
                AppButton(
                  label:   'فاتورة مبيعات',
                  icon:    Icons.description_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.go(
                    '${AppRoutes.invoiceNew}?itemId=$id',
                  ),
                ),
                if (item.isInventory)
                  AppButton(
                    label:   'تسوية مخزون',
                    icon:    Icons.tune_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.go(
                      '${AppRoutes.inventoryAdjustmentNew}?itemId=$id',
                    ),
                  ),
              ],
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

// ─── Sub-widgets ──────────────────────────────────

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.label,
    required this.amount,
    this.color,
    this.unit,
  });
  final String  label;
  final double  amount;
  final Color?  color;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              unit != null
                  ? '${amount.toStringAsFixed(2)} $unit'
                  : '${amount.toStringAsFixed(2)} ج.م',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon,
              size:  18,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.4)),
          const SizedBox(width: 12),
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.6),
                  )),
          const Spacer(),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
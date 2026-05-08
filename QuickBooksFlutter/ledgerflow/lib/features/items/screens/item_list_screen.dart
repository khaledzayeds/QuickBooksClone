// item_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/api/api_result.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/item_model.dart';
import '../providers/items_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/item_search_bar.dart';

class ItemListScreen extends ConsumerStatefulWidget {
  const ItemListScreen({super.key});

  @override
  ConsumerState<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends ConsumerState<ItemListScreen> {
  int? _selectedType;
  bool _includeInactive = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item List'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(itemsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          _ActionsMenu(onComingSoon: _showComingSoon),
          _NewItemMenu(
            onCreate: (type) =>
                context.go('${AppRoutes.itemNew}?type=${type.value}'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: items.when(
        loading: () => const SkeletonList(),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          message: 'Could not load items',
          description: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.read(itemsProvider.notifier).refresh(),
        ),
        data: (list) {
          final active = list.where((i) => i.isActive).length;
          final inactive = list.length - active;
          final inventory = list.where((i) => i.isInventory).toList();
          final stockValue = inventory.fold<double>(
            0,
            (sum, item) => sum + item.inventoryValue,
          );
          final missingPosting = list
              .where((i) => !i.hasRequiredPostingAccounts)
              .length;
          final lowOrZeroStock = inventory
              .where((i) => i.quantityOnHand <= 0)
              .length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory Center',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage inventory parts, non-inventory parts, services, and bundle/group items with QuickBooks-style posting behavior.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SummaryChip(
                          icon: Icons.inventory_2_outlined,
                          label: 'Items',
                          value: list.length.toString(),
                        ),
                        _SummaryChip(
                          icon: Icons.check_circle_outline,
                          label: 'Active',
                          value: active.toString(),
                        ),
                        _SummaryChip(
                          icon: Icons.block_outlined,
                          label: 'Inactive',
                          value: inactive.toString(),
                        ),
                        _SummaryChip(
                          icon: Icons.warehouse_outlined,
                          label: 'Stock value',
                          value: '${stockValue.toStringAsFixed(2)} EGP',
                        ),
                        _SummaryChip(
                          icon: Icons.warning_amber_outlined,
                          label: 'Missing accounts',
                          value: missingPosting.toString(),
                        ),
                        _SummaryChip(
                          icon: Icons.inventory_outlined,
                          label: 'Zero/low stock',
                          value: lowOrZeroStock.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final search = ItemSearchBar(
                      onChanged: (v) =>
                          ref.read(itemsProvider.notifier).setSearch(v),
                    );
                    final type = DropdownButtonFormField<int?>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All item types'),
                        ),
                        ...ItemType.values.map(
                          (t) => DropdownMenuItem<int?>(
                            value: t.value,
                            child: Text(t.label),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedType = v);
                        ref.read(itemsProvider.notifier).setTypeFilter(v);
                      },
                    );
                    final inactiveSwitch = SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includeInactive,
                      title: const Text('Include inactive'),
                      onChanged: (v) {
                        setState(() => _includeInactive = v);
                        ref.read(itemsProvider.notifier).setIncludeInactive(v);
                      },
                    );

                    if (!wide) {
                      return Column(
                        children: [
                          search,
                          const SizedBox(height: 10),
                          type,
                          inactiveSwitch,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(flex: 2, child: search),
                        const SizedBox(width: 12),
                        SizedBox(width: 280, child: type),
                        const SizedBox(width: 12),
                        SizedBox(width: 220, child: inactiveSwitch),
                      ],
                    );
                  },
                ),
              ),
              _TypeTabs(
                selectedType: _selectedType,
                onChanged: (type) {
                  setState(() => _selectedType = type?.value);
                  ref.read(itemsProvider.notifier).setTypeFilter(type?.value);
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: list.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.inventory_2_outlined,
                        message: 'No items found',
                        description:
                            'Create a new item or import a list from Excel later.',
                        actionLabel: 'New Item',
                        onAction: () => context.go(AppRoutes.itemNew),
                      )
                    : _GroupedItemList(
                        items: list,
                        onToggleActive: _toggleActive,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title is scheduled in the Items productivity backlog.'),
      ),
    );
  }

  Future<void> _toggleActive(ItemModel item) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: item.isActive ? 'Make item inactive' : 'Make item active',
      message: item.isActive
          ? 'Make "${item.name}" inactive?'
          : 'Make "${item.name}" active?',
    );
    if (confirmed != true || !mounted) return;

    final ApiResult<ItemModel> result = await ref
        .read(itemsProvider.notifier)
        .toggleActive(item.id, !item.isActive);

    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.isActive ? 'Item made inactive' : 'Item made active',
          ),
        ),
      ),
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}

class _GroupedItemList extends StatelessWidget {
  const _GroupedItemList({required this.items, required this.onToggleActive});
  final List<ItemModel> items;
  final Future<void> Function(ItemModel item) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final grouped = <ItemType, List<ItemModel>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.itemType, () => []).add(item);
    }
    final ordered = ItemType.values.where(grouped.containsKey).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ordered.length,
      itemBuilder: (context, groupIndex) {
        final type = ordered[groupIndex];
        final groupItems = grouped[type]!
          ..sort((a, b) => a.name.compareTo(b.name));
        final groupValue = groupItems.fold<double>(
          0,
          (sum, item) => sum + item.inventoryValue,
        );
        final missing = groupItems
            .where((item) => !item.hasRequiredPostingAccounts)
            .length;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(
              type.label,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              '${groupItems.length} items${groupValue > 0 ? ' • ${groupValue.toStringAsFixed(2)} EGP stock value' : ''}${missing > 0 ? ' • $missing missing account links' : ''}',
            ),
            children: groupItems
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: ItemCard(
                      item: item,
                      onTap: () => context.go(
                        AppRoutes.itemDetails.replaceFirst(':id', item.id),
                      ),
                      onEdit: () => context.go(
                        AppRoutes.itemEdit.replaceFirst(':id', item.id),
                      ),
                      onToggleActive: () => onToggleActive(item),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _TypeTabs extends StatelessWidget {
  const _TypeTabs({required this.selectedType, required this.onChanged});
  final int? selectedType;
  final ValueChanged<ItemType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedType == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          ...ItemType.values.map(
            (type) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(type.label),
                selected: selectedType == type.value,
                onSelected: (_) => onChanged(type),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewItemMenu extends StatelessWidget {
  const _NewItemMenu({required this.onCreate});
  final ValueChanged<ItemType> onCreate;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ItemType>(
      tooltip: 'New Item',
      onSelected: onCreate,
      itemBuilder: (context) => ItemType.values
          .map(
            (type) => PopupMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(_icon(type), size: 18),
                  const SizedBox(width: 10),
                  Text(type.label),
                ],
              ),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('New Item'),
        ),
      ),
    );
  }

  IconData _icon(ItemType type) => switch (type) {
    ItemType.inventory => Icons.inventory_2_outlined,
    ItemType.nonInventory => Icons.category_outlined,
    ItemType.service => Icons.design_services_outlined,
    ItemType.bundle => Icons.widgets_outlined,
  };
}

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({required this.onComingSoon});
  final ValueChanged<String> onComingSoon;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Item actions',
      onSelected: onComingSoon,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'Add/Edit Multiple Items',
          child: _MenuRow(
            icon: Icons.grid_on_outlined,
            label: 'Add/Edit Multiple Items',
          ),
        ),
        PopupMenuItem(
          value: 'Import Items from Excel/CSV',
          child: _MenuRow(
            icon: Icons.upload_file_outlined,
            label: 'Import Items from Excel/CSV',
          ),
        ),
        PopupMenuItem(
          value: 'Export Items to Excel/CSV',
          child: _MenuRow(
            icon: Icons.download_outlined,
            label: 'Export Items to Excel/CSV',
          ),
        ),
        PopupMenuItem(
          value: 'Download Import Template',
          child: _MenuRow(
            icon: Icons.description_outlined,
            label: 'Download Import Template',
          ),
        ),
        PopupMenuItem(
          value: 'Change Item Prices',
          child: _MenuRow(
            icon: Icons.price_change_outlined,
            label: 'Change Item Prices',
          ),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(Icons.more_vert),
            SizedBox(width: 4),
            Text('Actions'),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(value),
        ],
      ),
    );
  }
}

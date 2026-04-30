// item_list_screen.dart
// item_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/api/api_result.dart';
import '../../../core/widgets/app_button.dart';
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
  int?  _selectedType;
  bool  _includeInactive = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأصناف'),
        actions: [
          AppButton(
            label:     'صنف جديد',
            icon:      Icons.add_box_outlined,
            onPressed: () => context.go(AppRoutes.itemNew),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // ── Filters ───────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ItemSearchBar(
                    onChanged: (v) =>
                        ref.read(itemsProvider.notifier).setSearch(v),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<int?>(
                  value: _selectedType,
                  hint: const Text('كل الأنواع'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('كل الأنواع')),
                    ...ItemType.values.map((t) => DropdownMenuItem(
                          value: t.value,
                          child: Text(t.label),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedType = v);
                    ref.read(itemsProvider.notifier).setTypeFilter(v);
                  },
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _includeInactive,
                      onChanged: (v) {
                        setState(() => _includeInactive = v!);
                        ref
                            .read(itemsProvider.notifier)
                            .setIncludeInactive(v!);
                      },
                    ),
                    const Text('غير نشط'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── List ──────────────────────────────────
          Expanded(
            child: items.when(
              loading: () => const SkeletonList(),
              error: (e, _) => EmptyStateWidget(
                icon:        Icons.error_outline,
                message:     'تعذر تحميل الأصناف',
                description: e.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () =>
                    ref.read(itemsProvider.notifier).refresh(),
              ),
              data: (list) => list.isEmpty
                  ? EmptyStateWidget(
                      icon:        Icons.inventory_2_outlined,
                      message:     'لا توجد أصناف',
                      description: 'ابدأ بإضافة صنف جديد',
                      actionLabel: 'صنف جديد',
                      onAction: () => context.go(AppRoutes.itemNew),
                    )
                  : ListView.separated(
                      padding:  const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) => ItemCard(
                        item:   list[i],
                        onTap:  () => context.go(
                          AppRoutes.itemDetails
                              .replaceFirst(':id', list[i].id),
                        ),
                        onEdit: () => context.go(
                          AppRoutes.itemEdit
                              .replaceFirst(':id', list[i].id),
                        ),
                        onToggleActive: () => _toggleActive(list[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(ItemModel item) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title:   item.isActive ? 'تعطيل الصنف' : 'تفعيل الصنف',
      message: item.isActive
          ? 'هل تريد تعطيل "${item.name}"؟'
          : 'هل تريد تفعيل "${item.name}"؟',
    );
    if (!confirmed! || !mounted) return;

    final ApiResult<ItemModel> result = await ref
        .read(itemsProvider.notifier)
        .toggleActive(item.id, !item.isActive);

    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              item.isActive ? 'تم تعطيل الصنف' : 'تم تفعيل الصنف'),
        ),
      ),
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}
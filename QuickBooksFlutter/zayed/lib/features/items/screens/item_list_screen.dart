// item_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../../app/router.dart';
import '../../../core/api/api_result.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/item_model.dart';
import '../providers/items_provider.dart';
import '../utils/item_excel_workbooks.dart';
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
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _ToolStrip(
            l10n: l10n,
            onRefresh: () => ref.read(itemsProvider.notifier).refresh(),
            onClose: () => context.go(AppRoutes.dashboard),
            onNewItem: (type) =>
                context.go('${AppRoutes.itemNew}?type=${type.value}'),
            onBulkEdit: () => context.go(AppRoutes.itemBulkEdit),
            onImport: () => context.go(AppRoutes.itemImport),
            onExportCsv: _exportCsv,
            onExportExcel: _exportExcel,
            onDownloadTemplate: _downloadTemplate,
            onChangePrices: () => _showPriceChangeDialog(items.value ?? []),
            onBarcodeCenter: () => context.go(AppRoutes.itemBarcodeCenter),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 34,
                    child: ItemSearchBar(
                      onChanged: (v) =>
                          ref.read(itemsProvider.notifier).setSearch(v),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.type,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          l10n.allItemTypes,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...ItemType.values.map(
                        (t) => DropdownMenuItem<int?>(
                          value: t.value,
                          child: Text(
                            _itemTypeLabel(t, l10n),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedType = v);
                      ref.read(itemsProvider.notifier).setTypeFilter(v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(l10n.includeInactive, style: theme.textTheme.bodySmall),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: _includeInactive,
                    onChanged: (v) {
                      setState(() => _includeInactive = v);
                      ref.read(itemsProvider.notifier).setIncludeInactive(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Metric strip
          items.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (list) {
              final active = list.where((i) => i.isActive).length;
              final stockVal = list
                  .where((i) => i.isInventory)
                  .fold<double>(0, (s, i) => s + i.inventoryValue);
              final missing = list
                  .where((i) => !i.hasRequiredPostingAccounts)
                  .length;
              final lowStock = list
                  .where((i) => i.isInventory && i.quantityOnHand <= 0)
                  .length;
              return Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _M(l10n.items, '${list.length}', cs),
                    _D(cs),
                    _M(l10n.active, '$active', cs),
                    _D(cs),
                    _M(
                      l10n.stockValue,
                      '${stockVal.toStringAsFixed(0)} ${l10n.egp}',
                      cs,
                    ),
                    _D(cs),
                    _M(l10n.missingAccounts, '$missing', cs, warn: missing > 0),
                    _D(cs),
                    _M(l10n.zeroLowStock, '$lowStock', cs, warn: lowStock > 0),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: items.when(
              loading: () => const SkeletonList(),
              error: (e, _) => EmptyStateWidget(
                icon: Icons.error_outline,
                message: l10n.couldNotLoadItems,
                description: e.toString(),
                actionLabel: l10n.retry,
                onAction: () => ref.read(itemsProvider.notifier).refresh(),
              ),
              data: (list) => list.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.inventory_2_outlined,
                      message: l10n.noItemsFound,
                      description: l10n.createNewItemOrImport,
                      actionLabel: l10n.newItem,
                      onAction: () => context.go(AppRoutes.itemNew),
                    )
                  : _DenseItemCenter(
                      items: list,
                      l10n: l10n,
                      onToggleActive: _toggleActive,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref.read(itemsProvider.notifier).exportCsv();
    if (!mounted) return;
    result.when(
      success: (csvString) async {
        try {
          final dir =
              await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
          final file = File(
            '${dir.path}/items-export-${DateTime.now().millisecondsSinceEpoch}.csv',
          );
          await file.writeAsString(csvString);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.csvSaved(file.path)),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(label: l10n.ok, onPressed: () {}),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.exportFailed(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }

  Future<void> _exportExcel() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref.read(itemsProvider.notifier).exportItemsJson();
    if (!mounted) return;
    result.when(
      success: (rows) async {
        try {
          final bytes = buildItemExportWorkbookBytes(rows);
          final dir =
              await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
          final file = File(
            '${dir.path}/items-export-${DateTime.now().millisecondsSinceEpoch}.xlsx',
          );
          await file.writeAsBytes(bytes);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.excelSaved(file.path)),
              duration: const Duration(seconds: 5),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.excelExportFailed(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final dir =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/zayed-items-import-template.xlsx');
      await file.writeAsBytes(buildItemImportTemplateBytes());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.excelTemplateSaved(file.path)),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: l10n.ok, onPressed: () {}),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedWithError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showPriceChangeDialog(List<ItemModel> items) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _PriceChangeDialog(
        items: items,
        l10n: l10n,
        onConfirm: (ids, target, mode, value) async {
          Navigator.of(ctx).pop();
          final result = await ref
              .read(itemsProvider.notifier)
              .bulkPriceChange(
                itemIds: ids,
                target: target,
                mode: mode,
                value: value,
              );
          if (!mounted) return;
          result.when(
            success: (count) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.itemsUpdatedSuccessfully(count))),
            ),
            failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message), backgroundColor: Colors.red),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleActive(ItemModel item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context: context,
      title: item.isActive ? l10n.makeInactive : l10n.makeActive,
      message: item.isActive
          ? l10n.deactivateItemConfirm(item.name)
          : l10n.activateItemConfirm(item.name),
    );
    if (confirmed != true || !mounted) return;
    final ApiResult<ItemModel> result = await ref
        .read(itemsProvider.notifier)
        .toggleActive(item.id, !item.isActive);
    if (!mounted) return;
    result.when(
      success: (_) {},
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}

// ── Tool Strip ───────────────────────────────────────────────────────────────
class _ToolStrip extends StatelessWidget {
  const _ToolStrip({
    required this.l10n,
    required this.onRefresh,
    required this.onClose,
    required this.onNewItem,
    required this.onBulkEdit,
    required this.onImport,
    required this.onExportCsv,
    required this.onExportExcel,
    required this.onDownloadTemplate,
    required this.onChangePrices,
    required this.onBarcodeCenter,
  });
  final AppLocalizations l10n;
  final VoidCallback onRefresh;
  final VoidCallback onClose;
  final ValueChanged<ItemType> onNewItem;
  final VoidCallback onBulkEdit;
  final VoidCallback onImport;
  final VoidCallback onExportCsv;
  final VoidCallback onExportExcel;
  final VoidCallback onDownloadTemplate;
  final VoidCallback onChangePrices;
  final VoidCallback onBarcodeCenter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    vd() => VerticalDivider(
      width: 14,
      indent: 10,
      endIndent: 10,
      color: cs.outlineVariant,
    );

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          _Btn(icon: Icons.refresh, label: l10n.refresh, onTap: onRefresh),
          vd(),
          // Actions menu
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            onSelected: (v) {
              if (v == 'multi') onBulkEdit();
              if (v == 'import') onImport();
              if (v == 'export_csv') onExportCsv();
              if (v == 'export_excel') onExportExcel();
              if (v == 'template') onDownloadTemplate();
              if (v == 'prices') onChangePrices();
              if (v == 'barcodes') onBarcodeCenter();
            },
            child: _Btn(
              icon: Icons.more_vert,
              label: l10n.itemActions,
              onTap: null,
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'multi',
                child: _MRow(
                  icon: Icons.table_chart_outlined,
                  label: l10n.addEditMultipleItems,
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: _MRow(
                  icon: Icons.upload_file_outlined,
                  label: l10n.importItemsExcelCsv,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'export_csv',
                child: _MRow(
                  icon: Icons.table_rows_outlined,
                  label: l10n.exportToCsv,
                ),
              ),
              PopupMenuItem(
                value: 'export_excel',
                child: _MRow(
                  icon: Icons.grid_on_outlined,
                  label: l10n.exportToExcel,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'template',
                child: _MRow(
                  icon: Icons.description_outlined,
                  label: l10n.downloadImportTemplate,
                ),
              ),
              PopupMenuItem(
                value: 'prices',
                child: _MRow(
                  icon: Icons.price_change_outlined,
                  label: l10n.changeItemPrices,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'barcodes',
                child: _MRow(
                  icon: Icons.qr_code_2_outlined,
                  label: l10n.barcodeCenterPrintLabels,
                ),
              ),
            ],
          ),
          vd(),
          // New item menu
          PopupMenuButton<ItemType>(
            offset: const Offset(0, 40),
            onSelected: onNewItem,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 15, color: cs.onPrimary),
                  const SizedBox(width: 5),
                  Text(
                    l10n.newText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 16, color: cs.onPrimary),
                ],
              ),
            ),
            itemBuilder: (_) => ItemType.values
                .map(
                  (t) => PopupMenuItem(
                    value: t,
                    child: _MRow(
                      icon: _icon(t),
                      label: _itemTypeLabel(t, l10n),
                    ),
                  ),
                )
                .toList(),
          ),
          const Spacer(),
          _Btn(icon: Icons.close, label: l10n.close, onTap: onClose),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  IconData _icon(ItemType t) => switch (t) {
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
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: cs.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MRow extends StatelessWidget {
  const _MRow({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [Icon(icon, size: 17), const SizedBox(width: 10), Text(label)],
  );
}

// ── Metric ───────────────────────────────────────────────────────────────────
class _M extends StatelessWidget {
  const _M(this.label, this.value, this.cs, {this.warn = false});
  final String label, value;
  final ColorScheme cs;
  final bool warn;
  @override
  Widget build(BuildContext context) => Center(
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: warn ? cs.error : cs.primary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _D extends StatelessWidget {
  const _D(this.cs);
  final ColorScheme cs;
  @override
  Widget build(BuildContext context) => VerticalDivider(
    width: 18,
    indent: 9,
    endIndent: 9,
    color: cs.outlineVariant,
  );
}

// ── Dense Item Center ────────────────────────────────────────────────────────
class _DenseItemCenter extends StatefulWidget {
  const _DenseItemCenter({
    required this.items,
    required this.l10n,
    required this.onToggleActive,
  });
  final List<ItemModel> items;
  final AppLocalizations l10n;
  final Future<void> Function(ItemModel) onToggleActive;

  @override
  State<_DenseItemCenter> createState() => _DenseItemCenterState();
}

class _DenseItemCenterState extends State<_DenseItemCenter> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = [...widget.items]
      ..sort((a, b) {
        final type = a.itemType.value.compareTo(b.itemType.value);
        return type == 0 ? a.name.compareTo(b.name) : type;
      });
    final selected = sorted.isEmpty
        ? null
        : sorted.firstWhere(
            (item) => item.id == _selectedId,
            orElse: () => sorted.first,
          );
    if (selected != null && _selectedId != selected.id) {
      _selectedId = selected.id;
    }

    return Row(
      children: [
        SizedBox(
          width: 350,
          child: Column(
            children: [
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                color: cs.surfaceContainerHighest,
                child: Row(
                  children: [
                    Expanded(flex: 5, child: _MiniHead(widget.l10n.name)),
                    Expanded(
                      flex: 3,
                      child: _MiniHead(widget.l10n.price, end: true),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (ctx, index) {
                    final item = sorted[index];
                    return _ItemListEntry(
                      item: item,
                      selected: item.id == selected?.id,
                      onTap: () => setState(() => _selectedId = item.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: cs.outlineVariant),
        Expanded(
          child: selected == null
              ? Center(
                  child: Text(
                    widget.l10n.noItemsFound,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : _ItemInfoPane(
                  item: selected,
                  l10n: widget.l10n,
                  onOpen: () => context.go(
                    AppRoutes.itemDetails.replaceFirst(':id', selected.id),
                  ),
                  onEdit: () => context.go(
                    AppRoutes.itemEdit.replaceFirst(':id', selected.id),
                  ),
                  onToggleActive: () => widget.onToggleActive(selected),
                ),
        ),
      ],
    );
  }
}

class _ItemListEntry extends StatelessWidget {
  const _ItemListEntry({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final ItemModel item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color: selected ? cs.primary.withValues(alpha: 0.16) : null,
        child: Row(
          children: [
            Icon(
              _rowIcon(item.itemType),
              size: 15,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Expanded(
              flex: 5,
              child: Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: item.isActive ? null : cs.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                item.salesPrice.toStringAsFixed(2),
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniHead extends StatelessWidget {
  const _MiniHead(this.label, {this.end = false});
  final String label;
  final bool end;
  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: end ? TextAlign.end : TextAlign.start,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w900,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    overflow: TextOverflow.ellipsis,
  );
}

class _ItemInfoPane extends StatelessWidget {
  const _ItemInfoPane({
    required this.item,
    required this.l10n,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleActive,
  });
  final ItemModel item;
  final AppLocalizations l10n;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.itemInformation,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.open,
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_outlined),
              ),
              IconButton(
                tooltip: l10n.edit,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(42, 18, 22, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoLine(l10n.name, item.name),
                      _InfoLine(l10n.type, _itemTypeLabel(item.itemType, l10n)),
                      _InfoLine(l10n.barcode, item.barcode ?? '-'),
                      _InfoLine(l10n.partNo, item.sku ?? '-'),
                      _InfoLine(l10n.unit, item.unit ?? '-'),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ValueBox(
                            l10n.salesPrice,
                            '${item.salesPrice.toStringAsFixed(2)} ${l10n.egp}',
                          ),
                          _ValueBox(
                            l10n.purchaseCost,
                            '${item.purchasePrice.toStringAsFixed(2)} ${l10n.egp}',
                          ),
                          _ValueBox(
                            l10n.onHand,
                            item.isInventory
                                ? '${item.quantityOnHand.toStringAsFixed(2)} ${item.unit ?? ''}'
                                : '-',
                          ),
                          _ValueBox(
                            l10n.inventoryValue,
                            '${item.inventoryValue.toStringAsFixed(2)} ${l10n.egp}',
                            highlight: item.inventoryValue > 0,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(42, 8, 22, 12),
                color: cs.surface,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(l10n.editItem),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onToggleActive,
                      icon: const Icon(Icons.toggle_on_outlined, size: 16),
                      label: Text(
                        item.isActive
                            ? l10n.makeInactiveTitle
                            : l10n.makeActiveTitle,
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (item.isInventory)
                      OutlinedButton.icon(
                        onPressed: () => context.go(
                          '${AppRoutes.inventoryAdjustmentNew}?itemId=${item.id}',
                        ),
                        icon: const Icon(Icons.tune_outlined, size: 16),
                        label: Text(l10n.adjustStock),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: _MiniActivityTable(item: item, l10n: l10n),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _ValueBox extends StatelessWidget {
  const _ValueBox(this.label, this.value, {this.highlight = false});
  final String label;
  final String value;
  final bool highlight;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _MiniActivityTable extends StatelessWidget {
  const _MiniActivityTable({required this.item, required this.l10n});
  final ItemModel item;
  final AppLocalizations l10n;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          color: cs.surfaceContainerHighest,
          child: Text(
            l10n.transactions,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(child: _MiniHead(l10n.type)),
              Expanded(child: _MiniHead(l10n.date)),
              Expanded(child: _MiniHead(l10n.account)),
              Expanded(child: _MiniHead(l10n.amount, end: true)),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              item.isInventory
                  ? l10n.stockActivityHint
                  : l10n.salesPurchaseActivityHint,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}

IconData _rowIcon(ItemType type) => switch (type) {
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

// ── Price Change Dialog ───────────────────────────────────────────────────────
class _PriceChangeDialog extends StatefulWidget {
  const _PriceChangeDialog({
    required this.items,
    required this.l10n,
    required this.onConfirm,
  });
  final List<ItemModel> items;
  final AppLocalizations l10n;
  final void Function(List<String> ids, int target, int mode, double value)
  onConfirm;

  @override
  State<_PriceChangeDialog> createState() => _PriceChangeDialogState();
}

class _PriceChangeDialogState extends State<_PriceChangeDialog> {
  int _target = 1; // 1=Sales 2=Purchase 3=Both
  int _mode = 1; // 1=SetFixed 2=+Amt 3=+% 4=-Amt 5=-%
  final _valueCtrl = TextEditingController(text: '0');
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.items.where((i) => i.isActive).map((i) => i.id));
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = widget.l10n;
    final value = double.tryParse(_valueCtrl.text) ?? 0;
    final modeLabel = switch (_mode) {
      1 => l10n.setFixedPriceTo,
      2 => l10n.increaseByAmount,
      3 => l10n.increaseByPercent,
      4 => l10n.decreaseByAmount,
      5 => l10n.decreaseByPercent,
      _ => '',
    };

    return Dialog(
      child: SizedBox(
        width: 680,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.price_change_outlined,
                    color: cs.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.changeItemPrices,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target + Mode + Value in one row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _target,
                          decoration: InputDecoration(
                            labelText: l10n.applyTo,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 1,
                              child: Text(l10n.salesPrice),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(l10n.purchaseCost),
                            ),
                            DropdownMenuItem(value: 3, child: Text(l10n.both)),
                          ],
                          onChanged: (v) => setState(() => _target = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _mode,
                          decoration: InputDecoration(
                            labelText: l10n.method,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 1,
                              child: Text(l10n.setFixedPrice),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(l10n.increaseByAmount),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text(l10n.increaseByPercent),
                            ),
                            DropdownMenuItem(
                              value: 4,
                              child: Text(l10n.decreaseByAmount),
                            ),
                            DropdownMenuItem(
                              value: 5,
                              child: Text(l10n.decreaseByPercent),
                            ),
                          ],
                          onChanged: (v) => setState(() => _mode = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _valueCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: _mode == 3 || _mode == 5
                                ? l10n.percent
                                : l10n.amountEgp,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$modeLabel ${value.toStringAsFixed(2)}${_mode == 3 || _mode == 5 ? '%' : ' ${l10n.egp}'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Item selector
                  Row(
                    children: [
                      Text(
                        l10n.selectItems(_selected.length, widget.items.length),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(
                          () => _selected.addAll(widget.items.map((i) => i.id)),
                        ),
                        child: Text(l10n.all),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selected.clear()),
                        child: Text(l10n.none),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      itemCount: widget.items.length,
                      itemBuilder: (_, i) {
                        final item = widget.items[i];
                        final checked = _selected.contains(item.id);
                        return CheckboxListTile(
                          dense: true,
                          value: checked,
                          onChanged: (v) => setState(
                            () => v!
                                ? _selected.add(item.id)
                                : _selected.remove(item.id),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            l10n.salesCostLine(
                              item.salesPrice.toStringAsFixed(2),
                              item.purchasePrice.toStringAsFixed(2),
                            ),
                            style: const TextStyle(fontSize: 11),
                          ),
                          secondary: Text(
                            _itemTypeLabel(item.itemType, l10n),
                            style: TextStyle(fontSize: 11, color: cs.primary),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _selected.isEmpty || value <= 0
                        ? null
                        : () => widget.onConfirm(
                            _selected.toList(),
                            _target,
                            _mode,
                            value,
                          ),
                    icon: const Icon(Icons.price_change_outlined, size: 16),
                    label: Text(l10n.applyToItemCount(_selected.length)),
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

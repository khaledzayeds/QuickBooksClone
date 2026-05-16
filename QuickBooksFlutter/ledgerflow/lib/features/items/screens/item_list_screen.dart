// item_list_screen.dart
import 'dart:io';
import 'package:excel/excel.dart' hide Border, TextSpan;
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
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _ToolStrip(
            onRefresh: () => ref.read(itemsProvider.notifier).refresh(),
            onClose: () => Navigator.of(context).maybePop(),
            onNewItem: (type) => context.go('${AppRoutes.itemNew}?type=${type.value}'),
            onBulkEdit: () => context.go(AppRoutes.itemBulkEdit),
            onImport: () => context.go(AppRoutes.itemImport),
            onExportCsv: _exportCsv,
            onExportExcel: _exportExcel,
            onDownloadTemplate: _downloadTemplate,
            onChangePrices: () => _showPriceChangeDialog(items.asData?.value ?? []),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.4))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 34,
                    child: ItemSearchBar(
                      onChanged: (v) => ref.read(itemsProvider.notifier).setSearch(v),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All item types')),
                      ...ItemType.values.map((t) => DropdownMenuItem<int?>(value: t.value, child: Text(t.label))),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedType = v);
                      ref.read(itemsProvider.notifier).setTypeFilter(v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text('Include inactive', style: theme.textTheme.bodySmall),
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
              final stockVal = list.where((i) => i.isInventory).fold<double>(0, (s, i) => s + i.inventoryValue);
              final missing = list.where((i) => !i.hasRequiredPostingAccounts).length;
              final lowStock = list.where((i) => i.isInventory && i.quantityOnHand <= 0).length;
              return Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.4))),
                ),
                child: Row(
                  children: [
                    _M('Items', '${list.length}', cs),
                    _D(cs), _M('Active', '$active', cs),
                    _D(cs), _M('Stock value', '${stockVal.toStringAsFixed(0)} EGP', cs),
                    _D(cs), _M('Missing accounts', '$missing', cs, warn: missing > 0),
                    _D(cs), _M('Zero/low stock', '$lowStock', cs, warn: lowStock > 0),
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
                message: 'Could not load items',
                description: e.toString(),
                actionLabel: l10n.retry,
                onAction: () => ref.read(itemsProvider.notifier).refresh(),
              ),
              data: (list) => list.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.inventory_2_outlined,
                      message: 'No items found',
                      description: 'Create a new item or import a list.',
                      actionLabel: 'New Item',
                      onAction: () => context.go(AppRoutes.itemNew),
                    )
                  : _GroupedList(items: list, onToggleActive: _toggleActive),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    final result = await ref.read(itemsProvider.notifier).exportCsv();
    if (!mounted) return;
    result.when(
      success: (csvString) async {
        try {
          final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/items-export-${DateTime.now().millisecondsSinceEpoch}.csv');
          await file.writeAsString(csvString);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CSV saved: ${file.path}'),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(label: 'OK', onPressed: () {}),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
          );
        }
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }


  Future<void> _exportExcel() async {
    final result = await ref.read(itemsProvider.notifier).exportItemsJson();
    if (!mounted) return;
    result.when(
      success: (rows) async {
        try {
          // Build Excel workbook
          final excel = Excel.createExcel();
          final sheet = excel['Items'];
          excel.delete('Sheet1'); // remove default empty sheet

          // Header row
          final headers = [
            'Name', 'Type', 'SKU', 'Barcode', 'Unit',
            'Sales Price', 'Purchase Cost', 'Qty on Hand', 'Active',
            'Income Account', 'Inventory Asset Account', 'COGS Account', 'Expense Account',
          ];
          for (var i = 0; i < headers.length; i++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
            cell.value = TextCellValue(headers[i]);
            cell.cellStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('#1565C0'), fontColorHex: ExcelColor.fromHexString('#FFFFFF'));
          }

          // Data rows
          for (var r = 0; r < rows.length; r++) {
            final row = rows[r];
            final vals = [
              row['name']?.toString() ?? '',
              row['itemType']?.toString() ?? '',
              row['sku']?.toString() ?? '',
              row['barcode']?.toString() ?? '',
              row['unit']?.toString() ?? '',
              row['salesPrice']?.toString() ?? '0',
              row['purchasePrice']?.toString() ?? '0',
              row['quantityOnHand']?.toString() ?? '0',
              row['isActive'] == true ? 'Yes' : 'No',
              row['incomeAccountName']?.toString() ?? '',
              row['inventoryAssetAccountName']?.toString() ?? '',
              row['cogsAccountName']?.toString() ?? '',
              row['expenseAccountName']?.toString() ?? '',
            ];
            for (var c = 0; c < vals.length; c++) {
              sheet
                  .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
                  .value = TextCellValue(vals[c]);
            }
          }

          // Auto column widths (approximate)
          for (var i = 0; i < headers.length; i++) {
            sheet.setColumnWidth(i, 22);
          }

          final bytes = excel.encode();
          if (bytes == null) throw Exception('Failed to encode Excel file');

          final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/items-export-${DateTime.now().millisecondsSinceEpoch}.xlsx');
          await file.writeAsBytes(bytes);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Excel saved: ${file.path}'), duration: const Duration(seconds: 5)),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Excel export failed: $e'), backgroundColor: Colors.red),
          );
        }
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      const template = 'Name,Type,SKU,Barcode,Unit,Sales Price,Purchase Cost\n'
          'Thermal Printer,Inventory,INV-001,6221000000001,pcs,1500.00,1200.00\n'
          'Maintenance Service,Service,SRV-001,,hr,250.00,0\n'
          'Office Supplies,Non-inventory,OFF-001,,pcs,50.00,35.00\n';
      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/items-import-template.csv');
      await file.writeAsString(template);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template saved: ${file.path}'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showPriceChangeDialog(List<ItemModel> items) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _PriceChangeDialog(
        items: items,
        onConfirm: (ids, target, mode, value) async {
          Navigator.of(ctx).pop();
          final result = await ref.read(itemsProvider.notifier).bulkPriceChange(
            itemIds: ids,
            target: target,
            mode: mode,
            value: value,
          );
          if (!mounted) return;
          result.when(
            success: (count) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Updated $count item(s) successfully.')),
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
    final confirmed = await showConfirmDialog(
      context: context,
      title: item.isActive ? 'Make inactive' : 'Make active',
      message: '${item.isActive ? 'Deactivate' : 'Activate'} "${item.name}"?',
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
    required this.onRefresh,
    required this.onClose,
    required this.onNewItem,
    required this.onBulkEdit,
    required this.onImport,
    required this.onExportCsv,
    required this.onExportExcel,
    required this.onDownloadTemplate,
    required this.onChangePrices,
  });
  final VoidCallback onRefresh;
  final VoidCallback onClose;
  final ValueChanged<ItemType> onNewItem;
  final VoidCallback onBulkEdit;
  final VoidCallback onImport;
  final VoidCallback onExportCsv;
  final VoidCallback onExportExcel;
  final VoidCallback onDownloadTemplate;
  final VoidCallback onChangePrices;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    vd() => VerticalDivider(width: 14, indent: 10, endIndent: 10, color: cs.outlineVariant);

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          _Btn(icon: Icons.refresh, label: 'Refresh', onTap: onRefresh),
          vd(),
          // Actions menu
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            onSelected: (v) {
              if (v == 'multi')        onBulkEdit();
              if (v == 'import')       onImport();
              if (v == 'export_csv')   onExportCsv();
              if (v == 'export_excel') onExportExcel();
              if (v == 'template')     onDownloadTemplate();
              if (v == 'prices')       onChangePrices();
            },
            child: _Btn(icon: Icons.more_vert, label: 'Item actions', onTap: null),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'multi',        child: _MRow(icon: Icons.table_chart_outlined,    label: 'Add/Edit Multiple Items')),
              const PopupMenuItem(value: 'import',       child: _MRow(icon: Icons.upload_file_outlined,    label: 'Import Items from Excel/CSV')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'export_csv',   child: _MRow(icon: Icons.table_rows_outlined,     label: 'Export to CSV')),
              const PopupMenuItem(value: 'export_excel', child: _MRow(icon: Icons.grid_on_outlined,        label: 'Export to Excel (.xlsx)')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'template',     child: _MRow(icon: Icons.description_outlined,    label: 'Download Import Template')),
              const PopupMenuItem(value: 'prices',       child: _MRow(icon: Icons.price_change_outlined,   label: 'Change Item Prices')),
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
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, size: 15, color: cs.onPrimary),
                const SizedBox(width: 5),
                Text('New', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onPrimary)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 16, color: cs.onPrimary),
              ]),
            ),
            itemBuilder: (_) => ItemType.values.map((t) => PopupMenuItem(
              value: t,
              child: _MRow(icon: _icon(t), label: t.label),
            )).toList(),
          ),
          const Spacer(),
          _Btn(icon: Icons.close, label: 'Close', onTap: onClose),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  IconData _icon(ItemType t) => switch (t) {
    ItemType.inventory    => Icons.inventory_2_outlined,
    ItemType.nonInventory => Icons.category_outlined,
    ItemType.service      => Icons.design_services_outlined,
    ItemType.bundle       => Icons.widgets_outlined,
  };
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: cs.primary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
        ]),
      ),
    );
  }
}

class _MRow extends StatelessWidget {
  const _MRow({required this.icon, required this.label});
  final IconData icon; final String label;
  @override
  Widget build(BuildContext context) =>
      Row(children: [Icon(icon, size: 17), const SizedBox(width: 10), Text(label)]);
}

// ── Metric ───────────────────────────────────────────────────────────────────
class _M extends StatelessWidget {
  const _M(this.label, this.value, this.cs, {this.warn = false});
  final String label, value; final ColorScheme cs; final bool warn;
  @override
  Widget build(BuildContext context) => Center(child: RichText(text: TextSpan(style: const TextStyle(fontSize: 11), children: [
    TextSpan(text: '$label: ', style: TextStyle(color: cs.onSurfaceVariant)),
    TextSpan(text: value, style: TextStyle(fontWeight: FontWeight.w900, color: warn ? cs.error : cs.primary)),
  ])));
}

class _D extends StatelessWidget {
  const _D(this.cs);
  final ColorScheme cs;
  @override
  Widget build(BuildContext context) => VerticalDivider(width: 18, indent: 9, endIndent: 9, color: cs.outlineVariant);
}

// ── Grouped List ─────────────────────────────────────────────────────────────
class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.items, required this.onToggleActive});
  final List<ItemModel> items;
  final Future<void> Function(ItemModel) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grouped = <ItemType, List<ItemModel>>{};
    for (final i in items) grouped.putIfAbsent(i.itemType, () => []).add(i);
    final ordered = ItemType.values.where(grouped.containsKey).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ordered.length,
      itemBuilder: (ctx, gi) {
        final type = ordered[gi];
        final group = grouped[type]!..sort((a, b) => a.name.compareTo(b.name));
        final val = group.fold<double>(0, (s, i) => s + i.inventoryValue);
        final miss = group.where((i) => !i.hasRequiredPostingAccounts).length;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
          ),
          child: ExpansionTile(
            initiallyExpanded: true,
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            title: Text(type.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text(
              '${group.length} items${val > 0 ? ' · ${val.toStringAsFixed(2)} EGP' : ''}${miss > 0 ? ' · $miss ⚠' : ''}',
              style: const TextStyle(fontSize: 11),
            ),
            children: group.map((item) => Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
              child: ItemCard(
                item: item,
                onTap: () => ctx.go(AppRoutes.itemDetails.replaceFirst(':id', item.id)),
                onEdit: () => ctx.go(AppRoutes.itemEdit.replaceFirst(':id', item.id)),
                onToggleActive: () => onToggleActive(item),
              ),
            )).toList(),
          ),
        );
      },
    );
  }
}

// ── Price Change Dialog ───────────────────────────────────────────────────────
class _PriceChangeDialog extends StatefulWidget {
  const _PriceChangeDialog({required this.items, required this.onConfirm});
  final List<ItemModel> items;
  final void Function(List<String> ids, int target, int mode, double value) onConfirm;

  @override
  State<_PriceChangeDialog> createState() => _PriceChangeDialogState();
}

class _PriceChangeDialogState extends State<_PriceChangeDialog> {
  int _target = 1; // 1=Sales 2=Purchase 3=Both
  int _mode   = 1; // 1=SetFixed 2=+Amt 3=+% 4=-Amt 5=-%
  final _valueCtrl = TextEditingController(text: '0');
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.items.where((i) => i.isActive).map((i) => i.id));
  }

  @override
  void dispose() { _valueCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = double.tryParse(_valueCtrl.text) ?? 0;
    final modeLabel = switch (_mode) {
      1 => 'Set fixed price to',
      2 => 'Increase by amount',
      3 => 'Increase by %',
      4 => 'Decrease by amount',
      5 => 'Decrease by %',
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(children: [
                Icon(Icons.price_change_outlined, color: cs.onPrimaryContainer),
                const SizedBox(width: 10),
                Text('Change Item Prices', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: cs.onPrimaryContainer)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target + Mode + Value in one row
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _target,
                        decoration: const InputDecoration(labelText: 'Apply to', border: OutlineInputBorder(), isDense: true),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Sales price')),
                          DropdownMenuItem(value: 2, child: Text('Purchase cost')),
                          DropdownMenuItem(value: 3, child: Text('Both')),
                        ],
                        onChanged: (v) => setState(() => _target = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _mode,
                        decoration: const InputDecoration(labelText: 'Method', border: OutlineInputBorder(), isDense: true),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Set fixed price')),
                          DropdownMenuItem(value: 2, child: Text('Increase by amount')),
                          DropdownMenuItem(value: 3, child: Text('Increase by %')),
                          DropdownMenuItem(value: 4, child: Text('Decrease by amount')),
                          DropdownMenuItem(value: 5, child: Text('Decrease by %')),
                        ],
                        onChanged: (v) => setState(() => _mode = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _valueCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: _mode == 3 || _mode == 5 ? 'Percent %' : 'Amount EGP',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text('$modeLabel ${value.toStringAsFixed(2)}${_mode == 3 || _mode == 5 ? '%' : ' EGP'}',
                    style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  // Item selector
                  Row(children: [
                    Text('Select items (${_selected.length}/${widget.items.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const Spacer(),
                    TextButton(onPressed: () => setState(() => _selected.addAll(widget.items.map((i) => i.id))), child: const Text('All')),
                    TextButton(onPressed: () => setState(() => _selected.clear()), child: const Text('None')),
                  ]),
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
                          onChanged: (v) => setState(() => v! ? _selected.add(item.id) : _selected.remove(item.id)),
                          title: Text(item.name, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            'Sales: ${item.salesPrice.toStringAsFixed(2)}  Cost: ${item.purchasePrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          secondary: Text(item.itemType.label, style: TextStyle(fontSize: 11, color: cs.primary)),
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
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _selected.isEmpty || value <= 0
                      ? null
                      : () => widget.onConfirm(_selected.toList(), _target, _mode, value),
                  icon: const Icon(Icons.price_change_outlined, size: 16),
                  label: Text('Apply to ${_selected.length} item(s)'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

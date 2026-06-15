import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../app/router.dart';
import '../../../core/navigation/safe_navigation.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/providers/printing_settings_provider.dart';
import '../data/models/item_model.dart';
import '../providers/items_provider.dart';
import '../services/item_barcode_label_pdf_service.dart';
import '../utils/item_barcode_utils.dart';

enum _BarcodeFilter { all, missing, internal, external, inStock }

class ItemBarcodeCenterScreen extends ConsumerStatefulWidget {
  const ItemBarcodeCenterScreen({super.key});

  @override
  ConsumerState<ItemBarcodeCenterScreen> createState() =>
      _ItemBarcodeCenterScreenState();
}

class _ItemBarcodeCenterScreenState
    extends ConsumerState<ItemBarcodeCenterScreen> {
  final _searchCtrl = TextEditingController();
  final _quantities = <String, int>{};
  _BarcodeFilter _filter = _BarcodeFilter.all;
  ItemBarcodePaper _paper = ItemBarcodePaper.thermal80;
  ItemBarcodeLayout _layout = ItemBarcodeLayout.single;
  bool _useStockQty = false;
  bool _showPrice = true;
  bool _showCompanyName = false;
  bool _printing = false;
  bool _generatingBarcodes = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsProvider);
    final loadedItems = itemsState.maybeWhen(
      data: (items) => items,
      orElse: () => null,
    );
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _toolStrip(context, l10n, loadedItems),
          Expanded(
            child: itemsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _error(error),
              data: (items) {
                final filtered = _filtered(items);
                final totalLabels = _totalLabels(filtered);
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _filtersBar(l10n),
                          _metrics(filtered, totalLabels, l10n),
                          Expanded(child: _itemsList(filtered, l10n)),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: 330,
                      child: _settingsPanel(filtered, totalLabels, l10n),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolStrip(
    BuildContext context,
    AppLocalizations l10n,
    List<ItemModel>? items,
  ) {
    final cs = Theme.of(context).colorScheme;
    final missingCount =
        items
            ?.where(
              (item) => item.isActive && (item.barcode ?? '').trim().isEmpty,
            )
            .length ??
        0;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.arrow_back,
            label: l10n.items,
            onTap: () => context.popOrGo(AppRoutes.items),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.barcodeCenter,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          _ToolButton(
            icon: _generatingBarcodes
                ? Icons.hourglass_empty
                : Icons.qr_code_scanner_outlined,
            label: l10n.generateMissingBarcodesCount(missingCount),
            onTap: missingCount == 0 || _generatingBarcodes
                ? null
                : () => _confirmGenerateMissingBarcodes(missingCount),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.refresh,
            label: l10n.refresh,
            onTap: () => ref.read(itemsProvider.notifier).refresh(),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _filtersBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchNameSkuBarcode,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip(_BarcodeFilter.all, l10n.all),
                _chip(_BarcodeFilter.missing, l10n.missingBarcode),
                _chip(_BarcodeFilter.internal, l10n.internal200),
                _chip(_BarcodeFilter.external, l10n.external),
                _chip(_BarcodeFilter.inStock, l10n.inStock),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(_BarcodeFilter filter, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == filter,
        onSelected: (_) => setState(() => _filter = filter),
      ),
    );
  }

  Widget _metrics(
    List<ItemModel> filtered,
    int totalLabels,
    AppLocalizations l10n,
  ) {
    final withBarcode = filtered
        .where((item) => (item.barcode ?? '').trim().isNotEmpty)
        .length;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          _metric(l10n.items, '${filtered.length}'),
          _metric(l10n.withBarcode, '$withBarcode'),
          _metric(l10n.labels, '$totalLabels'),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsList(List<ItemModel> items, AppLocalizations l10n) {
    if (items.isEmpty) {
      return Center(child: Text(l10n.noItemsMatchFilters));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final qty = _quantityFor(item);
        final hasBarcode = (item.barcode ?? '').trim().isNotEmpty;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(
                  hasBarcode ? Icons.qr_code_2 : Icons.qr_code_2_outlined,
                  color: hasBarcode ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasBarcode
                            ? l10n.barcodeStockLine(
                                item.barcode!,
                                item.quantityOnHand.toStringAsFixed(2),
                              )
                            : l10n.noBarcode,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text('${item.salesPrice.toStringAsFixed(2)} ${l10n.egp}'),
                const SizedBox(width: 14),
                _qtyControl(item, qty, hasBarcode, l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _qtyControl(
    ItemModel item,
    int qty,
    bool enabled,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        IconButton(
          tooltip: l10n.decrease,
          onPressed: !enabled ? null : () => _setQuantity(item, qty - 1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          tooltip: l10n.increase,
          onPressed: !enabled ? null : () => _setQuantity(item, qty + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _settingsPanel(
    List<ItemModel> visibleItems,
    int totalLabels,
    AppLocalizations l10n,
  ) {
    final settings = ref.watch(printingSettingsProvider).settings;
    final printerName = _paper == ItemBarcodePaper.a4
        ? settings.a4PrinterName
        : settings.thermalPrinterName;

    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.printSettings,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ItemBarcodePaper>(
            segments: const [
              ButtonSegment(
                value: ItemBarcodePaper.thermal80,
                label: Text('80mm'),
                icon: Icon(Icons.receipt_long),
              ),
              ButtonSegment(
                value: ItemBarcodePaper.label50x40,
                label: Text('50x40'),
                icon: Icon(Icons.sell_outlined),
              ),
              ButtonSegment(
                value: ItemBarcodePaper.a4,
                label: Text('A4'),
                icon: Icon(Icons.description_outlined),
              ),
            ],
            selected: {_paper},
            onSelectionChanged: (v) {
              setState(() {
                _paper = v.first;
                if (_paper != ItemBarcodePaper.thermal80) {
                  _layout = ItemBarcodeLayout.single;
                }
              });
            },
          ),
          const SizedBox(height: 10),
          if (_paper == ItemBarcodePaper.thermal80)
            SegmentedButton<ItemBarcodeLayout>(
              segments: [
                ButtonSegment(
                  value: ItemBarcodeLayout.single,
                  label: Text(l10n.single),
                ),
                ButtonSegment(
                  value: ItemBarcodeLayout.triple,
                  label: Text(l10n.triple),
                ),
              ],
              selected: {_layout},
              onSelectionChanged: (v) => setState(() => _layout = v.first),
            ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _useStockQty,
            title: Text(l10n.useStockQty),
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) {
              setState(() {
                _useStockQty = v;
                _quantities.clear();
              });
            },
          ),
          SwitchListTile(
            value: _showPrice,
            title: Text(l10n.showSalesPrice),
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _showPrice = v),
          ),
          SwitchListTile(
            value: _showCompanyName,
            title: Text(l10n.showCompanyName),
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _showCompanyName = v),
          ),
          const Divider(height: 24),
          _settingsLine(l10n.selectedLabels, '$totalLabels'),
          _settingsLine(l10n.labelSize, _labelSizeText(l10n)),
          _settingsLine(
            l10n.printer,
            (printerName ?? '').isEmpty
                ? l10n.previewPdfFallback
                : printerName!,
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: totalLabels == 0 || _printing
                ? null
                : () => _preview(visibleItems),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(l10n.previewPdf),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: totalLabels == 0 || _printing
                ? null
                : () => _print(visibleItems),
            icon: _printing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            label: Text(_printing ? l10n.printing : l10n.printLabels),
          ),
        ],
      ),
    );
  }

  Widget _settingsLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(Object error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text(l10n.couldNotLoadItemsWithError(error.toString())),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => ref.read(itemsProvider.notifier).refresh(),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  List<ItemModel> _filtered(List<ItemModel> items) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return items.where((item) {
      final barcode = item.barcode?.trim() ?? '';
      if (query.isNotEmpty) {
        final matches =
            item.name.toLowerCase().contains(query) ||
            (item.sku?.toLowerCase().contains(query) ?? false) ||
            barcode.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return switch (_filter) {
        _BarcodeFilter.all => true,
        _BarcodeFilter.missing => barcode.isEmpty,
        _BarcodeFilter.internal => ItemBarcodeUtils.isInternalInStoreBarcode(
          barcode,
        ),
        _BarcodeFilter.external =>
          barcode.isNotEmpty &&
              !ItemBarcodeUtils.isInternalInStoreBarcode(barcode),
        _BarcodeFilter.inStock => item.quantityOnHand > 0,
      };
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  int _quantityFor(ItemModel item) {
    if (_quantities.containsKey(item.id)) return _quantities[item.id]!;
    if (_useStockQty) {
      return item.quantityOnHand.floor().clamp(0, 9999).toInt();
    }
    return (item.barcode ?? '').trim().isEmpty ? 0 : 1;
  }

  void _setQuantity(ItemModel item, int qty) {
    setState(() {
      _quantities[item.id] = qty.clamp(0, 9999).toInt();
    });
  }

  int _totalLabels(List<ItemModel> items) =>
      items.fold(0, (sum, item) => sum + _quantityFor(item));

  List<ItemBarcodePrintLine> _selectedLines(List<ItemModel> items) {
    return items
        .map(
          (item) =>
              ItemBarcodePrintLine(item: item, quantity: _quantityFor(item)),
        )
        .where(
          (line) =>
              line.quantity > 0 && (line.item.barcode ?? '').trim().isNotEmpty,
        )
        .toList();
  }

  Future<Uint8List> _buildPdf(List<ItemModel> visibleItems) {
    final settings = ref.read(printingSettingsProvider).settings;
    return const ItemBarcodeLabelPdfService().build(
      lines: _selectedLines(visibleItems),
      settings: settings,
      paper: _paper,
      layout: _layout,
      showPrice: _showPrice,
      showCompanyName: _showCompanyName,
      companyName: 'Zayed',
    );
  }

  Future<void> _preview(List<ItemModel> visibleItems) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final bytes = await _buildPdf(visibleItems);
      await Printing.layoutPdf(
        name: 'Zayed_Barcode_Labels',
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      _snack(l10n.couldNotBuildBarcodeLabels(e.toString()), isError: true);
    }
  }

  Future<void> _print(List<ItemModel> visibleItems) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _printing = true);
    try {
      final bytes = await _buildPdf(visibleItems);
      final settings = ref.read(printingSettingsProvider).settings;
      final printerName = _paper == ItemBarcodePaper.a4
          ? settings.a4PrinterName
          : settings.thermalPrinterName;
      if ((printerName ?? '').trim().isEmpty) {
        await Printing.layoutPdf(
          name: 'Zayed_Barcode_Labels',
          onLayout: (_) async => bytes,
        );
      } else {
        await Printing.directPrintPdf(
          printer: Printer(url: printerName!),
          onLayout: (_) async => bytes,
        );
      }
    } catch (e) {
      _snack(l10n.printFailed(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _confirmGenerateMissingBarcodes(int missingCount) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.generateMissingBarcodes),
        content: Text(l10n.generateMissingBarcodesConfirm(missingCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.qr_code_scanner_outlined),
            label: Text(l10n.generate),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _generateMissingBarcodes();
    }
  }

  Future<void> _generateMissingBarcodes() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _generatingBarcodes = true);
    final result = await ref
        .read(itemsProvider.notifier)
        .generateMissingBarcodes();
    if (!mounted) return;
    setState(() {
      _generatingBarcodes = false;
      _filter = _BarcodeFilter.all;
    });
    result.when(
      success: (updatedCount) {
        _snack(l10n.generatedMissingBarcodes(updatedCount));
      },
      failure: (error) {
        _snack(
          l10n.generateMissingBarcodesFailed(error.toString()),
          isError: true,
        );
      },
    );
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  String _labelSizeText(AppLocalizations l10n) => switch (_paper) {
    ItemBarcodePaper.thermal80 =>
      _layout == ItemBarcodeLayout.triple
          ? l10n.roll80Triple
          : l10n.roll80Single,
    ItemBarcodePaper.label50x40 => l10n.label50x40Roll,
    ItemBarcodePaper.a4 => l10n.a4SheetLabels,
  };
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

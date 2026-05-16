// item_bulk_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/safe_navigation.dart';
import '../../../app/router.dart';
import '../data/models/item_model.dart';
import '../providers/items_provider.dart';

class ItemBulkEditScreen extends ConsumerStatefulWidget {
  const ItemBulkEditScreen({super.key});
  @override
  ConsumerState<ItemBulkEditScreen> createState() => _ItemBulkEditScreenState();
}

class _Row {
  final ItemModel item;
  late final TextEditingController nameCtrl;
  late final TextEditingController skuCtrl;
  late final TextEditingController unitCtrl;
  late final TextEditingController salesCtrl;
  late final TextEditingController purchaseCtrl;
  bool isActive;
  bool dirty = false;

  _Row(this.item)
      : isActive = item.isActive {
    nameCtrl     = TextEditingController(text: item.name);
    skuCtrl      = TextEditingController(text: item.sku ?? '');
    unitCtrl     = TextEditingController(text: item.unit ?? '');
    salesCtrl    = TextEditingController(text: item.salesPrice.toStringAsFixed(2));
    purchaseCtrl = TextEditingController(text: item.purchasePrice.toStringAsFixed(2));
  }

  void dispose() {
    nameCtrl.dispose(); skuCtrl.dispose(); unitCtrl.dispose();
    salesCtrl.dispose(); purchaseCtrl.dispose();
  }
}

class _ItemBulkEditScreenState extends ConsumerState<ItemBulkEditScreen> {
  List<_Row> _rows = [];
  bool _loaded = false;
  bool _saving = false;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final r in _rows) r.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await ref.read(itemsRepositoryProvider).getItems(includeInactive: true);
    if (!mounted) return;
    result.when(
      success: (items) {
        setState(() {
          _rows = items.map((i) => _Row(i)).toList();
          _loaded = true;
        });
      },
      failure: (e) {
        setState(() => _loaded = true);
        _snack(e.message, isError: true);
      },
    );
  }

  Future<void> _saveAll() async {
    final dirty = _rows.where((r) => r.dirty).toList();
    if (dirty.isEmpty) { _snack('No changes to save.'); return; }
    setState(() => _saving = true);
    int saved = 0;
    for (final row in dirty) {
      final body = <String, dynamic>{
        'name': row.nameCtrl.text.trim(),
        'itemType': row.item.itemType.value,
        'salesPrice': double.tryParse(row.salesCtrl.text) ?? row.item.salesPrice,
        'purchasePrice': double.tryParse(row.purchaseCtrl.text) ?? row.item.purchasePrice,
        if (row.skuCtrl.text.trim().isNotEmpty) 'sku': row.skuCtrl.text.trim(),
        if (row.unitCtrl.text.trim().isNotEmpty) 'unit': row.unitCtrl.text.trim(),
        'isActive': row.isActive,
        if (row.item.incomeAccountId != null) 'incomeAccountId': row.item.incomeAccountId,
        if (row.item.inventoryAssetAccountId != null) 'inventoryAssetAccountId': row.item.inventoryAssetAccountId,
        if (row.item.cogsAccountId != null) 'cogsAccountId': row.item.cogsAccountId,
        if (row.item.expenseAccountId != null) 'expenseAccountId': row.item.expenseAccountId,
      };
      final result = await ref.read(itemsProvider.notifier).updateItem(row.item.id, body);
      result.when(success: (_) => saved++, failure: (_) {});
    }
    setState(() => _saving = false);
    if (!mounted) return;
    _snack('Saved $saved of ${dirty.length} items.');
    ref.read(itemsProvider.notifier).refresh();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : null),
    );
  }

  List<_Row> get _filtered {
    if (_search.isEmpty) return _rows;
    final q = _search.toLowerCase();
    return _rows.where((r) =>
      r.nameCtrl.text.toLowerCase().contains(q) ||
      r.skuCtrl.text.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dirtyCount = _rows.where((r) => r.dirty).length;
    final rows = _filtered;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // ── Tool Strip
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: Row(children: [
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.popOrGo(AppRoutes.items),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.arrow_back, size: 15, color: cs.primary),
                    const SizedBox(width: 5),
                    Text('Items', style: TextStyle(fontSize: 12, color: cs.onSurface, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              Text('Add / Edit Multiple Items',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 16),
              // search
              SizedBox(
                width: 220,
                height: 30,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search items…',
                    prefixIcon: const Icon(Icons.search, size: 15),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
              ),
              const Spacer(),
              if (dirtyCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('$dirtyCount unsaved changes',
                    style: TextStyle(fontSize: 12, color: cs.error, fontWeight: FontWeight.w600)),
                ),
              if (_saving)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else ...[
                OutlinedButton(
                  onPressed: dirtyCount == 0 ? null : () {
                    for (final r in _rows) { r.dirty = false; }
                    _load();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('Discard', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saveAll,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Save All Changes', style: TextStyle(fontSize: 12)),
                ),
              ],
              const SizedBox(width: 12),
            ]),
          ),

          // ── Header row
          Container(
            height: 32,
            color: cs.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              _H('Item Name', flex: 4),
              _H('SKU', flex: 2),
              _H('Unit', flex: 1),
              _H('Sales Price', flex: 2),
              _H('Purchase Cost', flex: 2),
              _H('Type', flex: 2),
              _H('Active', flex: 1),
            ]),
          ),

          // ── Rows
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                    ? Center(child: Text('No items found.', style: TextStyle(color: cs.onSurfaceVariant)))
                    : ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, i) => _buildRow(rows[i], i, cs),
                      ),
          ),

          // ── Footer
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
            ),
            child: Row(children: [
              Text('${rows.length} items shown · ${_rows.length} total',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_Row row, int index, ColorScheme cs) {
    final bg = index.isEven ? cs.surface : cs.surfaceContainerLowest;
    return Container(
      height: 38,
      color: row.dirty ? cs.primaryContainer.withValues(alpha: 0.3) : bg,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        // Name
        Expanded(flex: 4, child: _EditCell(
          controller: row.nameCtrl,
          onChanged: (_) => setState(() => row.dirty = true),
        )),
        // SKU
        Expanded(flex: 2, child: _EditCell(
          controller: row.skuCtrl,
          onChanged: (_) => setState(() => row.dirty = true),
        )),
        // Unit
        Expanded(flex: 1, child: _EditCell(
          controller: row.unitCtrl,
          onChanged: (_) => setState(() => row.dirty = true),
        )),
        // Sales Price
        Expanded(flex: 2, child: _EditCell(
          controller: row.salesCtrl,
          numeric: true,
          onChanged: (_) => setState(() => row.dirty = true),
        )),
        // Purchase Cost
        Expanded(flex: 2, child: _EditCell(
          controller: row.purchaseCtrl,
          numeric: true,
          onChanged: (_) => setState(() => row.dirty = true),
        )),
        // Type chip
        Expanded(flex: 2, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(row.item.itemType.label,
              style: TextStyle(fontSize: 11, color: cs.onSecondaryContainer),
              overflow: TextOverflow.ellipsis),
          ),
        )),
        // Active toggle
        Expanded(flex: 1, child: Transform.scale(
          scale: 0.7,
          child: Switch(
            value: row.isActive,
            onChanged: (v) => setState(() { row.isActive = v; row.dirty = true; }),
          ),
        )),
      ]),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.label, {required this.flex});
  final String label; final int flex;
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurfaceVariant),
      overflow: TextOverflow.ellipsis),
  );
}

class _EditCell extends StatelessWidget {
  const _EditCell({required this.controller, required this.onChanged, this.numeric = false});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool numeric;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 12),
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: numeric ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))] : null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      ),
    ),
  );
}

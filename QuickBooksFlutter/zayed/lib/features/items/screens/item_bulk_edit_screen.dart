// item_bulk_edit_screen.dart
import 'dart:io';
import 'package:excel/excel.dart' hide Border, TextSpan, BorderStyle;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/navigation/safe_navigation.dart';
import '../../../app/router.dart';
import '../../../core/constants/api_enums.dart' as api;
import '../../../l10n/app_localizations.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../data/models/item_model.dart';
import '../providers/items_provider.dart';

class ItemBulkEditScreen extends ConsumerStatefulWidget {
  const ItemBulkEditScreen({super.key});
  @override
  ConsumerState<ItemBulkEditScreen> createState() => _ItemBulkEditScreenState();
}

class _Row {
  final ItemModel? item;
  late final TextEditingController nameCtrl;
  late final TextEditingController barcodeCtrl;
  late final TextEditingController skuCtrl;
  late final TextEditingController unitCtrl;
  late final TextEditingController salesCtrl;
  late final TextEditingController purchaseCtrl;
  ItemType itemType;
  String? incomeAccountId;
  String? inventoryAssetAccountId;
  String? cogsAccountId;
  String? expenseAccountId;
  bool isActive;
  bool dirty = false;
  bool get isNew => item == null;

  _Row(ItemModel existing)
    : item = existing,
      isActive = existing.isActive,
      itemType = existing.itemType,
      incomeAccountId = existing.incomeAccountId,
      inventoryAssetAccountId = existing.inventoryAssetAccountId,
      cogsAccountId = existing.cogsAccountId,
      expenseAccountId = existing.expenseAccountId {
    nameCtrl = TextEditingController(text: existing.name);
    barcodeCtrl = TextEditingController(text: existing.barcode ?? '');
    skuCtrl = TextEditingController(text: existing.sku ?? '');
    unitCtrl = TextEditingController(text: existing.unit ?? '');
    salesCtrl = TextEditingController(
      text: existing.salesPrice.toStringAsFixed(2),
    );
    purchaseCtrl = TextEditingController(
      text: existing.purchasePrice.toStringAsFixed(2),
    );
  }

  _Row.newItem({
    String name = '',
    String barcode = '',
    String sku = '',
    String unit = 'pcs',
    double salesPrice = 0,
    double purchasePrice = 0,
    this.itemType = ItemType.inventory,
    this.incomeAccountId,
    this.inventoryAssetAccountId,
    this.cogsAccountId,
    this.expenseAccountId,
  }) : item = null,
       isActive = true,
       dirty = true {
    nameCtrl = TextEditingController(text: name);
    barcodeCtrl = TextEditingController(text: barcode);
    skuCtrl = TextEditingController(text: sku);
    unitCtrl = TextEditingController(text: unit);
    salesCtrl = TextEditingController(text: salesPrice.toStringAsFixed(2));
    purchaseCtrl = TextEditingController(
      text: purchasePrice.toStringAsFixed(2),
    );
  }

  void dispose() {
    nameCtrl.dispose();
    barcodeCtrl.dispose();
    skuCtrl.dispose();
    unitCtrl.dispose();
    salesCtrl.dispose();
    purchaseCtrl.dispose();
  }
}

class _ItemBulkEditScreenState extends ConsumerState<ItemBulkEditScreen> {
  List<_Row> _rows = [];
  List<AccountModel> _accounts = [];
  bool _loaded = false;
  bool _accountsLoaded = false;
  bool _saving = false;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _load();
  }

  @override
  void dispose() {
    for (final r in _rows) r.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await ref
        .read(itemsRepositoryProvider)
        .getItems(includeInactive: true);
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

  Future<void> _loadAccounts() async {
    final result = await ref
        .read(accountsRepositoryProvider)
        .getAccounts(includeInactive: false);
    if (!mounted) return;
    result.when(
      success: (accounts) {
        setState(() {
          _accounts = accounts;
          _accountsLoaded = true;
        });
      },
      failure: (_) => setState(() => _accountsLoaded = true),
    );
  }

  Future<void> _saveAll() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _BulkEditText.of(context);
    final dirty = _rows
        .where((r) => r.dirty && r.nameCtrl.text.trim().isNotEmpty)
        .toList();
    if (dirty.isEmpty) {
      _snack(text.noChangesToSave);
      return;
    }
    setState(() => _saving = true);
    int saved = 0;
    for (final row in dirty) {
      final body = <String, dynamic>{
        'name': row.nameCtrl.text.trim(),
        'itemType': row.itemType.value,
        'salesPrice':
            double.tryParse(row.salesCtrl.text) ?? row.item?.salesPrice ?? 0,
        'purchasePrice':
            double.tryParse(row.purchaseCtrl.text) ??
            row.item?.purchasePrice ??
            0,
        if (row.barcodeCtrl.text.trim().isNotEmpty)
          'barcode': row.barcodeCtrl.text.trim(),
        if (row.skuCtrl.text.trim().isNotEmpty) 'sku': row.skuCtrl.text.trim(),
        if (row.unitCtrl.text.trim().isNotEmpty)
          'unit': row.unitCtrl.text.trim(),
        if (row.isNew && _tracksInventory(row.itemType)) 'quantityOnHand': 0,
        if (row.incomeAccountId != null) 'incomeAccountId': row.incomeAccountId,
        if (row.inventoryAssetAccountId != null)
          'inventoryAssetAccountId': row.inventoryAssetAccountId,
        if (row.cogsAccountId != null) 'cogsAccountId': row.cogsAccountId,
        if (row.expenseAccountId != null)
          'expenseAccountId': row.expenseAccountId,
      };
      final result = row.isNew
          ? await ref.read(itemsProvider.notifier).createItem(body)
          : await ref
                .read(itemsProvider.notifier)
                .updateItem(row.item!.id, body);
      await result.when(
        success: (savedItem) async {
          saved++;
          if (!row.isActive && savedItem.isActive) {
            await ref
                .read(itemsProvider.notifier)
                .toggleActive(savedItem.id, false);
          } else if (!row.isNew && row.isActive != row.item!.isActive) {
            await ref
                .read(itemsProvider.notifier)
                .toggleActive(row.item!.id, row.isActive);
          }
        },
        failure: (_) async {},
      );
    }
    setState(() => _saving = false);
    if (!mounted) return;
    _snack(l10n.itemsUpdatedSuccessfully(saved));
    ref.read(itemsProvider.notifier).refresh();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  List<_Row> get _filtered {
    if (_search.isEmpty) return _rows;
    final q = _search.toLowerCase();
    return _rows
        .where(
          (r) =>
              r.nameCtrl.text.toLowerCase().contains(q) ||
              r.barcodeCtrl.text.toLowerCase().contains(q) ||
              r.skuCtrl.text.toLowerCase().contains(q),
        )
        .toList();
  }

  void _addRows([int count = 5]) {
    setState(() {
      for (var i = 0; i < count; i++) {
        final row = _Row.newItem();
        _applyDefaultAccounts(row, force: true);
        _rows.insert(0, row);
      }
    });
  }

  void _applyDefaultAccounts(_Row row, {bool force = false}) {
    if (_accounts.isEmpty) return;
    String? find(List<api.AccountType> types, List<String> keywords) {
      final pool = _accounts
          .where((a) => a.isActive && types.contains(a.accountType))
          .toList();
      for (final keyword in keywords) {
        final match = pool.cast<AccountModel?>().firstWhere(
          (a) => a!.name.toLowerCase().contains(keyword),
          orElse: () => null,
        );
        if (match != null) return match.id;
      }
      return pool.isEmpty ? null : pool.first.id;
    }

    if (force || row.incomeAccountId == null) {
      row.incomeAccountId = find(
        [api.AccountType.income, api.AccountType.otherIncome],
        ['sales income', 'sales', 'income'],
      );
    }
    if (force || row.inventoryAssetAccountId == null) {
      row.inventoryAssetAccountId = find(
        [api.AccountType.inventoryAsset, api.AccountType.otherCurrentAsset],
        ['inventory asset', 'inventory'],
      );
    }
    if (force || row.cogsAccountId == null) {
      row.cogsAccountId = find(
        [api.AccountType.costOfGoodsSold],
        ['cost of goods', 'cogs'],
      );
    }
    if (force || row.expenseAccountId == null) {
      row.expenseAccountId = find(
        [
          api.AccountType.expense,
          api.AccountType.otherExpense,
          api.AccountType.costOfGoodsSold,
        ],
        ['expense', 'cost'],
      );
    }
  }

  void _applyDefaultAccountsToRows({required bool allRows}) {
    setState(() {
      for (final row in _rows) {
        if (allRows || row.isNew) {
          _applyDefaultAccounts(row, force: true);
          row.dirty = true;
        }
      }
    });
    _snack(
      allRows
          ? _BulkEditText.of(context).accountsAppliedAllRows
          : _BulkEditText.of(context).accountsAppliedNewRows,
    );
  }

  Future<void> _importRows() async {
    final text = _BulkEditText.of(context);
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );
    final path = picked?.files.single.path;
    if (!mounted) return;
    if (path == null) return;

    final imported = path.toLowerCase().endsWith('.csv')
        ? await _readCsvRows(path)
        : await _readExcelRows(path);
    if (imported.isEmpty) {
      _snack(text.noValidRowsFound, isError: true);
      return;
    }
    setState(() {
      for (final row in imported.reversed) {
        _applyDefaultAccounts(row, force: true);
        _rows.insert(0, row);
      }
    });
    _snack(text.importedRows(imported.length));
  }

  Future<List<_Row>> _readCsvRows(String path) async {
    final lines = await File(path).readAsLines();
    if (lines.length < 2) return [];
    final headers = _splitCsv(lines.first).map((h) => h.toLowerCase()).toList();
    final rows = <_Row>[];
    for (var i = 1; i < lines.length; i++) {
      final cells = _splitCsv(lines[i]);
      final row = _rowFromCells(
        headers,
        (idx) => cells.elementAtOrNull(idx) ?? '',
      );
      if (row != null) rows.add(row);
    }
    return rows;
  }

  Future<List<_Row>> _readExcelRows(String path) async {
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.firstOrNull;
    if (sheet == null || sheet.rows.length < 2) return [];
    final headers = sheet.rows.first
        .map((c) => c?.value?.toString().toLowerCase() ?? '')
        .toList();
    final rows = <_Row>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      final cells = sheet.rows[i];
      final row = _rowFromCells(
        headers,
        (idx) => cells.elementAtOrNull(idx)?.value?.toString() ?? '',
      );
      if (row != null) rows.add(row);
    }
    return rows;
  }

  _Row? _rowFromCells(List<String> headers, String Function(int idx) cell) {
    int idx(String key, int fallback) {
      final found = headers.indexWhere((h) => h.contains(key));
      return found >= 0 ? found : fallback;
    }

    final name = cell(idx('name', 0)).trim();
    if (name.isEmpty) return null;
    final typeText = cell(idx('type', 1));
    final barcode = cell(idx('barcode', 2)).trim();
    final unit = cell(idx('unit', 3)).trim();
    final sales =
        double.tryParse(cell(idx('sales', 4)).replaceAll(',', '')) ?? 0;
    final purchase =
        double.tryParse(cell(idx('purchase', 5)).replaceAll(',', '')) ?? 0;
    final skuIndex = headers.indexWhere(
      (h) => h.contains('sku') || h.contains('part'),
    );
    return _Row.newItem(
      name: name,
      itemType: _parseType(typeText),
      barcode: barcode,
      unit: unit.isEmpty ? 'pcs' : unit,
      salesPrice: sales,
      purchasePrice: purchase,
      sku: skuIndex >= 0 ? cell(skuIndex).trim() : '',
    );
  }

  List<String> _splitCsv(String line) {
    final result = <String>[];
    var inQuotes = false;
    final buffer = StringBuffer();
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    result.add(buffer.toString());
    return result;
  }

  Future<void> _exportExcel() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _BulkEditText.of(context);
    final excel = Excel.createExcel();
    final sheet = excel['Items'];
    excel.delete('Sheet1');
    final headers = [
      'Name',
      'Type',
      'Barcode',
      'Unit',
      'Sales Price',
      'Purchase Cost',
      'Part No. (optional)',
      'Active',
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1f7a1f'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }
    for (var r = 0; r < _rows.length; r++) {
      final row = _rows[r];
      final values = [
        row.nameCtrl.text,
        row.itemType.label,
        row.barcodeCtrl.text,
        row.unitCtrl.text,
        row.salesCtrl.text,
        row.purchaseCtrl.text,
        row.skuCtrl.text,
        row.isActive ? 'Yes' : 'No',
      ];
      for (var c = 0; c < values.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(
          values[c],
        );
      }
    }
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 22);
    }
    final bytes = excel.encode();
    if (bytes == null) {
      _snack(text.excelExportFailed, isError: true);
      return;
    }
    final dir =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/items-bulk-${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(bytes);
    _snack(l10n.excelSaved(file.path));
  }

  Future<void> _showBulkAccountsDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _BulkEditText.of(context);
    String? income = _rows
        .map((r) => r.incomeAccountId)
        .firstWhere((id) => id != null, orElse: () => null);
    String? asset = _rows
        .map((r) => r.inventoryAssetAccountId)
        .firstWhere((id) => id != null, orElse: () => null);
    String? cogs = _rows
        .map((r) => r.cogsAccountId)
        .firstWhere((id) => id != null, orElse: () => null);
    String? expense = _rows
        .map((r) => r.expenseAccountId)
        .firstWhere((id) => id != null, orElse: () => null);
    var target = 'new';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.postingAccounts),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'new', label: Text(text.newRows)),
                    ButtonSegment(value: 'all', label: Text(text.allRows)),
                  ],
                  selected: {target},
                  onSelectionChanged: (v) =>
                      setDialogState(() => target = v.first),
                ),
                const SizedBox(height: 14),
                _AccountDrop(
                  label: l10n.depositPaymentAccountRequired,
                  value: income,
                  accounts: _filterAccounts([
                    api.AccountType.income,
                    api.AccountType.otherIncome,
                  ]),
                  onChanged: (v) => setDialogState(() => income = v),
                ),
                const SizedBox(height: 10),
                _AccountDrop(
                  label: l10n.inventoryAssetAccount,
                  value: asset,
                  accounts: _filterAccounts([
                    api.AccountType.inventoryAsset,
                    api.AccountType.otherCurrentAsset,
                  ]),
                  onChanged: (v) => setDialogState(() => asset = v),
                ),
                const SizedBox(height: 10),
                _AccountDrop(
                  label: l10n.cogsAccount,
                  value: cogs,
                  accounts: _filterAccounts([api.AccountType.costOfGoodsSold]),
                  onChanged: (v) => setDialogState(() => cogs = v),
                ),
                const SizedBox(height: 10),
                _AccountDrop(
                  label: l10n.expensePurchaseAccount,
                  value: expense,
                  accounts: _filterAccounts([
                    api.AccountType.expense,
                    api.AccountType.otherExpense,
                    api.AccountType.costOfGoodsSold,
                  ]),
                  onChanged: (v) => setDialogState(() => expense = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  for (final row in _rows) {
                    if (target == 'all' || row.isNew) {
                      row.incomeAccountId = income;
                      row.inventoryAssetAccountId = asset;
                      row.cogsAccountId = cogs;
                      row.expenseAccountId = expense;
                      row.dirty = true;
                    }
                  }
                });
                Navigator.of(ctx).pop();
                _snack(
                  target == 'all'
                      ? text.accountsAppliedAllRows
                      : text.accountsAppliedNewRows,
                );
              },
              child: Text(l10n.apply),
            ),
          ],
        ),
      ),
    );
  }

  List<AccountModel> _filterAccounts(List<api.AccountType> types) =>
      _accounts
          .where((a) => a.isActive && types.contains(a.accountType))
          .toList()
        ..sort((a, b) => a.code.compareTo(b.code));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final text = _BulkEditText.of(context);
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
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => context.popOrGo(AppRoutes.items),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 15, color: cs.primary),
                        const SizedBox(width: 5),
                        Text(
                          l10n.itemsAndServices,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.addEditMultipleItems,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 16),
                // search
                SizedBox(
                  width: 220,
                  height: 30,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: l10n.searchNameSkuBarcode,
                      prefixIcon: const Icon(Icons.search, size: 15),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _addRows(1),
                  icon: const Icon(Icons.add, size: 15),
                  label: Text(
                    text.addRow,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: _importRows,
                  icon: const Icon(Icons.upload_file_outlined, size: 15),
                  label: Text(
                    l10n.importItems,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: _exportExcel,
                  icon: const Icon(Icons.grid_on_outlined, size: 15),
                  label: Text(
                    l10n.exportExcel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: text.bulkAccountsAndTools,
                  icon: const Icon(Icons.more_vert, size: 19),
                  onSelected: (value) {
                    if (value == 'defaults_new') {
                      _applyDefaultAccountsToRows(allRows: false);
                    }
                    if (value == 'defaults_all') {
                      _applyDefaultAccountsToRows(allRows: true);
                    }
                    if (value == 'accounts') _showBulkAccountsDialog();
                    if (value == 'add5') _addRows(5);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'add5',
                      child: _MenuRow(
                        icon: Icons.add_box_outlined,
                        label: text.addFiveBlankRows,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'accounts',
                      enabled: _accountsLoaded && _accounts.isNotEmpty,
                      child: _MenuRow(
                        icon: Icons.tune_outlined,
                        label: text.chooseAccounts,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'defaults_new',
                      enabled: _accountsLoaded && _accounts.isNotEmpty,
                      child: _MenuRow(
                        icon: Icons.auto_fix_high_outlined,
                        label: text.applyDefaultsNewRows,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'defaults_all',
                      enabled: _accountsLoaded && _accounts.isNotEmpty,
                      child: _MenuRow(
                        icon: Icons.account_tree_outlined,
                        label: text.applyDefaultsAllRows,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (dirtyCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      text.unsavedChanges(dirtyCount),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: dirtyCount == 0
                        ? null
                        : () {
                            for (final r in _rows) {
                              r.dirty = false;
                            }
                            _load();
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Text(
                      text.discard,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saveAll,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      text.saveAllChanges,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
              ],
            ),
          ),

          // ── Header row
          Container(
            height: 32,
            color: cs.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _H(l10n.name, flex: 4),
                _H(l10n.barcode, flex: 3),
                _H(l10n.partNo, flex: 2),
                _H(l10n.unit, flex: 1),
                _H(l10n.salesPrice, flex: 2),
                _H(l10n.purchaseCost, flex: 2),
                _H(l10n.type, flex: 2),
                _H(l10n.active, flex: 1),
              ],
            ),
          ),

          // ── Rows
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                ? Center(
                    child: Text(
                      l10n.noItemsFound,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) =>
                        _buildRow(rows[i], i, cs, l10n),
                  ),
          ),

          // ── Footer
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  text.itemsShown(rows.length, _rows.length),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_Row row, int index, ColorScheme cs, AppLocalizations l10n) {
    final bg = index.isEven ? cs.surface : cs.surfaceContainerLowest;
    return Container(
      height: 38,
      color: row.dirty ? cs.primaryContainer.withValues(alpha: 0.3) : bg,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 4,
            child: _EditCell(
              controller: row.nameCtrl,
              onChanged: (_) => setState(() => row.dirty = true),
            ),
          ),
          // Barcode
          Expanded(
            flex: 3,
            child: _EditCell(
              controller: row.barcodeCtrl,
              onChanged: (_) => setState(() => row.dirty = true),
            ),
          ),
          // Part No.
          Expanded(
            flex: 2,
            child: _EditCell(
              controller: row.skuCtrl,
              onChanged: (_) => setState(() => row.dirty = true),
            ),
          ),
          // Unit
          Expanded(
            flex: 1,
            child: _EditCell(
              controller: row.unitCtrl,
              onChanged: (_) => setState(() => row.dirty = true),
            ),
          ),
          // Sales Price
          Expanded(
            flex: 2,
            child: _EditCell(
              controller: row.salesCtrl,
              numeric: true,
              onChanged: (_) => setState(() => row.dirty = true),
            ),
          ),
          // Purchase Cost
          Expanded(
            flex: 2,
            child: _EditCell(
              controller: row.purchaseCtrl,
              numeric: true,
              onChanged: (_) => setState(() => row.dirty = true),
            ),
          ),
          // Type
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ItemType>(
                  value: row.itemType,
                  isDense: true,
                  isExpanded: true,
                  style: TextStyle(fontSize: 11, color: cs.onSurface),
                  items: ItemType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            _itemTypeLabel(type, l10n),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (type) {
                    if (type == null) return;
                    setState(() {
                      row.itemType = type;
                      _applyDefaultAccounts(row);
                      row.dirty = true;
                    });
                  },
                ),
              ),
            ),
          ),
          // Active toggle
          Expanded(
            flex: 1,
            child: Transform.scale(
              scale: 0.7,
              child: Switch(
                value: row.isActive,
                onChanged: (v) => setState(() {
                  row.isActive = v;
                  row.dirty = true;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ItemType _parseType(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('service')) return ItemType.service;
    if (lower.contains('non')) return ItemType.nonInventory;
    if (lower.contains('assembly')) return ItemType.inventoryAssembly;
    if (lower.contains('fixed')) return ItemType.fixedAsset;
    if (lower.contains('charge')) return ItemType.otherCharge;
    if (lower.contains('subtotal')) return ItemType.subtotal;
    if (lower.contains('group')) return ItemType.group;
    if (lower.contains('discount')) return ItemType.discount;
    if (lower.contains('payment')) return ItemType.payment;
    if (lower.contains('bundle')) return ItemType.bundle;
    return ItemType.inventory;
  }

  static bool _tracksInventory(ItemType type) =>
      type == ItemType.inventory || type == ItemType.inventoryAssembly;

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
}

class _BulkEditText {
  const _BulkEditText(this.ar);

  final bool ar;

  static _BulkEditText of(BuildContext context) =>
      _BulkEditText(Localizations.localeOf(context).languageCode == 'ar');

  String get addRow => ar ? 'إضافة صف' : 'Add Row';
  String get bulkAccountsAndTools =>
      ar ? 'الحسابات والأدوات الجماعية' : 'Bulk accounts and tools';
  String get addFiveBlankRows => ar ? 'إضافة 5 صفوف فارغة' : 'Add 5 blank rows';
  String get chooseAccounts => ar ? 'اختيار الحسابات...' : 'Choose accounts...';
  String get applyDefaultsNewRows => ar
      ? 'تطبيق الحسابات الافتراضية على الصفوف الجديدة'
      : 'Apply default accounts to new rows';
  String get applyDefaultsAllRows => ar
      ? 'تطبيق الحسابات الافتراضية على كل الصفوف'
      : 'Apply default accounts to all rows';
  String get discard => ar ? 'تجاهل' : 'Discard';
  String get saveAllChanges => ar ? 'حفظ كل التعديلات' : 'Save All Changes';
  String get noChangesToSave =>
      ar ? 'لا توجد تعديلات للحفظ.' : 'No changes to save.';
  String get noValidRowsFound =>
      ar ? 'لم يتم العثور على صفوف صالحة.' : 'No valid rows found.';
  String get excelExportFailed =>
      ar ? 'فشل تصدير Excel.' : 'Excel export failed.';
  String get newRows => ar ? 'الصفوف الجديدة' : 'New rows';
  String get allRows => ar ? 'كل الصفوف' : 'All rows';
  String get accountsAppliedAllRows =>
      ar ? 'تم تطبيق الحسابات على كل الصفوف.' : 'Accounts applied to all rows.';
  String get accountsAppliedNewRows => ar
      ? 'تم تطبيق الحسابات على الصفوف الجديدة.'
      : 'Accounts applied to new rows.';

  String unsavedChanges(int count) =>
      ar ? '$count تعديل غير محفوظ' : '$count unsaved changes';

  String itemsShown(int shown, int total) => ar
      ? '$shown صنف ظاهر · $total إجمالي'
      : '$shown items shown · $total total';

  String importedRows(int count) => ar
      ? 'تم استيراد $count صف. راجع البيانات ثم احفظ كل التعديلات.'
      : 'Imported $count row(s). Review then Save All Changes.';
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17),
      const SizedBox(width: 10),
      Flexible(child: Text(label)),
    ],
  );
}

class _AccountDrop extends StatelessWidget {
  const _AccountDrop({
    required this.label,
    required this.value,
    required this.accounts,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<AccountModel> accounts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String?>(
    value: accounts.any((a) => a.id == value) ? value : null,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    items: [
      DropdownMenuItem<String?>(
        value: null,
        child: Text(AppLocalizations.of(context)!.notSelected),
      ),
      ...accounts.map(
        (account) => DropdownMenuItem<String?>(
          value: account.id,
          child: Text(
            '${account.code} - ${account.name}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ],
    onChanged: onChanged,
  );
}

class _H extends StatelessWidget {
  const _H(this.label, {required this.flex});
  final String label;
  final int flex;
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  );
}

class _EditCell extends StatelessWidget {
  const _EditCell({
    required this.controller,
    required this.onChanged,
    this.numeric = false,
  });
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
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
          : null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      ),
    ),
  );
}

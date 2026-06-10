// item_import_screen.dart
import 'dart:io';
import 'package:excel/excel.dart' hide Border, TextSpan, BorderStyle;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/router.dart';
import '../../../core/constants/api_enums.dart' as api;
import '../../../core/navigation/safe_navigation.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../data/models/item_model.dart';
import '../providers/items_provider.dart';
import '../utils/item_excel_workbooks.dart';

class _ImportRow {
  String name;
  String type;
  String barcode;
  String sku;
  String unit;
  String incomeAccountName;
  String inventoryAssetAccountName;
  String cogsAccountName;
  String expenseAccountName;
  double salesPrice;
  double purchasePrice;
  double quantityOnHand;
  bool valid;
  String? error;

  _ImportRow({
    required this.name,
    required this.type,
    required this.barcode,
    required this.sku,
    required this.unit,
    required this.incomeAccountName,
    required this.inventoryAssetAccountName,
    required this.cogsAccountName,
    required this.expenseAccountName,
    required this.salesPrice,
    required this.purchasePrice,
    required this.quantityOnHand,
    required this.valid,
    this.error,
  });
}

class ItemImportScreen extends ConsumerStatefulWidget {
  const ItemImportScreen({super.key});
  @override
  ConsumerState<ItemImportScreen> createState() => _ItemImportScreenState();
}

class _ItemImportScreenState extends ConsumerState<ItemImportScreen> {
  List<_ImportRow> _rows = [];
  String? _fileName;
  bool _importing = false;
  int _imported = 0;
  int _failed = 0;
  bool _done = false;
  final List<String> _failureMessages = [];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final path = file.path;
    if (path == null) return;

    setState(() {
      _rows = [];
      _fileName = file.name;
      _done = false;
    });

    if (path.toLowerCase().endsWith('.csv')) {
      await _parseCsv(path);
    } else {
      await _parseExcel(path);
    }
  }

  Future<void> _parseCsv(String path) async {
    final lines = await File(path).readAsLines();
    if (lines.isEmpty) return;
    final rows = <_ImportRow>[];
    final headers = _splitCsv(
      lines.first,
    ).map((h) => h.toLowerCase().trim()).toList();
    int idx(String key, int fallback) {
      final found = headers.indexWhere((h) => h.contains(key));
      return found >= 0 ? found : fallback;
    }

    final nameIdx = idx('name', 0);
    final typeIdx = idx('type', 1);
    final barcodeIdx = idx('barcode', 2);
    final skuIdx = headers.indexWhere(
      (h) => h.contains('sku') || h.contains('part'),
    );
    final unitIdx = idx('unit', 3);
    final salesIdx = idx('sales', 4);
    final purchaseIdx = idx('purchase', 5);
    final quantityIdx = headers.indexWhere(
      (h) => h.contains('qty') || h.contains('quantity') || h.contains('hand'),
    );
    final incomeAccountIdx = _headerIndex(headers, ['income account']);
    final inventoryAssetAccountIdx = _headerIndex(headers, [
      'inventory asset account',
      'asset account',
    ]);
    final cogsAccountIdx = _headerIndex(headers, ['cogs account', 'cogs']);
    final expenseAccountIdx = _headerIndex(headers, ['expense account']);
    for (var i = 1; i < lines.length; i++) {
      final cols = _splitCsv(lines[i]);
      if (cols.length < 2) continue;
      final row = _validateRow(
        name: cols.elementAtOrNull(nameIdx) ?? '',
        type: cols.elementAtOrNull(typeIdx) ?? '',
        barcode: cols.elementAtOrNull(barcodeIdx) ?? '',
        sku: skuIdx >= 0 ? (cols.elementAtOrNull(skuIdx) ?? '') : '',
        unit: cols.elementAtOrNull(unitIdx) ?? '',
        salesStr: cols.elementAtOrNull(salesIdx) ?? '0',
        purchaseStr: cols.elementAtOrNull(purchaseIdx) ?? '0',
        quantityStr: quantityIdx >= 0
            ? (cols.elementAtOrNull(quantityIdx) ?? '0')
            : '0',
        incomeAccountName: incomeAccountIdx >= 0
            ? (cols.elementAtOrNull(incomeAccountIdx) ?? '')
            : '',
        inventoryAssetAccountName: inventoryAssetAccountIdx >= 0
            ? (cols.elementAtOrNull(inventoryAssetAccountIdx) ?? '')
            : '',
        cogsAccountName: cogsAccountIdx >= 0
            ? (cols.elementAtOrNull(cogsAccountIdx) ?? '')
            : '',
        expenseAccountName: expenseAccountIdx >= 0
            ? (cols.elementAtOrNull(expenseAccountIdx) ?? '')
            : '',
      );
      rows.add(row);
    }
    setState(() => _rows = rows);
  }

  Future<void> _parseExcel(String path) async {
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables['Items'] ?? excel.tables.values.firstOrNull;
    if (sheet == null) return;
    final rows = <_ImportRow>[];
    final headers = sheet.rows.first
        .map((c) => c?.value?.toString().toLowerCase().trim() ?? '')
        .toList();
    int idx(String key, int fallback) {
      final found = headers.indexWhere((h) => h.contains(key));
      return found >= 0 ? found : fallback;
    }

    final nameIdx = idx('name', 0);
    final typeIdx = idx('type', 1);
    final barcodeIdx = idx('barcode', 2);
    final skuIdx = headers.indexWhere(
      (h) => h.contains('sku') || h.contains('part'),
    );
    final unitIdx = idx('unit', 3);
    final salesIdx = idx('sales', 4);
    final purchaseIdx = idx('purchase', 5);
    final quantityIdx = headers.indexWhere(
      (h) => h.contains('qty') || h.contains('quantity') || h.contains('hand'),
    );
    final incomeAccountIdx = _headerIndex(headers, ['income account']);
    final inventoryAssetAccountIdx = _headerIndex(headers, [
      'inventory asset account',
      'asset account',
    ]);
    final cogsAccountIdx = _headerIndex(headers, ['cogs account', 'cogs']);
    final expenseAccountIdx = _headerIndex(headers, ['expense account']);
    for (var i = 1; i < sheet.rows.length; i++) {
      final r = sheet.rows[i];
      String cell(int idx) => r.elementAtOrNull(idx)?.value?.toString() ?? '';
      final row = _validateRow(
        name: cell(nameIdx),
        type: cell(typeIdx),
        barcode: cell(barcodeIdx),
        sku: skuIdx >= 0 ? cell(skuIdx) : '',
        unit: cell(unitIdx),
        salesStr: cell(salesIdx),
        purchaseStr: cell(purchaseIdx),
        quantityStr: quantityIdx >= 0 ? cell(quantityIdx) : '0',
        incomeAccountName: incomeAccountIdx >= 0 ? cell(incomeAccountIdx) : '',
        inventoryAssetAccountName: inventoryAssetAccountIdx >= 0
            ? cell(inventoryAssetAccountIdx)
            : '',
        cogsAccountName: cogsAccountIdx >= 0 ? cell(cogsAccountIdx) : '',
        expenseAccountName: expenseAccountIdx >= 0
            ? cell(expenseAccountIdx)
            : '',
      );
      rows.add(row);
    }
    setState(() => _rows = rows);
  }

  int _headerIndex(List<String> headers, List<String> keys) {
    return headers.indexWhere(
      (header) => keys.any((key) => header.contains(key)),
    );
  }

  _ImportRow _validateRow({
    required String name,
    required String type,
    required String barcode,
    required String sku,
    required String unit,
    required String salesStr,
    required String purchaseStr,
    required String quantityStr,
    required String incomeAccountName,
    required String inventoryAssetAccountName,
    required String cogsAccountName,
    required String expenseAccountName,
  }) {
    if (name.trim().isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return _ImportRow(
        name: name,
        type: type,
        barcode: barcode,
        sku: sku,
        unit: unit,
        incomeAccountName: incomeAccountName,
        inventoryAssetAccountName: inventoryAssetAccountName,
        cogsAccountName: cogsAccountName,
        expenseAccountName: expenseAccountName,
        salesPrice: 0,
        purchasePrice: 0,
        quantityOnHand: 0,
        valid: false,
        error: l10n.nameRequired,
      );
    }
    final sales = double.tryParse(salesStr.replaceAll(',', '')) ?? 0;
    final purchase = double.tryParse(purchaseStr.replaceAll(',', '')) ?? 0;
    final quantity = double.tryParse(quantityStr.replaceAll(',', '')) ?? 0;
    return _ImportRow(
      name: name.trim(),
      type: type.trim(),
      barcode: barcode.trim(),
      sku: sku.trim(),
      unit: unit.trim(),
      incomeAccountName: incomeAccountName.trim(),
      inventoryAssetAccountName: inventoryAssetAccountName.trim(),
      cogsAccountName: cogsAccountName.trim(),
      expenseAccountName: expenseAccountName.trim(),
      salesPrice: sales,
      purchasePrice: purchase,
      quantityOnHand: quantity,
      valid: true,
    );
  }

  ItemType _parseType(String t) {
    final lower = t.toLowerCase();
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

  Future<void> _doImport() async {
    final l10n = AppLocalizations.of(context)!;
    final valid = _rows.where((r) => r.valid).toList();
    if (valid.isEmpty) {
      _snack(l10n.noValidRowsToImport, isError: true);
      return;
    }
    setState(() {
      _importing = true;
      _imported = 0;
      _failed = 0;
      _failureMessages.clear();
    });

    final accounts = await _loadAccountsForImport();
    for (final row in valid) {
      final itemType = _parseType(row.type);
      final accountIds = _resolvePostingAccounts(row, itemType, accounts);
      final accountError = _validatePostingAccounts(row, itemType, accountIds);
      if (accountError != null) {
        _markRowFailed(row, accountError);
        continue;
      }
      final body = <String, dynamic>{
        'name': row.name,
        'itemType': itemType.value,
        'salesPrice': row.salesPrice,
        'purchasePrice': row.purchasePrice,
        if (itemType == ItemType.inventory ||
            itemType == ItemType.inventoryAssembly)
          'quantityOnHand': row.quantityOnHand,
        if (row.barcode.isNotEmpty) 'barcode': row.barcode,
        if (row.sku.isNotEmpty) 'sku': row.sku,
        if (row.unit.isNotEmpty) 'unit': row.unit,
        if (accountIds.incomeAccountId != null)
          'incomeAccountId': accountIds.incomeAccountId,
        if (accountIds.inventoryAssetAccountId != null)
          'inventoryAssetAccountId': accountIds.inventoryAssetAccountId,
        if (accountIds.cogsAccountId != null)
          'cogsAccountId': accountIds.cogsAccountId,
        if (accountIds.expenseAccountId != null)
          'expenseAccountId': accountIds.expenseAccountId,
      };
      final result = await ref.read(itemsProvider.notifier).createItem(body);
      result.when(
        success: (_) => setState(() => _imported++),
        failure: (error) => _markRowFailed(row, error.message),
      );
    }

    setState(() {
      _importing = false;
      _done = true;
    });
    ref.read(itemsProvider.notifier).refresh();
  }

  Future<List<AccountModel>> _loadAccountsForImport() async {
    try {
      final result = await ref
          .read(accountsDatasourceProvider)
          .getAccounts(includeInactive: false, pageSize: 10000);
      return result.when(
        success: (accounts) => accounts,
        failure: (_) => const <AccountModel>[],
      );
    } catch (_) {
      return const <AccountModel>[];
    }
  }

  _ResolvedItemAccounts _resolvePostingAccounts(
    _ImportRow row,
    ItemType itemType,
    List<AccountModel> accounts,
  ) {
    String? findByName(String value, List<api.AccountType> types) {
      final text = _normalizeAccount(value);
      if (text.isEmpty) return null;
      final pool = accounts
          .where(
            (account) =>
                account.isActive && types.contains(account.accountType),
          )
          .toList();
      final exact = pool.cast<AccountModel?>().firstWhere(
        (account) => _normalizeAccount(account!.name) == text,
        orElse: () => null,
      );
      if (exact != null) return exact.id;
      final contains = pool.cast<AccountModel?>().firstWhere(
        (account) =>
            _normalizeAccount(account!.name).contains(text) ||
            text.contains(_normalizeAccount(account.name)),
        orElse: () => null,
      );
      return contains?.id;
    }

    String? fallback(List<api.AccountType> types, List<String> keywords) {
      final pool = accounts
          .where(
            (account) =>
                account.isActive && types.contains(account.accountType),
          )
          .toList();
      for (final keyword in keywords) {
        final match = pool.cast<AccountModel?>().firstWhere(
          (account) => _normalizeAccount(account!.name).contains(keyword),
          orElse: () => null,
        );
        if (match != null) return match.id;
      }
      return pool.isEmpty ? null : pool.first.id;
    }

    final incomeTypes = [api.AccountType.income, api.AccountType.otherIncome];
    final assetTypes = [
      api.AccountType.inventoryAsset,
      api.AccountType.otherCurrentAsset,
    ];
    final cogsTypes = [api.AccountType.costOfGoodsSold];
    final expenseTypes = [
      api.AccountType.expense,
      api.AccountType.otherExpense,
      api.AccountType.costOfGoodsSold,
    ];

    var incomeId = findByName(row.incomeAccountName, incomeTypes);
    var assetId = findByName(row.inventoryAssetAccountName, assetTypes);
    var cogsId = findByName(row.cogsAccountName, cogsTypes);
    var expenseId = findByName(row.expenseAccountName, expenseTypes);

    if (itemType == ItemType.inventory ||
        itemType == ItemType.inventoryAssembly) {
      incomeId ??= fallback(incomeTypes, ['sales income', 'income']);
      assetId ??= fallback(assetTypes, ['inventory asset', 'inventory']);
      cogsId ??= fallback(cogsTypes, ['cost of goods', 'cogs']);
    } else if (itemType == ItemType.service) {
      incomeId ??= fallback(incomeTypes, [
        'service income',
        'sales income',
        'income',
      ]);
      expenseId ??= row.expenseAccountName.isEmpty
          ? null
          : fallback(expenseTypes, ['expense', 'cost']);
    } else if (itemType == ItemType.nonInventory ||
        itemType == ItemType.otherCharge ||
        itemType == ItemType.discount) {
      incomeId ??= fallback(incomeTypes, ['sales income', 'income']);
      expenseId ??=
          findByName(row.expenseAccountName, expenseTypes) ??
          (incomeId == null
              ? fallback(expenseTypes, ['expense', 'cost'])
              : null);
    } else if (itemType == ItemType.fixedAsset) {
      assetId ??= fallback(
        [api.AccountType.fixedAsset, ...assetTypes],
        ['fixed asset', 'asset'],
      );
      expenseId ??= row.expenseAccountName.isEmpty
          ? null
          : fallback(expenseTypes, ['expense', 'cost']);
    } else if (itemType == ItemType.payment) {
      incomeId ??= fallback(incomeTypes, ['income']);
    }

    return _ResolvedItemAccounts(
      incomeAccountId: incomeId,
      inventoryAssetAccountId: assetId,
      cogsAccountId: cogsId,
      expenseAccountId: expenseId,
    );
  }

  String? _validatePostingAccounts(
    _ImportRow row,
    ItemType itemType,
    _ResolvedItemAccounts accounts,
  ) {
    if (itemType == ItemType.inventory ||
        itemType == ItemType.inventoryAssembly) {
      if (row.quantityOnHand > 0 && row.purchasePrice <= 0) {
        return AppLocalizations.of(
          context,
        )!.inventoryOpeningQtyRequiresPurchasePrice;
      }
      if (accounts.incomeAccountId == null) {
        return AppLocalizations.of(context)!.incomeAccountNotFound;
      }
      if (accounts.inventoryAssetAccountId == null) {
        return AppLocalizations.of(context)!.inventoryAssetAccountNotFound;
      }
      if (accounts.cogsAccountId == null) {
        return AppLocalizations.of(context)!.cogsAccountNotFound;
      }
    }
    if ((itemType == ItemType.service ||
            itemType == ItemType.nonInventory ||
            itemType == ItemType.otherCharge ||
            itemType == ItemType.discount) &&
        accounts.incomeAccountId == null &&
        accounts.expenseAccountId == null) {
      return AppLocalizations.of(context)!.incomeOrExpenseAccountNotFound;
    }
    if (itemType == ItemType.fixedAsset &&
        accounts.inventoryAssetAccountId == null &&
        accounts.expenseAccountId == null) {
      return AppLocalizations.of(context)!.assetOrExpenseAccountNotFound;
    }
    if (itemType == ItemType.payment && accounts.incomeAccountId == null) {
      return AppLocalizations.of(context)!.depositOrIncomeAccountNotFound;
    }
    return null;
  }

  String _normalizeAccount(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  void _markRowFailed(_ImportRow row, String message) {
    setState(() {
      row.error = message;
      _failed++;
      if (_failureMessages.length < 5) {
        _failureMessages.add('${row.name}: $message');
      }
    });
  }

  Future<void> _downloadTemplate() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final dir =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/zayed-items-import-template.xlsx');
      await file.writeAsBytes(buildItemImportTemplateBytes());
      _snack(l10n.excelTemplateSaved(file.path));
    } catch (e) {
      _snack(l10n.couldNotSaveExcelTemplate(e.toString()), isError: true);
    }
  }

  Future<void> _exportItems() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref.read(itemsProvider.notifier).exportItemsJson();
    if (!mounted) return;
    result.when(
      success: (rows) async {
        try {
          final dir =
              await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
          final file = File(
            '${dir.path}/items-export-${DateTime.now().millisecondsSinceEpoch}.xlsx',
          );
          await file.writeAsBytes(buildItemExportWorkbookBytes(rows));
          _snack(l10n.excelExportSaved(file.path));
        } catch (e) {
          _snack(l10n.excelExportFailed(e.toString()), isError: true);
        }
      },
      failure: (e) => _snack(e.message, isError: true),
    );
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

  List<String> _splitCsv(String line) {
    final result = <String>[];
    var inQuotes = false;
    final buf = StringBuffer();
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (c == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
        continue;
      }
      buf.write(c);
    }
    result.add(buf.toString());
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final validCount = _rows.where((r) => r.valid).length;
    final invalidCount = _rows.where((r) => !r.valid).length;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // â”€â”€ Tool Strip
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
                          l10n.items,
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
                  l10n.importItems,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _downloadTemplate,
                  icon: const Icon(Icons.description_outlined, size: 15),
                  label: Text(
                    l10n.downloadImportTemplate,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _exportItems,
                  icon: const Icon(Icons.grid_on_outlined, size: 15),
                  label: Text(
                    l10n.exportExcel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(width: 12),
                if (_rows.isNotEmpty && !_done && !_importing)
                  FilledButton.icon(
                    onPressed: validCount == 0 ? null : _doImport,
                    icon: const Icon(Icons.upload, size: 15),
                    label: Text(
                      l10n.importItemCount(validCount),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                const SizedBox(width: 12),
              ],
            ),
          ),

          Expanded(
            child: _done
                ? _buildDone(cs, l10n)
                : _rows.isEmpty
                ? _buildDropZone(cs, theme, l10n)
                : _buildPreview(cs, validCount, invalidCount, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone(
    ColorScheme cs,
    ThemeData theme,
    AppLocalizations l10n,
  ) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 480,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.4),
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(16),
            color: cs.primaryContainer.withValues(alpha: 0.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.upload_file_outlined, size: 56, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                l10n.importItemsCsvExcel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.selectCsvXlsxFileHint,
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open, size: 18),
                label: Text(l10n.browseFile),
                style: FilledButton.styleFrom(minimumSize: const Size(180, 44)),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: Text(l10n.downloadImportTemplate),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exportItems,
                    icon: const Icon(Icons.grid_on_outlined, size: 18),
                    label: Text(l10n.exportCurrentItems),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.expectedItemsWorkbookHint,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildPreview(
    ColorScheme cs,
    int valid,
    int invalid,
    AppLocalizations l10n,
  ) => Column(
    children: [
      // Summary bar
      Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.insert_drive_file_outlined, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              _fileName ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 16),
            _Chip(
              l10n.rowCount(_rows.length),
              cs.secondaryContainer,
              cs.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            _Chip(
              l10n.validCount(valid),
              cs.primaryContainer,
              cs.onPrimaryContainer,
            ),
            if (invalid > 0) ...[
              const SizedBox(width: 8),
              _Chip(
                l10n.errorCount(invalid),
                cs.errorContainer,
                cs.onErrorContainer,
              ),
            ],
            const Spacer(),
            TextButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.refresh, size: 14),
              label: Text(
                l10n.changeFile,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (_importing) ...[
              const SizedBox(width: 12),
              Text(
                l10n.importingProgress(
                  _imported,
                  _rows.where((r) => r.valid).length,
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),

      // Header
      Container(
        height: 30,
        color: cs.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _PH(l10n.status, 1),
            _PH(l10n.name, 3),
            _PH(l10n.type, 2),
            _PH(l10n.barcode, 2),
            _PH(l10n.partNo, 2),
            _PH(l10n.unit, 1),
            _PH(l10n.salesPrice, 2),
            _PH(l10n.purchaseCost, 2),
            _PH(l10n.qty, 1),
          ],
        ),
      ),

      // Rows
      Expanded(
        child: ListView.builder(
          itemCount: _rows.length,
          itemBuilder: (ctx, i) {
            final row = _rows[i];
            final bg = i.isEven ? cs.surface : cs.surfaceContainerLowest;
            return Container(
              height: 36,
              color: row.valid ? bg : cs.errorContainer.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Icon(
                      row.valid
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 15,
                      color: row.valid ? Colors.green : cs.error,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.name,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(row.type, style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.barcode,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.sku,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(row.unit, style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.salesPrice.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Text(
                          row.purchasePrice.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (row.error != null) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: row.error!,
                            child: Icon(
                              Icons.warning_amber,
                              size: 14,
                              color: cs.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      row.quantityOnHand.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _buildDone(ColorScheme cs, AppLocalizations l10n) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 64, color: Colors.green.shade600),
        const SizedBox(height: 16),
        Text(
          l10n.importComplete,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _failed > 0
              ? l10n.itemsImportedWithFailures(_imported, _failed)
              : l10n.itemsImportedSuccess(_imported),
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        if (_failureMessages.isNotEmpty) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: _failureMessages
                  .map(
                    (message) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: cs.error),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.popOrGo(AppRoutes.items),
          child: Text(l10n.backToItems),
        ),
      ],
    ),
  );
}

class _ResolvedItemAccounts {
  const _ResolvedItemAccounts({
    this.incomeAccountId,
    this.inventoryAssetAccountId,
    this.cogsAccountId,
    this.expenseAccountId,
  });

  final String? incomeAccountId;
  final String? inventoryAssetAccountId;
  final String? cogsAccountId;
  final String? expenseAccountId;
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.bg, this.fg);
  final String label;
  final Color bg, fg;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
    ),
  );
}

class _PH extends StatelessWidget {
  const _PH(this.label, this.flex);
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
    ),
  );
}

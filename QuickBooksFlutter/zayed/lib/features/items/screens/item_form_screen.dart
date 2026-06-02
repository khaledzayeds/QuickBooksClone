// item_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/api/api_result.dart';
import '../../../core/constants/api_enums.dart' as api;
import '../../../core/navigation/safe_navigation.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../data/models/item_model.dart';
import '../providers/items_provider.dart';
import '../utils/item_barcode_utils.dart';
import '../widgets/item_unit_selector.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, this.id, this.initialType});
  final String? id;
  final ItemType? initialType;
  bool get isEdit => id != null;
  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'pcs');
  final _salesPriceCtrl = TextEditingController(text: '0');
  final _purchasePriceCtrl = TextEditingController(text: '0');
  final _qtyCtrl = TextEditingController(text: '0');

  ItemType _itemType = ItemType.inventory;
  bool _loading = false;
  bool _loadingItem = false;
  bool _loadingAccounts = true;
  bool _showAdvancedIds = false;
  List<AccountModel> _accounts = const [];
  ItemModel? _loadedItem;

  String? _incomeAccountId;
  String? _inventoryAssetAccountId;
  String? _cogsAccountId;
  String? _expenseAccountId;

  @override
  void initState() {
    super.initState();
    if (!widget.isEdit && widget.initialType != null) {
      _itemType = widget.initialType!;
      _unitCtrl.text = _tracksInventory(_itemType) ? 'pcs' : 'hr';
    }
    _loadAccounts();
    if (widget.isEdit) _loadItem();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _unitCtrl.dispose();
    _salesPriceCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
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
          _loadingAccounts = false;
        });
        _applyDefaults();
      },
      failure: (e) {
        setState(() => _loadingAccounts = false);
        _snack(e.message, isError: true);
      },
    );
  }

  Future<void> _loadItem() async {
    setState(() => _loadingItem = true);
    final result = await ref.read(itemsRepositoryProvider).getItem(widget.id!);
    if (!mounted) return;
    result.when(
      success: (item) {
        _nameCtrl.text = item.name;
        _skuCtrl.text = item.sku ?? '';
        _barcodeCtrl.text = item.barcode ?? '';
        _unitCtrl.text = item.unit ?? 'pcs';
        _salesPriceCtrl.text = item.salesPrice.toString();
        _purchasePriceCtrl.text = item.purchasePrice.toString();
        _qtyCtrl.text = item.quantityOnHand.toString();
        setState(() {
          _loadedItem = item;
          _itemType = item.itemType;
          _showAdvancedIds = (item.sku ?? '').isNotEmpty;
          _incomeAccountId = item.incomeAccountId;
          _inventoryAssetAccountId = item.inventoryAssetAccountId;
          _cogsAccountId = item.cogsAccountId;
          _expenseAccountId = item.expenseAccountId;
          _loadingItem = false;
        });
      },
      failure: (e) {
        setState(() => _loadingItem = false);
        _snack(e.message, isError: true);
      },
    );
  }

  void _applyDefaults({bool force = false}) {
    if (_accounts.isEmpty) return;
    String? find(List<api.AccountType> types, List<String> kw) {
      final pool = _accounts
          .where((a) => a.isActive && types.contains(a.accountType))
          .toList();
      for (final k in kw) {
        final m = pool.cast<AccountModel?>().firstWhere(
          (a) => a!.name.toLowerCase().contains(k),
          orElse: () => null,
        );
        if (m != null) return m.id;
      }
      return pool.isEmpty ? null : pool.first.id;
    }

    setState(() {
      if (force) {
        _incomeAccountId = _inventoryAssetAccountId = _cogsAccountId =
            _expenseAccountId = null;
      }
      _incomeAccountId ??= find(
        [api.AccountType.income, api.AccountType.otherIncome],
        ['sales income', 'income'],
      );
      _inventoryAssetAccountId ??= find(
        [api.AccountType.inventoryAsset, api.AccountType.otherCurrentAsset],
        ['inventory asset', 'inventory'],
      );
      _cogsAccountId ??= find(
        [api.AccountType.costOfGoodsSold],
        ['cost of goods', 'cogs'],
      );
      _expenseAccountId ??= find(
        [
          api.AccountType.expense,
          api.AccountType.otherExpense,
          api.AccountType.costOfGoodsSold,
        ],
        ['expense', 'cost'],
      );
    });
  }

  String? _numVal(String? v) {
    final n = double.tryParse(v ?? '');
    if (n == null) return 'Invalid number';
    if (n < 0) return 'Cannot be negative';
    return null;
  }

  String? _barcodeVal(String? value) {
    final barcode = value?.trim() ?? '';
    if (barcode.isEmpty) return null;
    final items = ref.read(itemsProvider).value ?? const <ItemModel>[];
    if (ItemBarcodeUtils.hasDuplicateBarcode(
      items,
      barcode,
      excludingItemId: widget.id,
    )) {
      return 'Barcode already exists on another item.';
    }
    return null;
  }

  Future<void> _generateBarcode() async {
    var items = ref.read(itemsProvider).value;
    if (items == null) {
      final result = await ref
          .read(itemsRepositoryProvider)
          .getItems(includeInactive: true, pageSize: 10000);
      if (!mounted) return;
      result.when(
        success: (list) => items = list,
        failure: (e) => _snack(e.message, isError: true),
      );
    }
    if (items == null) return;
    setState(() {
      _barcodeCtrl.text = ItemBarcodeUtils.generateInStoreBarcode(items!);
    });
  }

  String? _validateAccounts() {
    if (_tracksInventory(_itemType)) {
      if (_incomeAccountId == null) return 'Income account required.';
      if (_inventoryAssetAccountId == null) {
        return 'Inventory asset account required.';
      }
      if (_cogsAccountId == null) return 'COGS account required.';
    }
    if ((_isSalesOrPurchaseOnly(_itemType)) &&
        _incomeAccountId == null &&
        _expenseAccountId == null) {
      return 'Income or expense account required.';
    }
    if (_itemType == ItemType.fixedAsset &&
        _inventoryAssetAccountId == null &&
        _expenseAccountId == null) {
      return 'Asset or expense account required.';
    }
    if (_itemType == ItemType.payment && _incomeAccountId == null) {
      return 'Deposit or income account required.';
    }
    if (_postsThroughComponents(_itemType) && _incomeAccountId != null) {
      return 'Group and subtotal items should not have an income account.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final acErr = _validateAccounts();
    if (acErr != null) {
      _snack(acErr, isError: true);
      return;
    }
    setState(() => _loading = true);

    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'itemType': _itemType.value,
      'salesPrice': double.tryParse(_salesPriceCtrl.text) ?? 0,
      'purchasePrice': double.tryParse(_purchasePriceCtrl.text) ?? 0,
      if (_skuCtrl.text.trim().isNotEmpty) 'sku': _skuCtrl.text.trim(),
      if (_barcodeCtrl.text.trim().isNotEmpty)
        'barcode': _barcodeCtrl.text.trim(),
      if (_unitCtrl.text.trim().isNotEmpty) 'unit': _unitCtrl.text.trim(),
      if (!widget.isEdit && _tracksInventory(_itemType))
        'quantityOnHand': double.tryParse(_qtyCtrl.text) ?? 0,
      if (_incomeAccountId != null) 'incomeAccountId': _incomeAccountId,
      if (_inventoryAssetAccountId != null)
        'inventoryAssetAccountId': _inventoryAssetAccountId,
      if (_cogsAccountId != null) 'cogsAccountId': _cogsAccountId,
      if (_expenseAccountId != null) 'expenseAccountId': _expenseAccountId,
    };

    final ApiResult<ItemModel> result = widget.isEdit
        ? await ref.read(itemsProvider.notifier).updateItem(widget.id!, body)
        : await ref.read(itemsProvider.notifier).createItem(body);

    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) {
        _snack(widget.isEdit ? 'Item updated.' : 'Item created.');
        context.popOrGo(AppRoutes.items);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final busy = _loading || _loadingItem || _loadingAccounts;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // ── Tool Strip ──────────────────────────────────────────────────────
          Container(
            height: 42,
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
                _TBtn(
                  icon: Icons.arrow_back,
                  label: l10n.cancel,
                  onTap: _loading
                      ? null
                      : () => context.popOrGo(AppRoutes.items),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.isEdit ? 'Edit Item' : 'New Item',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => context.go(AppRoutes.itemBarcodeCenter),
                  icon: const Icon(Icons.qr_code_2_outlined, size: 16),
                  label: const Text('Barcode Center'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(width: 8),
                if (!_loading)
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: Text(widget.isEdit ? 'Save Changes' : 'Create Item'),
                  )
                else
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 12),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Expanded(
            child: busy && _loadingAccounts && !widget.isEdit
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _ItemFormHero(
                          isEdit: widget.isEdit,
                          itemType: _typeLabel(_itemType),
                          name: _nameCtrl.text,
                          barcode: _barcodeCtrl.text,
                          unit: _unitCtrl.text,
                          salesPrice:
                              double.tryParse(_salesPriceCtrl.text) ?? 0,
                          purchasePrice:
                              double.tryParse(_purchasePriceCtrl.text) ?? 0,
                          quantityOnHand: _tracksInventory(_itemType)
                              ? double.tryParse(_qtyCtrl.text) ?? 0
                              : null,
                          currency: 'EGP',
                          onGenerateBarcode: _generateBarcode,
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left panel — Basic info
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _Section(
                                        title: 'Item Details',
                                        icon: Icons.inventory_2_outlined,
                                        children: [
                                          // Item type
                                          DropdownButtonFormField<ItemType>(
                                            initialValue: _itemType,
                                            decoration: const InputDecoration(
                                              labelText: 'Item Type *',
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            items: ItemType.values
                                                .map(
                                                  (t) => DropdownMenuItem(
                                                    value: t,
                                                    child: Text(_typeLabel(t)),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged:
                                                widget.isEdit &&
                                                    (_loadedItem?.quantityOnHand ??
                                                            0) !=
                                                        0
                                                ? null
                                                : (v) {
                                                    if (v == null) return;
                                                    setState(
                                                      () => _itemType = v,
                                                    );
                                                    _applyDefaults(force: true);
                                                  },
                                          ),
                                          const SizedBox(height: 8),
                                          _hint(_typeHint(_itemType), cs),
                                          if (_loadedItem != null) ...[
                                            const SizedBox(height: 8),
                                            _banner(_loadedItem!, cs),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _Section(
                                        title: 'Name & Barcode',
                                        icon: Icons.qr_code_2_outlined,
                                        children: [
                                          AppTextField(
                                            label: 'Item Name / Number *',
                                            controller: _nameCtrl,
                                            hint: 'e.g. Thermal Printer',
                                            onChanged: (_) => setState(() {}),
                                            validator: (v) =>
                                                (v ?? '').trim().isEmpty
                                                ? 'Required'
                                                : null,
                                          ),
                                          const SizedBox(height: 10),
                                          AppTextField(
                                            label: 'Barcode',
                                            controller: _barcodeCtrl,
                                            hint: 'Scan or type barcode',
                                            keyboardType: TextInputType.text,
                                            onChanged: (_) => setState(() {}),
                                            validator: _barcodeVal,
                                            suffixIcon: Tooltip(
                                              message:
                                                  'Generate internal barcode',
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.auto_awesome_outlined,
                                                  size: 18,
                                                ),
                                                onPressed: _generateBarcode,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Theme(
                                            data: theme.copyWith(
                                              dividerColor: Colors.transparent,
                                            ),
                                            child: ExpansionTile(
                                              initiallyExpanded:
                                                  _showAdvancedIds,
                                              tilePadding: EdgeInsets.zero,
                                              childrenPadding: EdgeInsets.zero,
                                              dense: true,
                                              onExpansionChanged: (v) =>
                                                  setState(
                                                    () => _showAdvancedIds = v,
                                                  ),
                                              title: const Text(
                                                'Advanced identifiers',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              subtitle: const Text(
                                                'Part No. / manufacturer code is optional.',
                                                style: TextStyle(fontSize: 11),
                                              ),
                                              children: [
                                                AppTextField(
                                                  label:
                                                      'Part No. / SKU (optional)',
                                                  controller: _skuCtrl,
                                                  hint: 'INV-001',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          ItemUnitSelector(
                                            initialValue: _unitCtrl.text.isEmpty
                                                ? null
                                                : _unitCtrl.text,
                                            onChanged: (v) => setState(
                                              () => _unitCtrl.text = v ?? '',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _Section(
                                        title: 'Pricing',
                                        icon: Icons.price_change_outlined,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: AppTextField(
                                                  label: 'Sales Price',
                                                  controller: _salesPriceCtrl,
                                                  hint: '0.00',
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  validator: _numVal,
                                                  onChanged: (_) =>
                                                      setState(() {}),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: AppTextField(
                                                  label: 'Purchase Cost',
                                                  controller:
                                                      _purchasePriceCtrl,
                                                  hint: '0.00',
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  validator: _numVal,
                                                  onChanged: (_) =>
                                                      setState(() {}),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (!widget.isEdit &&
                                              _tracksInventory(_itemType)) ...[
                                            const SizedBox(height: 10),
                                            AppTextField(
                                              label: 'Opening Qty on Hand',
                                              controller: _qtyCtrl,
                                              hint: '0',
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              validator: (v) {
                                                final base = _numVal(v);
                                                if (base != null) return base;
                                                final qty =
                                                    double.tryParse(v ?? '') ??
                                                    0;
                                                final cost =
                                                    double.tryParse(
                                                      _purchasePriceCtrl.text,
                                                    ) ??
                                                    0;
                                                if (qty > 0 && cost <= 0) {
                                                  return 'Purchase cost required for opening qty';
                                                }
                                                return null;
                                              },
                                              onChanged: (_) => setState(() {}),
                                            ),
                                            const SizedBox(height: 6),
                                            _hint(
                                              'Opening qty > 0 posts an opening inventory value via the purchase cost.',
                                              cs,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Divider
                              VerticalDivider(
                                width: 1,
                                color: cs.outlineVariant.withValues(alpha: 0.4),
                              ),
                              // Right panel — Accounts
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: _Section(
                                    title: 'Posting Accounts',
                                    icon: Icons.account_tree_outlined,
                                    children: [
                                      _hint(_accountsHint(_itemType), cs),
                                      const SizedBox(height: 12),
                                      if (!_postsThroughComponents(
                                        _itemType,
                                      )) ...[
                                        _AccountPicker(
                                          label:
                                              _tracksInventory(_itemType) ||
                                                  _itemType == ItemType.payment
                                              ? 'Income / Deposit Account *'
                                              : 'Income Account',
                                          value: _incomeAccountId,
                                          accounts: _filter([
                                            api.AccountType.income,
                                            api.AccountType.otherIncome,
                                          ]),
                                          onChanged: (v) => setState(
                                            () => _incomeAccountId = v,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      if (_tracksInventory(_itemType)) ...[
                                        _AccountPicker(
                                          label: 'Inventory Asset Account *',
                                          value: _inventoryAssetAccountId,
                                          accounts: _filter([
                                            api.AccountType.inventoryAsset,
                                            api.AccountType.otherCurrentAsset,
                                          ]),
                                          onChanged: (v) => setState(
                                            () => _inventoryAssetAccountId = v,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        _AccountPicker(
                                          label: 'COGS Account *',
                                          value: _cogsAccountId,
                                          accounts: _filter([
                                            api.AccountType.costOfGoodsSold,
                                          ]),
                                          onChanged: (v) => setState(
                                            () => _cogsAccountId = v,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      if (_isSalesOrPurchaseOnly(_itemType) ||
                                          _itemType == ItemType.fixedAsset) ...[
                                        _AccountPicker(
                                          label:
                                              _itemType == ItemType.fixedAsset
                                              ? 'Asset / Expense Account'
                                              : 'Expense / Purchase Account',
                                          value: _expenseAccountId,
                                          accounts:
                                              _itemType == ItemType.fixedAsset
                                              ? _filter([
                                                  api.AccountType.fixedAsset,
                                                  api
                                                      .AccountType
                                                      .otherCurrentAsset,
                                                  api.AccountType.expense,
                                                  api.AccountType.otherExpense,
                                                ])
                                              : _filter([
                                                  api.AccountType.expense,
                                                  api.AccountType.otherExpense,
                                                  api
                                                      .AccountType
                                                      .costOfGoodsSold,
                                                ]),
                                          onChanged: (v) => setState(
                                            () => _expenseAccountId = v,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      if (_postsThroughComponents(_itemType))
                                        _hint(
                                          'Group and subtotal items do not post directly. Accounting flows through their component lines.',
                                          cs,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<AccountModel> _filter(List<api.AccountType> types) =>
      _accounts
          .where((a) => a.isActive && types.contains(a.accountType))
          .toList()
        ..sort((a, b) => a.code.compareTo(b.code));

  static String _typeLabel(ItemType t) => switch (t) {
    ItemType.inventory => 'Inventory Part',
    ItemType.nonInventory => 'Non-inventory Part',
    ItemType.service => 'Service',
    ItemType.bundle => 'Bundle',
    ItemType.inventoryAssembly => 'Inventory Assembly',
    ItemType.fixedAsset => 'Fixed Asset',
    ItemType.otherCharge => 'Other Charge',
    ItemType.subtotal => 'Subtotal',
    ItemType.group => 'Group',
    ItemType.discount => 'Discount',
    ItemType.payment => 'Payment',
  };

  static String _typeHint(ItemType t) => switch (t) {
    ItemType.inventory =>
      'Tracks quantity on hand and posts to Inventory Asset + COGS.',
    ItemType.nonInventory =>
      'Does not track stock. Can be bought, sold, or both.',
    ItemType.service => 'Labor or non-stock work. Can be sold or purchased.',
    ItemType.bundle =>
      'Groups items on sales forms. Accounting flows through components.',
    ItemType.inventoryAssembly =>
      'Built from inventory components and tracks quantity on hand.',
    ItemType.fixedAsset =>
      'Tracks property or equipment you buy and may sell later.',
    ItemType.otherCharge =>
      'Miscellaneous charges such as delivery, setup, or service fees.',
    ItemType.subtotal => 'Adds a subtotal line on sales or purchase forms.',
    ItemType.group => 'Groups several items together without direct posting.',
    ItemType.discount =>
      'Subtracts a fixed amount or percentage from a subtotal.',
    ItemType.payment =>
      'Records a payment item linked to a deposit or income account.',
  };

  static String _accountsHint(ItemType t) => switch (t) {
    ItemType.inventory =>
      'Inventory items require Income, Inventory Asset, and COGS accounts.',
    ItemType.nonInventory => 'Use Income and/or Expense account.',
    ItemType.service => 'Use Income and/or Expense account.',
    ItemType.bundle => 'Bundle items post through their component items.',
    ItemType.inventoryAssembly =>
      'Assemblies require Income, Inventory Asset, and COGS accounts.',
    ItemType.fixedAsset => 'Use an asset account or expense account.',
    ItemType.otherCharge => 'Use Income and/or Expense account.',
    ItemType.subtotal => 'Subtotal lines do not post directly.',
    ItemType.group => 'Group items post through their component items.',
    ItemType.discount => 'Use Income and/or Expense account.',
    ItemType.payment => 'Use a deposit or income account.',
  };

  static bool _tracksInventory(ItemType t) =>
      t == ItemType.inventory || t == ItemType.inventoryAssembly;

  static bool _isSalesOrPurchaseOnly(ItemType t) =>
      t == ItemType.service ||
      t == ItemType.nonInventory ||
      t == ItemType.otherCharge ||
      t == ItemType.discount;

  static bool _postsThroughComponents(ItemType t) =>
      t == ItemType.bundle || t == ItemType.group || t == ItemType.subtotal;

  static Widget _hint(String text, ColorScheme cs) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: cs.primaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 15, color: cs.onPrimaryContainer),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
          ),
        ),
      ],
    ),
  );

  static Widget _banner(ItemModel item, ColorScheme cs) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(
          item.isActive ? Icons.check_circle_outline : Icons.block_outlined,
          size: 15,
          color: item.isActive ? cs.primary : cs.error,
        ),
        const SizedBox(width: 8),
        Text(
          'Qty on hand: ${item.quantityOnHand.toStringAsFixed(2)} ${item.unit ?? ''} · ${item.isActive ? 'Active' : 'Inactive'}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

// ── Section ───────────────────────────────────────────────────────────────────
class _ItemFormHero extends StatelessWidget {
  const _ItemFormHero({
    required this.isEdit,
    required this.itemType,
    required this.name,
    required this.barcode,
    required this.unit,
    required this.salesPrice,
    required this.purchasePrice,
    required this.quantityOnHand,
    required this.currency,
    required this.onGenerateBarcode,
  });

  final bool isEdit;
  final String itemType;
  final String name;
  final String barcode;
  final String unit;
  final double salesPrice;
  final double purchasePrice;
  final double? quantityOnHand;
  final String currency;
  final VoidCallback onGenerateBarcode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = name.trim().isEmpty ? 'New item' : name.trim();
    final code = barcode.trim().isEmpty ? 'No barcode yet' : barcode.trim();
    return Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFB),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.65)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F4E4),
              border: Border.all(color: const Color(0xFF9CCB94)),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF1C9B16),
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF203C49),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isEdit
                            ? const Color(0xFFEFF3F6)
                            : const Color(0xFFE8F3E5),
                        border: Border.all(color: const Color(0xFFB7C3CB)),
                      ),
                      child: Text(
                        isEdit ? 'EDIT' : 'NEW',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF33434C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _HeroChip(icon: Icons.category_outlined, text: itemType),
                    _HeroChip(icon: Icons.straighten_outlined, text: unit),
                    if (quantityOnHand != null)
                      _HeroChip(
                        icon: Icons.warehouse_outlined,
                        text: 'On hand ${quantityOnHand!.toStringAsFixed(2)}',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 270,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricBox(
                        label: 'Sales',
                        value: '${salesPrice.toStringAsFixed(2)} $currency',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricBox(
                        label: 'Cost',
                        value: '${purchasePrice.toStringAsFixed(2)} $currency',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFB7C3CB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Generate barcode',
                        visualDensity: VisualDensity.compact,
                        onPressed: onGenerateBarcode,
                        icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCAD4DA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF3B5966)),
          const SizedBox(width: 5),
          Text(
            text.isEmpty ? '-' : text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7C3CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF687980),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

// ── Tool Button ───────────────────────────────────────────────────────────────
class _TBtn extends StatelessWidget {
  const _TBtn({required this.icon, required this.label, required this.onTap});
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

// ── Account Picker ────────────────────────────────────────────────────────────
class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
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
    initialValue: accounts.any((a) => a.id == value) ? value : null,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    items: [
      const DropdownMenuItem<String?>(value: null, child: Text('Not selected')),
      ...accounts.map(
        (a) => DropdownMenuItem<String?>(
          value: a.id,
          child: Text('${a.code} — ${a.name}', overflow: TextOverflow.ellipsis),
        ),
      ),
    ],
    onChanged: onChanged,
  );
}

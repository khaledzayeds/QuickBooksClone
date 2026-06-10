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
      if (_needsIncomeAccount(_itemType)) {
        _incomeAccountId ??= find(
          [api.AccountType.income, api.AccountType.otherIncome],
          _itemType == ItemType.discount
              ? ['discount', 'sales discount', 'income']
              : ['sales income', 'income'],
        );
      }
      if (_tracksInventory(_itemType)) {
        _inventoryAssetAccountId ??= find(
          [api.AccountType.inventoryAsset, api.AccountType.otherCurrentAsset],
          ['inventory asset', 'inventory'],
        );
        _cogsAccountId ??= find(
          [api.AccountType.costOfGoodsSold],
          ['cost of goods', 'cogs'],
        );
      }
      if (_needsExpenseAccount(_itemType)) {
        _expenseAccountId ??= find(
          [
            api.AccountType.expense,
            api.AccountType.otherExpense,
            api.AccountType.costOfGoodsSold,
          ],
          ['expense', 'cost'],
        );
      }
      _normalizeAccountsForType();
    });
  }

  String? _numVal(String? v, AppLocalizations l10n) {
    final n = double.tryParse(v ?? '');
    if (n == null) return l10n.invalidNumber;
    if (n < 0) return l10n.cannotBeNegative;
    return null;
  }

  String? _barcodeVal(String? value, AppLocalizations l10n) {
    final barcode = value?.trim() ?? '';
    if (barcode.isEmpty) return null;
    final items = ref.read(itemsProvider).value ?? const <ItemModel>[];
    if (ItemBarcodeUtils.hasDuplicateBarcode(
      items,
      barcode,
      excludingItemId: widget.id,
    )) {
      return l10n.barcodeExists;
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

  String? _validateAccounts(AppLocalizations l10n) {
    if (_tracksInventory(_itemType)) {
      if (_incomeAccountId == null) return l10n.incomeAccountRequiredMsg;
      if (_inventoryAssetAccountId == null) {
        return l10n.inventoryAssetAccountRequiredMsg;
      }
      if (_cogsAccountId == null) return l10n.cogsAccountRequiredMsg;
    }
    if (_itemType == ItemType.discount) {
      if (_incomeAccountId == null) return l10n.discountAccountRequiredMsg;
    }
    if ((_isSalesOrPurchaseItem(_itemType)) &&
        _incomeAccountId == null &&
        _expenseAccountId == null) {
      return l10n.incomeOrExpenseAccountRequired;
    }
    if (_itemType == ItemType.fixedAsset &&
        _inventoryAssetAccountId == null &&
        _expenseAccountId == null) {
      return l10n.assetOrExpenseAccountRequired;
    }
    if (_itemType == ItemType.payment && _incomeAccountId == null) {
      return l10n.depositOrIncomeAccountRequired;
    }
    if (_postsThroughComponents(_itemType) && _incomeAccountId != null) {
      return l10n.componentItemsNoIncomeAccount;
    }
    return null;
  }

  void _normalizeAccountsForType() {
    if (!_needsIncomeAccount(_itemType)) _incomeAccountId = null;
    if (!_tracksInventory(_itemType)) {
      _inventoryAssetAccountId = null;
      _cogsAccountId = null;
    }
    if (!_needsExpenseAccount(_itemType)) _expenseAccountId = null;
  }

  Map<String, String?> _accountPayloadForType() {
    _normalizeAccountsForType();
    return {
      'incomeAccountId': _incomeAccountId,
      'inventoryAssetAccountId': _inventoryAssetAccountId,
      'cogsAccountId': _cogsAccountId,
      'expenseAccountId': _expenseAccountId,
    };
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    final acErr = _validateAccounts(l10n);
    if (acErr != null) {
      _snack(acErr, isError: true);
      return;
    }
    setState(() => _loading = true);

    final accounts = _accountPayloadForType();
    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'itemType': _itemType.value,
      'salesPrice': _showsSalesPrice(_itemType)
          ? double.tryParse(_salesPriceCtrl.text) ?? 0
          : 0,
      'purchasePrice': _showsPurchaseCost(_itemType)
          ? double.tryParse(_purchasePriceCtrl.text) ?? 0
          : 0,
      if (_skuCtrl.text.trim().isNotEmpty) 'sku': _skuCtrl.text.trim(),
      if (_barcodeCtrl.text.trim().isNotEmpty)
        'barcode': _barcodeCtrl.text.trim(),
      if (_showsUnit(_itemType) && _unitCtrl.text.trim().isNotEmpty)
        'unit': _unitCtrl.text.trim(),
      if (!widget.isEdit && _tracksInventory(_itemType))
        'quantityOnHand': double.tryParse(_qtyCtrl.text) ?? 0,
      if (accounts['incomeAccountId'] != null)
        'incomeAccountId': accounts['incomeAccountId'],
      if (accounts['inventoryAssetAccountId'] != null)
        'inventoryAssetAccountId': accounts['inventoryAssetAccountId'],
      if (accounts['cogsAccountId'] != null)
        'cogsAccountId': accounts['cogsAccountId'],
      if (accounts['expenseAccountId'] != null)
        'expenseAccountId': accounts['expenseAccountId'],
    };

    final ApiResult<ItemModel> result = widget.isEdit
        ? await ref.read(itemsProvider.notifier).updateItem(widget.id!, body)
        : await ref.read(itemsProvider.notifier).createItem(body);

    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) {
        _snack(widget.isEdit ? l10n.itemUpdated : l10n.itemCreated);
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
          // â”€â”€ Tool Strip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  widget.isEdit ? l10n.editItem : l10n.newItem,
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
                  label: Text(l10n.barcodeCenter),
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
                    child: Text(
                      widget.isEdit ? l10n.saveChanges : l10n.createItem,
                    ),
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

          // â”€â”€ Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: busy && _loadingAccounts && !widget.isEdit
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _ItemFormHero(
                          isEdit: widget.isEdit,
                          itemType: _typeLabel(_itemType, l10n),
                          name: _nameCtrl.text,
                          barcode: _barcodeCtrl.text,
                          unit: _unitCtrl.text,
                          salesPrice:
                              double.tryParse(_salesPriceCtrl.text) ?? 0,
                          purchasePrice:
                              double.tryParse(_purchasePriceCtrl.text) ?? 0,
                          showSalesPrice: _showsSalesPrice(_itemType),
                          showPurchaseCost: _showsPurchaseCost(_itemType),
                          showUnit: _showsUnit(_itemType),
                          isDiscount: _itemType == ItemType.discount,
                          quantityOnHand: _tracksInventory(_itemType)
                              ? double.tryParse(_qtyCtrl.text) ?? 0
                              : null,
                          currency: 'EGP',
                          l10n: l10n,
                          onGenerateBarcode: _generateBarcode,
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left panel â€” Basic info
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _Section(
                                        title: l10n.itemDetails,
                                        icon: Icons.inventory_2_outlined,
                                        children: [
                                          // Item type
                                          DropdownButtonFormField<ItemType>(
                                            initialValue: _itemType,
                                            decoration: InputDecoration(
                                              labelText: l10n.itemTypeRequired,
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            items: ItemType.values
                                                .map(
                                                  (t) => DropdownMenuItem(
                                                    value: t,
                                                    child: Text(
                                                      _typeLabel(t, l10n),
                                                    ),
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
                                                    setState(() {
                                                      _itemType = v;
                                                      if (!_showsUnit(v)) {
                                                        _unitCtrl.clear();
                                                      } else if (_unitCtrl.text
                                                          .trim()
                                                          .isEmpty) {
                                                        _unitCtrl.text =
                                                            _tracksInventory(v)
                                                            ? 'pcs'
                                                            : 'hr';
                                                      }
                                                    });
                                                    _applyDefaults(force: true);
                                                  },
                                          ),
                                          const SizedBox(height: 8),
                                          _hint(_typeHint(_itemType, l10n), cs),
                                          if (_loadedItem != null) ...[
                                            const SizedBox(height: 8),
                                            _banner(_loadedItem!, cs, l10n),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _Section(
                                        title: l10n.nameAndBarcode,
                                        icon: Icons.qr_code_2_outlined,
                                        children: [
                                          AppTextField(
                                            label: l10n.itemNameNumber,
                                            controller: _nameCtrl,
                                            hint: l10n.itemNameExample,
                                            onChanged: (_) => setState(() {}),
                                            validator: (v) =>
                                                (v ?? '').trim().isEmpty
                                                ? l10n.required
                                                : null,
                                          ),
                                          const SizedBox(height: 10),
                                          AppTextField(
                                            label: l10n.barcode,
                                            controller: _barcodeCtrl,
                                            hint: l10n.barcodeHint,
                                            keyboardType: TextInputType.text,
                                            onChanged: (_) => setState(() {}),
                                            validator: (v) =>
                                                _barcodeVal(v, l10n),
                                            suffixIcon: Tooltip(
                                              message:
                                                  l10n.generateInternalBarcode,
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
                                              title: Text(
                                                l10n.advancedIdentifiers,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              subtitle: Text(
                                                l10n.advancedIdentifiersHint,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                              children: [
                                                AppTextField(
                                                  label: l10n.partNoSkuOptional,
                                                  controller: _skuCtrl,
                                                  hint: 'INV-001',
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_showsUnit(_itemType)) ...[
                                            const SizedBox(height: 10),
                                            ItemUnitSelector(
                                              initialValue:
                                                  _unitCtrl.text.isEmpty
                                                  ? null
                                                  : _unitCtrl.text,
                                              onChanged: (v) => setState(
                                                () => _unitCtrl.text = v ?? '',
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (_showsSalesPrice(_itemType) ||
                                          _showsPurchaseCost(_itemType) ||
                                          (!widget.isEdit &&
                                              _tracksInventory(_itemType))) ...[
                                        const SizedBox(height: 16),
                                        _Section(
                                          title: _itemType == ItemType.discount
                                              ? l10n.discount
                                              : l10n.pricing,
                                          icon: Icons.price_change_outlined,
                                          children: [
                                            Row(
                                              children: [
                                                if (_showsSalesPrice(_itemType))
                                                  Expanded(
                                                    child: AppTextField(
                                                      label:
                                                          _itemType ==
                                                              ItemType.discount
                                                          ? l10n.discountAmountPercent
                                                          : l10n.salesPrice,
                                                      controller:
                                                          _salesPriceCtrl,
                                                      hint: '0.00',
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                      validator: (v) =>
                                                          _numVal(v, l10n),
                                                      onChanged: (_) =>
                                                          setState(() {}),
                                                    ),
                                                  ),
                                                if (_showsSalesPrice(
                                                      _itemType,
                                                    ) &&
                                                    _showsPurchaseCost(
                                                      _itemType,
                                                    ))
                                                  const SizedBox(width: 10),
                                                if (_showsPurchaseCost(
                                                  _itemType,
                                                ))
                                                  Expanded(
                                                    child: AppTextField(
                                                      label:
                                                          _tracksInventory(
                                                            _itemType,
                                                          )
                                                          ? l10n.purchaseCost
                                                          : l10n.purchaseExpenseCost,
                                                      controller:
                                                          _purchasePriceCtrl,
                                                      hint: '0.00',
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                      validator: (v) =>
                                                          _numVal(v, l10n),
                                                      onChanged: (_) =>
                                                          setState(() {}),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (_itemType == ItemType.discount)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 6,
                                                ),
                                                child: _hint(
                                                  l10n.discountItemHint,
                                                  cs,
                                                ),
                                              ),
                                            if (!widget.isEdit &&
                                                _tracksInventory(
                                                  _itemType,
                                                )) ...[
                                              const SizedBox(height: 10),
                                              AppTextField(
                                                label: l10n.openingQtyOnHand,
                                                controller: _qtyCtrl,
                                                hint: '0',
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                validator: (v) {
                                                  final base = _numVal(v, l10n);
                                                  if (base != null) {
                                                    return base;
                                                  }
                                                  final qty =
                                                      double.tryParse(
                                                        v ?? '',
                                                      ) ??
                                                      0;
                                                  final cost =
                                                      double.tryParse(
                                                        _purchasePriceCtrl.text,
                                                      ) ??
                                                      0;
                                                  if (qty > 0 && cost <= 0) {
                                                    return l10n
                                                        .purchaseCostRequiredForOpeningQty;
                                                  }
                                                  return null;
                                                },
                                                onChanged: (_) =>
                                                    setState(() {}),
                                              ),
                                              const SizedBox(height: 6),
                                              _hint(l10n.openingQtyHint, cs),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              // Divider
                              VerticalDivider(
                                width: 1,
                                color: cs.outlineVariant.withValues(alpha: 0.4),
                              ),
                              // Right panel â€” Accounts
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: _Section(
                                    title: l10n.postingAccounts,
                                    icon: Icons.account_tree_outlined,
                                    children: [
                                      _hint(_accountsHint(_itemType, l10n), cs),
                                      const SizedBox(height: 12),
                                      if (_needsIncomeAccount(_itemType)) ...[
                                        _AccountPicker(
                                          label: _incomeAccountLabel(
                                            _itemType,
                                            l10n,
                                          ),
                                          value: _incomeAccountId,
                                          accounts: _incomeAccounts(_itemType),
                                          notSelectedLabel: l10n.notSelected,
                                          onChanged: (v) => setState(
                                            () => _incomeAccountId = v,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      if (_tracksInventory(_itemType)) ...[
                                        _AccountPicker(
                                          label: l10n
                                              .inventoryAssetAccountRequired,
                                          value: _inventoryAssetAccountId,
                                          accounts: _filter([
                                            api.AccountType.inventoryAsset,
                                            api.AccountType.otherCurrentAsset,
                                          ]),
                                          notSelectedLabel: l10n.notSelected,
                                          onChanged: (v) => setState(
                                            () => _inventoryAssetAccountId = v,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        _AccountPicker(
                                          label: l10n.cogsAccountRequired,
                                          value: _cogsAccountId,
                                          accounts: _filter([
                                            api.AccountType.costOfGoodsSold,
                                          ]),
                                          notSelectedLabel: l10n.notSelected,
                                          onChanged: (v) => setState(
                                            () => _cogsAccountId = v,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      if (_needsExpenseAccount(_itemType) ||
                                          _itemType == ItemType.fixedAsset) ...[
                                        _AccountPicker(
                                          label:
                                              _itemType == ItemType.fixedAsset
                                              ? l10n.assetExpenseAccount
                                              : l10n.expensePurchaseAccount,
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
                                          notSelectedLabel: l10n.notSelected,
                                          onChanged: (v) => setState(
                                            () => _expenseAccountId = v,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      if (_postsThroughComponents(_itemType))
                                        _hint(l10n.componentPostingHint, cs),
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

  List<AccountModel> _incomeAccounts(ItemType t) => _filter(
    t == ItemType.payment
        ? [
            api.AccountType.bank,
            api.AccountType.income,
            api.AccountType.otherIncome,
          ]
        : [api.AccountType.income, api.AccountType.otherIncome],
  );

  static String _typeLabel(ItemType t, AppLocalizations l10n) => switch (t) {
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

  static String _typeHint(ItemType t, AppLocalizations l10n) => switch (t) {
    ItemType.inventory => l10n.typeHintInventory,
    ItemType.nonInventory => l10n.typeHintNonInventory,
    ItemType.service => l10n.typeHintService,
    ItemType.bundle => l10n.typeHintBundle,
    ItemType.inventoryAssembly => l10n.typeHintInventoryAssembly,
    ItemType.fixedAsset => l10n.typeHintFixedAsset,
    ItemType.otherCharge => l10n.typeHintOtherCharge,
    ItemType.subtotal => l10n.typeHintSubtotal,
    ItemType.group => l10n.typeHintGroup,
    ItemType.discount => l10n.typeHintDiscount,
    ItemType.payment => l10n.typeHintPayment,
  };

  static String _accountsHint(ItemType t, AppLocalizations l10n) => switch (t) {
    ItemType.inventory => l10n.accountsHintInventory,
    ItemType.nonInventory => l10n.accountsHintNonInventory,
    ItemType.service => l10n.accountsHintService,
    ItemType.bundle => l10n.accountsHintBundle,
    ItemType.inventoryAssembly => l10n.accountsHintInventoryAssembly,
    ItemType.fixedAsset => l10n.accountsHintFixedAsset,
    ItemType.otherCharge => l10n.accountsHintOtherCharge,
    ItemType.subtotal => l10n.accountsHintSubtotal,
    ItemType.group => l10n.accountsHintGroup,
    ItemType.discount => l10n.accountsHintDiscount,
    ItemType.payment => l10n.accountsHintPayment,
  };

  static bool _tracksInventory(ItemType t) =>
      t == ItemType.inventory || t == ItemType.inventoryAssembly;

  static bool _isSalesOrPurchaseItem(ItemType t) =>
      t == ItemType.service ||
      t == ItemType.nonInventory ||
      t == ItemType.otherCharge;

  static bool _needsIncomeAccount(ItemType t) =>
      _tracksInventory(t) ||
      _isSalesOrPurchaseItem(t) ||
      t == ItemType.discount ||
      t == ItemType.payment;

  static bool _needsExpenseAccount(ItemType t) =>
      _isSalesOrPurchaseItem(t) || t == ItemType.fixedAsset;

  static bool _showsSalesPrice(ItemType t) =>
      _tracksInventory(t) ||
      _isSalesOrPurchaseItem(t) ||
      t == ItemType.discount ||
      t == ItemType.fixedAsset;

  static bool _showsPurchaseCost(ItemType t) =>
      _tracksInventory(t) ||
      _isSalesOrPurchaseItem(t) ||
      t == ItemType.fixedAsset;

  static bool _showsUnit(ItemType t) =>
      _tracksInventory(t) ||
      _isSalesOrPurchaseItem(t) ||
      t == ItemType.fixedAsset;

  static String _incomeAccountLabel(ItemType t, AppLocalizations l10n) =>
      switch (t) {
        ItemType.inventory ||
        ItemType.inventoryAssembly => l10n.incomeAccountRequired,
        ItemType.discount => l10n.discountAccountRequired,
        ItemType.payment => l10n.depositPaymentAccountRequired,
        _ => l10n.incomeAccount,
      };

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

  static Widget _banner(
    ItemModel item,
    ColorScheme cs,
    AppLocalizations l10n,
  ) => Container(
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
          '${l10n.qtyOnHand}: ${item.quantityOnHand.toStringAsFixed(2)} ${item.unit ?? ''} - ${item.isActive ? l10n.active : l10n.inactive}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

// â”€â”€ Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ItemFormHero extends StatelessWidget {
  const _ItemFormHero({
    required this.isEdit,
    required this.itemType,
    required this.name,
    required this.barcode,
    required this.unit,
    required this.salesPrice,
    required this.purchasePrice,
    required this.showSalesPrice,
    required this.showPurchaseCost,
    required this.showUnit,
    required this.isDiscount,
    required this.quantityOnHand,
    required this.currency,
    required this.l10n,
    required this.onGenerateBarcode,
  });

  final bool isEdit;
  final String itemType;
  final String name;
  final String barcode;
  final String unit;
  final double salesPrice;
  final double purchasePrice;
  final bool showSalesPrice;
  final bool showPurchaseCost;
  final bool showUnit;
  final bool isDiscount;
  final double? quantityOnHand;
  final String currency;
  final AppLocalizations l10n;
  final VoidCallback onGenerateBarcode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = name.trim().isEmpty ? l10n.newItemHero : name.trim();
    final code = barcode.trim().isEmpty ? l10n.noBarcodeYet : barcode.trim();
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
                        isEdit
                            ? l10n.edit.toUpperCase()
                            : l10n.newText.toUpperCase(),
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
                    if (showUnit)
                      _HeroChip(icon: Icons.straighten_outlined, text: unit),
                    if (quantityOnHand != null)
                      _HeroChip(
                        icon: Icons.warehouse_outlined,
                        text:
                            '${l10n.onHand} ${quantityOnHand!.toStringAsFixed(2)}',
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
                if (showSalesPrice || showPurchaseCost) ...[
                  Row(
                    children: [
                      if (showSalesPrice)
                        Expanded(
                          child: _MetricBox(
                            label: isDiscount ? l10n.discount : l10n.sales,
                            value: '${salesPrice.toStringAsFixed(2)} $currency',
                          ),
                        ),
                      if (showSalesPrice && showPurchaseCost)
                        const SizedBox(width: 8),
                      if (showPurchaseCost)
                        Expanded(
                          child: _MetricBox(
                            label: l10n.cost,
                            value:
                                '${purchasePrice.toStringAsFixed(2)} $currency',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
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
                        tooltip: l10n.generateBarcode,
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

// â”€â”€ Tool Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Account Picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.label,
    required this.value,
    required this.accounts,
    required this.notSelectedLabel,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<AccountModel> accounts;
  final String notSelectedLabel;
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
      DropdownMenuItem<String?>(value: null, child: Text(notSelectedLabel)),
      ...accounts.map(
        (a) => DropdownMenuItem<String?>(
          value: a.id,
          child: Text(
            '${a.code} â€” ${a.name}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ],
    onChanged: onChanged,
  );
}

// item_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../widgets/item_unit_selector.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, this.id});
  final String? id;
  bool get isEdit => id != null;
  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl         = TextEditingController();
  final _skuCtrl          = TextEditingController();
  final _barcodeCtrl      = TextEditingController();
  final _unitCtrl         = TextEditingController(text: 'pcs');
  final _salesPriceCtrl   = TextEditingController(text: '0');
  final _purchasePriceCtrl= TextEditingController(text: '0');
  final _qtyCtrl          = TextEditingController(text: '0');

  ItemType _itemType = ItemType.inventory;
  bool _loading = false;
  bool _loadingItem = false;
  bool _loadingAccounts = true;
  List<AccountModel> _accounts = const [];
  ItemModel? _loadedItem;

  String? _incomeAccountId;
  String? _inventoryAssetAccountId;
  String? _cogsAccountId;
  String? _expenseAccountId;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    if (widget.isEdit) _loadItem();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _skuCtrl.dispose(); _barcodeCtrl.dispose();
    _unitCtrl.dispose(); _salesPriceCtrl.dispose(); _purchasePriceCtrl.dispose();
    _qtyCtrl.dispose(); super.dispose();
  }

  Future<void> _loadAccounts() async {
    final result = await ref.read(accountsRepositoryProvider).getAccounts(includeInactive: false);
    if (!mounted) return;
    result.when(
      success: (accounts) {
        setState(() { _accounts = accounts; _loadingAccounts = false; });
        _applyDefaults();
      },
      failure: (e) { setState(() => _loadingAccounts = false); _snack(e.message, isError: true); },
    );
  }

  Future<void> _loadItem() async {
    setState(() => _loadingItem = true);
    final result = await ref.read(itemsRepositoryProvider).getItem(widget.id!);
    if (!mounted) return;
    result.when(
      success: (item) {
        _nameCtrl.text          = item.name;
        _skuCtrl.text           = item.sku ?? '';
        _barcodeCtrl.text       = item.barcode ?? '';
        _unitCtrl.text          = item.unit ?? 'pcs';
        _salesPriceCtrl.text    = item.salesPrice.toString();
        _purchasePriceCtrl.text = item.purchasePrice.toString();
        _qtyCtrl.text           = item.quantityOnHand.toString();
        setState(() {
          _loadedItem              = item;
          _itemType                = item.itemType;
          _incomeAccountId         = item.incomeAccountId;
          _inventoryAssetAccountId = item.inventoryAssetAccountId;
          _cogsAccountId           = item.cogsAccountId;
          _expenseAccountId        = item.expenseAccountId;
          _loadingItem             = false;
        });
      },
      failure: (e) { setState(() => _loadingItem = false); _snack(e.message, isError: true); },
    );
  }

  void _applyDefaults({bool force = false}) {
    if (_accounts.isEmpty) return;
    String? find(List<api.AccountType> types, List<String> kw) {
      final pool = _accounts.where((a) => a.isActive && types.contains(a.accountType)).toList();
      for (final k in kw) {
        final m = pool.cast<AccountModel?>().firstWhere(
          (a) => a!.name.toLowerCase().contains(k), orElse: () => null);
        if (m != null) return m.id;
      }
      return pool.isEmpty ? null : pool.first.id;
    }
    setState(() {
      if (force) { _incomeAccountId = _inventoryAssetAccountId = _cogsAccountId = _expenseAccountId = null; }
      _incomeAccountId         ??= find([api.AccountType.income, api.AccountType.otherIncome], ['sales income', 'income']);
      _inventoryAssetAccountId ??= find([api.AccountType.inventoryAsset, api.AccountType.otherCurrentAsset], ['inventory asset', 'inventory']);
      _cogsAccountId           ??= find([api.AccountType.costOfGoodsSold], ['cost of goods', 'cogs']);
      _expenseAccountId        ??= find([api.AccountType.expense, api.AccountType.otherExpense, api.AccountType.costOfGoodsSold], ['expense', 'cost']);
    });
  }

  String? _numVal(String? v) {
    final n = double.tryParse(v ?? '');
    if (n == null) return 'Invalid number';
    if (n < 0) return 'Cannot be negative';
    return null;
  }

  String? _validateAccounts() {
    if (_itemType == ItemType.inventory) {
      if (_incomeAccountId == null) return 'Income account required.';
      if (_inventoryAssetAccountId == null) return 'Inventory asset account required.';
      if (_cogsAccountId == null) return 'COGS account required.';
    }
    if ((_itemType == ItemType.service || _itemType == ItemType.nonInventory) &&
        _incomeAccountId == null && _expenseAccountId == null) {
      return 'Income or expense account required.';
    }
    if (_itemType == ItemType.bundle && _incomeAccountId != null) {
      return 'Bundle items should not have an income account.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final acErr = _validateAccounts();
    if (acErr != null) { _snack(acErr, isError: true); return; }
    setState(() => _loading = true);

    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'itemType': _itemType.value,
      'salesPrice': double.tryParse(_salesPriceCtrl.text) ?? 0,
      'purchasePrice': double.tryParse(_purchasePriceCtrl.text) ?? 0,
      if (_skuCtrl.text.trim().isNotEmpty) 'sku': _skuCtrl.text.trim(),
      if (_barcodeCtrl.text.trim().isNotEmpty) 'barcode': _barcodeCtrl.text.trim(),
      if (_unitCtrl.text.trim().isNotEmpty) 'unit': _unitCtrl.text.trim(),
      if (!widget.isEdit && _itemType == ItemType.inventory)
        'quantityOnHand': double.tryParse(_qtyCtrl.text) ?? 0,
      if (_incomeAccountId != null) 'incomeAccountId': _incomeAccountId,
      if (_inventoryAssetAccountId != null) 'inventoryAssetAccountId': _inventoryAssetAccountId,
      if (_cogsAccountId != null) 'cogsAccountId': _cogsAccountId,
      if (_expenseAccountId != null) 'expenseAccountId': _expenseAccountId,
    };

    final ApiResult<ItemModel> result = widget.isEdit
        ? await ref.read(itemsProvider.notifier).updateItem(widget.id!, body)
        : await ref.read(itemsProvider.notifier).createItem(body);

    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) { _snack(widget.isEdit ? 'Item updated.' : 'Item created.'); context.popOrGo(AppRoutes.items); },
      failure: (e) => _snack(e.message, isError: true),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : null),
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
              border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.5))),
            ),
            child: Row(children: [
              const SizedBox(width: 8),
              _TBtn(icon: Icons.arrow_back, label: l10n.cancel, onTap: _loading ? null : () => context.popOrGo(AppRoutes.items)),
              const SizedBox(width: 12),
              Text(
                widget.isEdit ? 'Edit Item' : 'New Item',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
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
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
            ]),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Expanded(
            child: busy && _loadingAccounts && !widget.isEdit
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left panel — Basic info
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Section(title: 'Item Details', icon: Icons.inventory_2_outlined, children: [
                                  // Item type
                                  DropdownButtonFormField<ItemType>(
                                    initialValue: _itemType,
                                    decoration: const InputDecoration(labelText: 'Item Type *', border: OutlineInputBorder(), isDense: true),
                                    items: ItemType.values.map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t)))).toList(),
                                    onChanged: widget.isEdit && (_loadedItem?.quantityOnHand ?? 0) != 0 ? null : (v) {
                                      if (v == null) return;
                                      setState(() => _itemType = v);
                                      _applyDefaults(force: true);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _hint(_typeHint(_itemType), cs),
                                  if (_loadedItem != null) ...[
                                    const SizedBox(height: 8),
                                    _banner(_loadedItem!, cs),
                                  ],
                                ]),
                                const SizedBox(height: 16),
                                _Section(title: 'Name & Identifiers', icon: Icons.label_outline, children: [
                                  AppTextField(
                                    label: 'Item Name *',
                                    controller: _nameCtrl,
                                    hint: 'e.g. Thermal Printer',
                                    validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(child: AppTextField(label: 'SKU / Part No.', controller: _skuCtrl, hint: 'INV-001')),
                                    const SizedBox(width: 10),
                                    Expanded(child: AppTextField(label: 'Barcode', controller: _barcodeCtrl, hint: '6221000000', keyboardType: TextInputType.number)),
                                  ]),
                                  const SizedBox(height: 10),
                                  ItemUnitSelector(
                                    initialValue: _unitCtrl.text.isEmpty ? null : _unitCtrl.text,
                                    onChanged: (v) => _unitCtrl.text = v ?? '',
                                  ),
                                ]),
                                const SizedBox(height: 16),
                                _Section(title: 'Pricing', icon: Icons.price_change_outlined, children: [
                                  Row(children: [
                                    Expanded(child: AppTextField(
                                      label: 'Sales Price',
                                      controller: _salesPriceCtrl,
                                      hint: '0.00',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: _numVal,
                                    )),
                                    const SizedBox(width: 10),
                                    Expanded(child: AppTextField(
                                      label: 'Purchase Cost',
                                      controller: _purchasePriceCtrl,
                                      hint: '0.00',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: _numVal,
                                    )),
                                  ]),
                                  if (!widget.isEdit && _itemType == ItemType.inventory) ...[
                                    const SizedBox(height: 10),
                                    AppTextField(
                                      label: 'Opening Qty on Hand',
                                      controller: _qtyCtrl,
                                      hint: '0',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (v) {
                                        final base = _numVal(v);
                                        if (base != null) return base;
                                        final qty = double.tryParse(v ?? '') ?? 0;
                                        final cost = double.tryParse(_purchasePriceCtrl.text) ?? 0;
                                        if (qty > 0 && cost <= 0) return 'Purchase cost required for opening qty';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 6),
                                    _hint('Opening qty > 0 posts an opening inventory value via the purchase cost.', cs),
                                  ],
                                ]),
                              ],
                            ),
                          ),
                        ),
                        // Divider
                        VerticalDivider(width: 1, color: cs.outlineVariant.withOpacity(0.4)),
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
                                if (_itemType != ItemType.bundle) ...[
                                  _AccountPicker(
                                    label: _itemType == ItemType.inventory ? 'Income Account *' : 'Income Account',
                                    value: _incomeAccountId,
                                    accounts: _filter([api.AccountType.income, api.AccountType.otherIncome]),
                                    onChanged: (v) => setState(() => _incomeAccountId = v),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                if (_itemType == ItemType.inventory) ...[
                                  _AccountPicker(
                                    label: 'Inventory Asset Account *',
                                    value: _inventoryAssetAccountId,
                                    accounts: _filter([api.AccountType.inventoryAsset, api.AccountType.otherCurrentAsset]),
                                    onChanged: (v) => setState(() => _inventoryAssetAccountId = v),
                                  ),
                                  const SizedBox(height: 10),
                                  _AccountPicker(
                                    label: 'COGS Account *',
                                    value: _cogsAccountId,
                                    accounts: _filter([api.AccountType.costOfGoodsSold]),
                                    onChanged: (v) => setState(() => _cogsAccountId = v),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                if (_itemType == ItemType.service || _itemType == ItemType.nonInventory) ...[
                                  _AccountPicker(
                                    label: 'Expense / Purchase Account',
                                    value: _expenseAccountId,
                                    accounts: _filter([api.AccountType.expense, api.AccountType.otherExpense, api.AccountType.costOfGoodsSold]),
                                    onChanged: (v) => setState(() => _expenseAccountId = v),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                if (_itemType == ItemType.bundle)
                                  _hint('Bundle items do not post directly. Accounting flows through component items.', cs),
                              ],
                            ),
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
      _accounts.where((a) => a.isActive && types.contains(a.accountType)).toList()
        ..sort((a, b) => a.code.compareTo(b.code));

  static String _typeLabel(ItemType t) => switch (t) {
    ItemType.inventory    => 'Inventory Part',
    ItemType.nonInventory => 'Non-inventory Part',
    ItemType.service      => 'Service',
    ItemType.bundle       => 'Bundle / Group',
  };

  static String _typeHint(ItemType t) => switch (t) {
    ItemType.inventory    => 'Tracks quantity on hand and posts to Inventory Asset + COGS.',
    ItemType.nonInventory => 'Does not track stock. Can be bought, sold, or both.',
    ItemType.service      => 'Labor or non-stock work. Can be sold or purchased.',
    ItemType.bundle       => 'Groups items on sales forms. Accounting flows through components.',
  };

  static String _accountsHint(ItemType t) => switch (t) {
    ItemType.inventory    => 'Inventory items require Income, Inventory Asset, and COGS accounts.',
    ItemType.nonInventory => 'Use Income and/or Expense account.',
    ItemType.service      => 'Use Income and/or Expense account.',
    ItemType.bundle       => 'Bundle items post through their component items.',
  };

  static Widget _hint(String text, ColorScheme cs) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline, size: 15, color: cs.onPrimaryContainer),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer))),
    ]),
  );

  static Widget _banner(ItemModel item, ColorScheme cs) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Icon(item.isActive ? Icons.check_circle_outline : Icons.block_outlined,
        size: 15, color: item.isActive ? cs.primary : cs.error),
      const SizedBox(width: 8),
      Text(
        'Qty on hand: ${item.quantityOnHand.toStringAsFixed(2)} ${item.unit ?? ''} · ${item.isActive ? 'Active' : 'Inactive'}',
        style: const TextStyle(fontSize: 12),
      ),
    ]),
  );
}

// ── Section ───────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});
  final String title; final IconData icon; final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
      const SizedBox(height: 10),
      ...children,
    ]);
  }
}

// ── Tool Button ───────────────────────────────────────────────────────────────
class _TBtn extends StatelessWidget {
  const _TBtn({required this.icon, required this.label, required this.onTap});
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

// ── Account Picker ────────────────────────────────────────────────────────────
class _AccountPicker extends StatelessWidget {
  const _AccountPicker({required this.label, required this.value, required this.accounts, required this.onChanged});
  final String label; final String? value;
  final List<AccountModel> accounts; final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String?>(
    initialValue: accounts.any((a) => a.id == value) ? value : null,
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
    items: [
      const DropdownMenuItem<String?>(value: null, child: Text('Not selected')),
      ...accounts.map((a) => DropdownMenuItem<String?>(value: a.id, child: Text('${a.code} — ${a.name}', overflow: TextOverflow.ellipsis))),
    ],
    onChanged: onChanged,
  );
}

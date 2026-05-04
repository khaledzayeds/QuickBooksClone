// item_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/api/api_result.dart';
import '../../../core/constants/api_enums.dart' as api;
import '../../../core/navigation/safe_navigation.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
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

  Future<void> _loadAccounts() async {
    final result = await ref.read(accountsRepositoryProvider).getAccounts(includeInactive: false);
    if (!mounted) return;
    result.when(
      success: (accounts) {
        setState(() {
          _accounts = accounts;
          _loadingAccounts = false;
        });
        _applyDefaultAccountsIfEmpty();
      },
      failure: (error) {
        setState(() => _loadingAccounts = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message), backgroundColor: Colors.red));
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
          _incomeAccountId = item.incomeAccountId;
          _inventoryAssetAccountId = item.inventoryAssetAccountId;
          _cogsAccountId = item.cogsAccountId;
          _expenseAccountId = item.expenseAccountId;
          _loadingItem = false;
        });
      },
      failure: (error) {
        setState(() => _loadingItem = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message), backgroundColor: Colors.red));
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final busy = _loading || _loadingItem || _loadingAccounts;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Item' : 'New Item'),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : () => context.popOrGo(AppRoutes.items),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: busy && !widget.isEdit && _loadingAccounts
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(backgroundColor: cs.primaryContainer, child: Icon(Icons.inventory_2_outlined, color: cs.onPrimaryContainer)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.isEdit ? 'Edit item' : 'Create item', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'QuickBooks-style item setup: choose item type, sales/purchase behavior, and posting accounts carefully.',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _ItemTypeHelp(type: _itemType),
                          if (_loadedItem != null) ...[
                            const SizedBox(height: 12),
                            _ItemStatusBanner(item: _loadedItem!),
                          ],
                          const SizedBox(height: 24),
                          DropdownButtonFormField<ItemType>(
                            initialValue: _itemType,
                            decoration: const InputDecoration(labelText: 'Item Type *', border: OutlineInputBorder()),
                            items: ItemType.values.map((type) => DropdownMenuItem(value: type, child: Text(_typeLabel(type)))).toList(),
                            onChanged: widget.isEdit && (_loadedItem?.quantityOnHand ?? 0) != 0
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() => _itemType = value);
                                    _applyDefaultAccountsIfEmpty(forceForType: true);
                                  },
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final two = constraints.maxWidth >= 780;
                              final nameField = AppTextField(
                                label: 'Item Name *',
                                controller: _nameCtrl,
                                hint: 'Example: Thermal Printer',
                                validator: (value) => value == null || value.trim().isEmpty ? 'Item name is required' : null,
                              );
                              final skuField = AppTextField(label: 'SKU / Part No.', controller: _skuCtrl, hint: 'INV-001');
                              final barcodeField = AppTextField(label: 'Barcode', controller: _barcodeCtrl, hint: '6221000000', keyboardType: TextInputType.number);
                              if (!two) {
                                return Column(children: [nameField, const SizedBox(height: 16), skuField, const SizedBox(height: 16), barcodeField]);
                              }
                              return Column(
                                children: [
                                  nameField,
                                  const SizedBox(height: 16),
                                  Row(children: [Expanded(child: skuField), const SizedBox(width: 12), Expanded(child: barcodeField)]),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          ItemUnitSelector(initialValue: _unitCtrl.text.isEmpty ? null : _unitCtrl.text, onChanged: (value) => _unitCtrl.text = value ?? ''),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final two = constraints.maxWidth >= 780;
                              final sales = AppTextField(
                                label: 'Sales Price',
                                controller: _salesPriceCtrl,
                                hint: '0.00',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: _nonNegativeNumberValidator,
                              );
                              final purchase = AppTextField(
                                label: 'Purchase Cost',
                                controller: _purchasePriceCtrl,
                                hint: '0.00',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: _nonNegativeNumberValidator,
                              );
                              if (!two) return Column(children: [sales, const SizedBox(height: 16), purchase]);
                              return Row(children: [Expanded(child: sales), const SizedBox(width: 12), Expanded(child: purchase)]);
                            },
                          ),
                          if (!widget.isEdit && _itemType == ItemType.inventory) ...[
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Opening Quantity on Hand',
                              controller: _qtyCtrl,
                              hint: '0',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: _openingQuantityValidator,
                            ),
                            const SizedBox(height: 8),
                            _InfoBox(
                              icon: Icons.account_balance_outlined,
                              text: 'If opening quantity is greater than zero, the backend posts an opening inventory value. Purchase cost and Inventory Asset account are required.',
                            ),
                          ],
                          const SizedBox(height: 24),
                          _AccountsSection(
                            itemType: _itemType,
                            accounts: _accounts,
                            incomeAccountId: _incomeAccountId,
                            inventoryAssetAccountId: _inventoryAssetAccountId,
                            cogsAccountId: _cogsAccountId,
                            expenseAccountId: _expenseAccountId,
                            onIncomeChanged: (value) => setState(() => _incomeAccountId = value),
                            onInventoryAssetChanged: (value) => setState(() => _inventoryAssetAccountId = value),
                            onCogsChanged: (value) => setState(() => _cogsAccountId = value),
                            onExpenseChanged: (value) => setState(() => _expenseAccountId = value),
                          ),
                          const SizedBox(height: 32),
                          AppButton(label: widget.isEdit ? 'Save Changes' : 'Create Item', loading: _loading, expanded: true, onPressed: _submit),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _applyDefaultAccountsIfEmpty({bool forceForType = false}) {
    if (_accounts.isEmpty) return;
    String? find(List<api.AccountType> types, List<String> keywords) {
      final matches = _accounts.where((a) => a.isActive && types.contains(a.accountType)).toList();
      for (final keyword in keywords) {
        final match = matches.cast<AccountModel?>().firstWhere(
              (a) => a!.name.toLowerCase().contains(keyword.toLowerCase()),
              orElse: () => null,
            );
        if (match != null) return match.id;
      }
      return matches.isEmpty ? null : matches.first.id;
    }

    setState(() {
      if (forceForType) {
        _incomeAccountId = null;
        _inventoryAssetAccountId = null;
        _cogsAccountId = null;
        _expenseAccountId = null;
      }
      _incomeAccountId ??= find([api.AccountType.income, api.AccountType.otherIncome], ['sales income', 'service income', 'income']);
      _inventoryAssetAccountId ??= find([api.AccountType.inventoryAsset, api.AccountType.otherCurrentAsset], ['inventory asset', 'inventory']);
      _cogsAccountId ??= find([api.AccountType.costOfGoodsSold], ['cost of goods', 'cogs']);
      _expenseAccountId ??= find([api.AccountType.expense, api.AccountType.otherExpense, api.AccountType.costOfGoodsSold], ['general expenses', 'expense', 'cost']);
    });
  }

  String? _nonNegativeNumberValidator(String? value) {
    final number = double.tryParse(value ?? '');
    if (number == null) return 'Invalid number';
    if (number < 0) return 'Cannot be negative';
    return null;
  }

  String? _openingQuantityValidator(String? value) {
    final base = _nonNegativeNumberValidator(value);
    if (base != null) return base;
    final qty = double.tryParse(value ?? '') ?? 0;
    final cost = double.tryParse(_purchasePriceCtrl.text) ?? 0;
    if (qty > 0 && cost <= 0) return 'Opening quantity requires purchase cost greater than zero';
    return null;
  }

  String? _validateAccountLinks() {
    if (_itemType == ItemType.inventory) {
      if (_incomeAccountId == null) return 'Inventory item requires an income account.';
      if (_inventoryAssetAccountId == null) return 'Inventory item requires an inventory asset account.';
      if (_cogsAccountId == null) return 'Inventory item requires a COGS account.';
    }
    if (_itemType == ItemType.service || _itemType == ItemType.nonInventory) {
      if (_incomeAccountId == null && _expenseAccountId == null) {
        return 'Service and non-inventory items require income account, expense account, or both.';
      }
    }
    if (_itemType == ItemType.bundle && _incomeAccountId != null) {
      return 'Bundle items should not post directly to income. Clear income account.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final accountError = _validateAccountLinks();
    if (accountError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accountError), backgroundColor: Colors.red));
      return;
    }

    setState(() => _loading = true);

    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'itemType': _itemType.value,
      'salesPrice': double.tryParse(_salesPriceCtrl.text) ?? 0,
      'purchasePrice': double.tryParse(_purchasePriceCtrl.text) ?? 0,
      if (_skuCtrl.text.trim().isNotEmpty) 'sku': _skuCtrl.text.trim(),
      if (_barcodeCtrl.text.trim().isNotEmpty) 'barcode': _barcodeCtrl.text.trim(),
      if (_unitCtrl.text.trim().isNotEmpty) 'unit': _unitCtrl.text.trim(),
      if (!widget.isEdit && _itemType == ItemType.inventory) 'quantityOnHand': double.tryParse(_qtyCtrl.text) ?? 0,
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
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? 'Item updated successfully' : 'Item created successfully')),
        );
        context.popOrGo(AppRoutes.items);
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message), backgroundColor: Colors.red)),
    );
  }

  static String _typeLabel(ItemType type) => switch (type) {
        ItemType.inventory => 'Inventory Part',
        ItemType.nonInventory => 'Non-inventory Part',
        ItemType.service => 'Service',
        ItemType.bundle => 'Bundle / Group',
      };
}

class _AccountsSection extends StatelessWidget {
  const _AccountsSection({
    required this.itemType,
    required this.accounts,
    required this.incomeAccountId,
    required this.inventoryAssetAccountId,
    required this.cogsAccountId,
    required this.expenseAccountId,
    required this.onIncomeChanged,
    required this.onInventoryAssetChanged,
    required this.onCogsChanged,
    required this.onExpenseChanged,
  });

  final ItemType itemType;
  final List<AccountModel> accounts;
  final String? incomeAccountId;
  final String? inventoryAssetAccountId;
  final String? cogsAccountId;
  final String? expenseAccountId;
  final ValueChanged<String?> onIncomeChanged;
  final ValueChanged<String?> onInventoryAssetChanged;
  final ValueChanged<String?> onCogsChanged;
  final ValueChanged<String?> onExpenseChanged;

  @override
  Widget build(BuildContext context) {
    final showInventory = itemType == ItemType.inventory;
    final showSalesPurchase = itemType != ItemType.bundle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Posting accounts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        _InfoBox(icon: Icons.rule_outlined, text: _ruleText(itemType)),
        const SizedBox(height: 16),
        if (showSalesPurchase)
          _AccountPicker(
            label: itemType == ItemType.inventory ? 'Income Account *' : 'Income Account',
            value: incomeAccountId,
            accounts: _filter(accounts, [api.AccountType.income, api.AccountType.otherIncome]),
            onChanged: onIncomeChanged,
          ),
        if (showSalesPurchase) const SizedBox(height: 12),
        if (showInventory)
          _AccountPicker(
            label: 'Inventory Asset Account *',
            value: inventoryAssetAccountId,
            accounts: _filter(accounts, [api.AccountType.inventoryAsset, api.AccountType.otherCurrentAsset]),
            onChanged: onInventoryAssetChanged,
          ),
        if (showInventory) const SizedBox(height: 12),
        if (showInventory)
          _AccountPicker(
            label: 'COGS Account *',
            value: cogsAccountId,
            accounts: _filter(accounts, [api.AccountType.costOfGoodsSold]),
            onChanged: onCogsChanged,
          ),
        if (showInventory) const SizedBox(height: 12),
        if (itemType == ItemType.service || itemType == ItemType.nonInventory)
          _AccountPicker(
            label: 'Expense / Purchase Account',
            value: expenseAccountId,
            accounts: _filter(accounts, [api.AccountType.expense, api.AccountType.otherExpense, api.AccountType.costOfGoodsSold]),
            onChanged: onExpenseChanged,
          ),
        if (itemType == ItemType.bundle)
          _InfoBox(icon: Icons.inventory_2_outlined, text: 'Bundle items do not post directly. Component items should carry income, COGS, and inventory behavior.'),
      ],
    );
  }

  static List<AccountModel> _filter(List<AccountModel> accounts, List<api.AccountType> types) {
    return accounts.where((account) => account.isActive && types.contains(account.accountType)).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  static String _ruleText(ItemType type) => switch (type) {
        ItemType.inventory => 'Inventory part requires Income, Inventory Asset, and COGS accounts.',
        ItemType.nonInventory => 'Non-inventory part can be sold, purchased, or both. Use Income and/or Expense account.',
        ItemType.service => 'Service can be sold, purchased, or both. Use Income and/or Expense account.',
        ItemType.bundle => 'Bundle/group is a container; posting should happen through component items.',
      };
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({required this.label, required this.value, required this.accounts, required this.onChanged});
  final String label;
  final String? value;
  final List<AccountModel> accounts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: accounts.any((a) => a.id == value) ? value : null,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Not selected')),
        ...accounts.map((account) => DropdownMenuItem<String?>(value: account.id, child: Text('${account.code} — ${account.name}'))),
      ],
      onChanged: onChanged,
    );
  }
}

class _ItemTypeHelp extends StatelessWidget {
  const _ItemTypeHelp({required this.type});
  final ItemType type;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = switch (type) {
      ItemType.inventory => 'Inventory Part tracks quantity on hand and posts to Inventory Asset and COGS.',
      ItemType.nonInventory => 'Non-inventory Part does not track stock; it can be bought, sold, or both.',
      ItemType.service => 'Service is labor or non-stock work; it can be sold or purchased.',
      ItemType.bundle => 'Bundle groups items on sales forms; accounting should flow through components.',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(Icons.info_outline, color: cs.onPrimaryContainer), const SizedBox(width: 10), Expanded(child: Text(text, style: TextStyle(color: cs.onPrimaryContainer)))]),
    );
  }
}

class _ItemStatusBanner extends StatelessWidget {
  const _ItemStatusBanner({required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(item.isActive ? Icons.check_circle_outline : Icons.block_outlined, color: item.isActive ? cs.primary : cs.error),
        const SizedBox(width: 10),
        Expanded(child: Text('Quantity on hand: ${item.quantityOnHand.toStringAsFixed(2)} ${item.unit ?? ''} • Status: ${item.isActive ? 'Active' : 'Inactive'}')),
      ]),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: cs.onSecondaryContainer), const SizedBox(width: 10), Expanded(child: Text(text, style: TextStyle(color: cs.onSecondaryContainer)))]),
    );
  }
}

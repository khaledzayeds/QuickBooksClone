import 'package:flutter/material.dart';

import '../../../core/constants/api_enums.dart' as api;
import '../../accounts/data/models/account_model.dart';
import '../../items/data/models/item_model.dart';

class QuickCustomerDraft {
  const QuickCustomerDraft({
    required this.displayName,
    required this.companyName,
    required this.phone,
    required this.email,
    required this.currency,
  });

  final String displayName;
  final String companyName;
  final String phone;
  final String email;
  final String currency;
}

class QuickCustomerDialog extends StatefulWidget {
  const QuickCustomerDialog({super.key});

  @override
  State<QuickCustomerDialog> createState() => _QuickCustomerDialogState();
}

class _QuickCustomerDialogState extends State<QuickCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _currency = 'EGP';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Customer'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Customer name required'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 112,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'EGP', child: Text('EGP')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                      ],
                      onChanged: (value) =>
                          setState(() => _currency = value ?? 'EGP'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              QuickCustomerDraft(
                displayName: _nameCtrl.text.trim(),
                companyName: _companyCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
                email: _emailCtrl.text.trim(),
                currency: _currency,
              ),
            );
          },
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Create'),
        ),
      ],
    );
  }
}

class QuickItemAccountDefaults {
  const QuickItemAccountDefaults({
    required this.incomeAccountId,
    required this.inventoryAssetAccountId,
    required this.cogsAccountId,
    required this.expenseAccountId,
  });

  final String? incomeAccountId;
  final String? inventoryAssetAccountId;
  final String? cogsAccountId;
  final String? expenseAccountId;
}

class QuickItemDraft {
  const QuickItemDraft({
    required this.name,
    required this.itemType,
    required this.salesPrice,
    required this.purchasePrice,
    required this.quantityOnHand,
    required this.sku,
    required this.barcode,
    required this.unit,
    required this.incomeAccountId,
    required this.inventoryAssetAccountId,
    required this.cogsAccountId,
    required this.expenseAccountId,
  });

  final String name;
  final ItemType itemType;
  final double salesPrice;
  final double purchasePrice;
  final double quantityOnHand;
  final String sku;
  final String barcode;
  final String unit;
  final String? incomeAccountId;
  final String? inventoryAssetAccountId;
  final String? cogsAccountId;
  final String? expenseAccountId;

  String? validateAccounts() {
    if (itemType == ItemType.inventory ||
        itemType == ItemType.inventoryAssembly) {
      if (incomeAccountId == null) return 'Income account required.';
      if (inventoryAssetAccountId == null) {
        return 'Inventory asset account required.';
      }
      if (cogsAccountId == null) return 'COGS account required.';
    }
    if ((itemType == ItemType.nonInventory ||
            itemType == ItemType.service ||
            itemType == ItemType.otherCharge ||
            itemType == ItemType.discount) &&
        incomeAccountId == null &&
        expenseAccountId == null) {
      return 'Income or expense account required.';
    }
    return null;
  }

  Map<String, dynamic> toBody() => {
    'name': name,
    'itemType': itemType.value,
    'salesPrice': salesPrice,
    'purchasePrice': purchasePrice,
    if (sku.isNotEmpty) 'sku': sku,
    if (barcode.isNotEmpty) 'barcode': barcode,
    if (unit.isNotEmpty) 'unit': unit,
    if (itemType == ItemType.inventory ||
        itemType == ItemType.inventoryAssembly)
      'quantityOnHand': quantityOnHand,
    if (incomeAccountId != null) 'incomeAccountId': incomeAccountId,
    if (inventoryAssetAccountId != null)
      'inventoryAssetAccountId': inventoryAssetAccountId,
    if (cogsAccountId != null) 'cogsAccountId': cogsAccountId,
    if (expenseAccountId != null) 'expenseAccountId': expenseAccountId,
  };
}

class QuickItemDialog extends StatefulWidget {
  const QuickItemDialog({
    super.key,
    required this.accounts,
    required this.defaults,
    required this.suggestedBarcode,
  });

  final List<AccountModel> accounts;
  final QuickItemAccountDefaults defaults;
  final String suggestedBarcode;

  @override
  State<QuickItemDialog> createState() => _QuickItemDialogState();
}

class _QuickItemDialogState extends State<QuickItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'pcs');
  final _salesPriceCtrl = TextEditingController(text: '0');
  final _purchasePriceCtrl = TextEditingController(text: '0');
  final _qtyCtrl = TextEditingController(text: '0');
  ItemType _itemType = ItemType.inventory;
  String? _incomeAccountId;
  String? _inventoryAssetAccountId;
  String? _cogsAccountId;
  String? _expenseAccountId;

  @override
  void initState() {
    super.initState();
    _barcodeCtrl.text = widget.suggestedBarcode;
    _incomeAccountId = widget.defaults.incomeAccountId;
    _inventoryAssetAccountId = widget.defaults.inventoryAssetAccountId;
    _cogsAccountId = widget.defaults.cogsAccountId;
    _expenseAccountId = widget.defaults.expenseAccountId;
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

  bool get _tracksInventory =>
      _itemType == ItemType.inventory ||
      _itemType == ItemType.inventoryAssembly;

  String? _numberValidator(String? value) {
    final number = double.tryParse(value ?? '');
    if (number == null) return 'Invalid number';
    if (number < 0) return 'Cannot be negative';
    return null;
  }

  List<AccountModel> _accountsFor(List<api.AccountType> types) => widget
      .accounts
      .where((account) => types.contains(account.accountType))
      .toList();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Item'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Item name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Item name required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<ItemType>(
                        initialValue: _itemType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ItemType.inventory,
                            child: Text('Inventory Part'),
                          ),
                          DropdownMenuItem(
                            value: ItemType.nonInventory,
                            child: Text('Non-inventory'),
                          ),
                          DropdownMenuItem(
                            value: ItemType.service,
                            child: Text('Service'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _itemType = value;
                            _unitCtrl.text = _tracksInventory ? 'pcs' : 'hr';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'Generate barcode',
                      onPressed: () => setState(
                        () => _barcodeCtrl.text = widget.suggestedBarcode,
                      ),
                      icon: const Icon(Icons.auto_awesome_outlined),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _skuCtrl,
                        decoration: const InputDecoration(
                          labelText: 'SKU',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _salesPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Sales price',
                          border: OutlineInputBorder(),
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _purchasePriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Purchase cost',
                          border: OutlineInputBorder(),
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (_tracksInventory) ...[
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        child: TextFormField(
                          controller: _qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'On hand',
                            border: OutlineInputBorder(),
                          ),
                          validator: _numberValidator,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _AccountDropdown(
                  label: 'Income account',
                  value: _incomeAccountId,
                  accounts: _accountsFor([
                    api.AccountType.income,
                    api.AccountType.otherIncome,
                  ]),
                  required: true,
                  onChanged: (value) =>
                      setState(() => _incomeAccountId = value),
                ),
                if (_tracksInventory) ...[
                  const SizedBox(height: 10),
                  _AccountDropdown(
                    label: 'Inventory asset account',
                    value: _inventoryAssetAccountId,
                    accounts: _accountsFor([
                      api.AccountType.inventoryAsset,
                      api.AccountType.otherCurrentAsset,
                    ]),
                    required: true,
                    onChanged: (value) =>
                        setState(() => _inventoryAssetAccountId = value),
                  ),
                  const SizedBox(height: 10),
                  _AccountDropdown(
                    label: 'COGS account',
                    value: _cogsAccountId,
                    accounts: _accountsFor([api.AccountType.costOfGoodsSold]),
                    required: true,
                    onChanged: (value) =>
                        setState(() => _cogsAccountId = value),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  _AccountDropdown(
                    label: 'Expense account',
                    value: _expenseAccountId,
                    accounts: _accountsFor([
                      api.AccountType.expense,
                      api.AccountType.otherExpense,
                      api.AccountType.costOfGoodsSold,
                    ]),
                    onChanged: (value) =>
                        setState(() => _expenseAccountId = value),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final draft = QuickItemDraft(
              name: _nameCtrl.text.trim(),
              itemType: _itemType,
              salesPrice: double.tryParse(_salesPriceCtrl.text) ?? 0,
              purchasePrice: double.tryParse(_purchasePriceCtrl.text) ?? 0,
              quantityOnHand: double.tryParse(_qtyCtrl.text) ?? 0,
              sku: _skuCtrl.text.trim(),
              barcode: _barcodeCtrl.text.trim(),
              unit: _unitCtrl.text.trim(),
              incomeAccountId: _incomeAccountId,
              inventoryAssetAccountId: _inventoryAssetAccountId,
              cogsAccountId: _cogsAccountId,
              expenseAccountId: _expenseAccountId,
            );
            final accountError = draft.validateAccounts();
            if (accountError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(accountError),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.of(context).pop(draft);
          },
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Create & Add'),
        ),
      ],
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.label,
    required this.value,
    required this.accounts,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final String? value;
  final List<AccountModel> accounts;
  final ValueChanged<String?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final selected = accounts.any((account) => account.id == value)
        ? value
        : null;
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: accounts
          .map(
            (account) => DropdownMenuItem(
              value: account.id,
              child: Text(
                account.code.isEmpty
                    ? account.name
                    : '${account.code} - ${account.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: required
          ? (value) => value == null ? '$label required' : null
          : null,
    );
  }
}

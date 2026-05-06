// item_form_account_linked_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/api/api_result.dart';
import '../../../core/constants/api_enums.dart' show AccountType;
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
  final _unitCtrl = TextEditingController();
  final _salesPriceCtrl = TextEditingController(text: '0');
  final _purchasePriceCtrl = TextEditingController(text: '0');
  final _qtyCtrl = TextEditingController(text: '0');

  ItemType _itemType = ItemType.inventory;
  String? _incomeAccountId;
  String? _inventoryAssetAccountId;
  String? _cogsAccountId;
  String? _expenseAccountId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadItem();
  }

  Future<void> _loadItem() async {
    final result = await ref.read(itemsRepositoryProvider).getItem(widget.id!);
    result.when(
      success: (item) {
        _nameCtrl.text = item.name;
        _skuCtrl.text = item.sku ?? '';
        _barcodeCtrl.text = item.barcode ?? '';
        _unitCtrl.text = item.unit ?? '';
        _salesPriceCtrl.text = item.salesPrice.toString();
        _purchasePriceCtrl.text = item.purchasePrice.toString();
        _qtyCtrl.text = item.quantityOnHand.toString();
        setState(() {
          _itemType = item.itemType;
          _incomeAccountId = item.incomeAccountId;
          _inventoryAssetAccountId = item.inventoryAssetAccountId;
          _cogsAccountId = item.cogsAccountId;
          _expenseAccountId = item.expenseAccountId;
        });
      },
      failure: (_) {},
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
    final accountsAsync = ref.watch(accountsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'تعديل صنف' : 'صنف جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<ItemType>(
              initialValue: _itemType,
              decoration: const InputDecoration(labelText: 'نوع الصنف *'),
              items: ItemType.values
                  .map(
                    (t) => DropdownMenuItem<ItemType>(
                      value: t,
                      child: Text(t.label),
                    ),
                  )
                  .toList(),
              onChanged: widget.isEdit
                  ? null
                  : (v) => setState(() {
                      _itemType = v!;
                      _inventoryAssetAccountId = null;
                      _cogsAccountId = null;
                      _expenseAccountId = null;
                    }),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'اسم الصنف *',
              controller: _nameCtrl,
              hint: 'مثال: طابعة حرارية',
              validator: (v) =>
                  v == null || v.isEmpty ? 'اسم الصنف مطلوب' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'كود الصنف (SKU)',
                    controller: _skuCtrl,
                    hint: 'INV-001',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'الباركود',
                    controller: _barcodeCtrl,
                    hint: '6221000000',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ItemUnitSelector(
              initialValue: _unitCtrl.text.isEmpty ? null : _unitCtrl.text,
              onChanged: (v) => _unitCtrl.text = v ?? '',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'سعر البيع *',
                    controller: _salesPriceCtrl,
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _nonNegativeNumberValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'سعر الشراء *',
                    controller: _purchasePriceCtrl,
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _nonNegativeNumberValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!widget.isEdit && _itemType == ItemType.inventory) ...[
              AppTextField(
                label: 'الكمية الافتتاحية',
                controller: _qtyCtrl,
                hint: '0',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _nonNegativeNumberValidator,
              ),
              const SizedBox(height: 8),
              Text(
                '* إذا كانت الكمية > 0 مع سعر شراء > 0، سيتم إنشاء قيد مخزون افتتاحي',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'الحسابات المرتبطة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            accountsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                e.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              data: _buildAccountFields,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: widget.isEdit ? 'حفظ التعديلات' : 'إضافة الصنف',
              loading: _loading,
              expanded: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountFields(List<AccountModel> accounts) {
    final active = accounts.where((a) => a.isActive).toList();
    final income = active
        .where(
          (a) =>
              a.accountType == AccountType.income ||
              a.accountType == AccountType.otherIncome,
        )
        .toList();
    final asset = active
        .where(
          (a) =>
              a.accountType == AccountType.inventoryAsset ||
              a.accountType == AccountType.otherCurrentAsset,
        )
        .toList();
    final cogs = active
        .where((a) => a.accountType == AccountType.costOfGoodsSold)
        .toList();
    final expense = active
        .where(
          (a) =>
              a.accountType == AccountType.expense ||
              a.accountType == AccountType.otherExpense,
        )
        .toList();

    return Column(
      children: [
        _AccountDropdown(
          label: 'حساب الإيراد *',
          value: _incomeAccountId,
          accounts: income,
          onChanged: (v) => setState(() => _incomeAccountId = v),
          validator: (v) =>
              v == null || v.isEmpty ? 'حساب الإيراد مطلوب' : null,
        ),
        const SizedBox(height: 16),
        if (_itemType == ItemType.inventory) ...[
          _AccountDropdown(
            label: 'حساب أصل المخزون *',
            value: _inventoryAssetAccountId,
            accounts: asset,
            onChanged: (v) => setState(() => _inventoryAssetAccountId = v),
            validator: (v) =>
                v == null || v.isEmpty ? 'حساب أصل المخزون مطلوب' : null,
          ),
          const SizedBox(height: 16),
          _AccountDropdown(
            label: 'حساب تكلفة المبيعات *',
            value: _cogsAccountId,
            accounts: cogs,
            onChanged: (v) => setState(() => _cogsAccountId = v),
            validator: (v) =>
                v == null || v.isEmpty ? 'حساب تكلفة المبيعات مطلوب' : null,
          ),
        ] else ...[
          _AccountDropdown(
            label: _itemType == ItemType.service
                ? 'حساب المصروفات/التكلفة'
                : 'حساب تكلفة المبيعات',
            value: _itemType == ItemType.service
                ? _expenseAccountId
                : _cogsAccountId,
            accounts: _itemType == ItemType.service ? expense : cogs,
            onChanged: (v) => setState(() {
              if (_itemType == ItemType.service) {
                _expenseAccountId = v;
              } else {
                _cogsAccountId = v;
              }
            }),
          ),
        ],
      ],
    );
  }

  String? _nonNegativeNumberValidator(String? v) {
    final n = double.tryParse(v ?? '');
    if (n == null) return 'رقم غير صحيح';
    if (n < 0) return 'لا يمكن أن يكون سالباً';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'itemType': _itemType.value,
      'salesPrice': double.tryParse(_salesPriceCtrl.text) ?? 0,
      'purchasePrice': double.tryParse(_purchasePriceCtrl.text) ?? 0,
      if (_skuCtrl.text.isNotEmpty) 'sku': _skuCtrl.text.trim(),
      if (_barcodeCtrl.text.isNotEmpty) 'barcode': _barcodeCtrl.text.trim(),
      if (_unitCtrl.text.isNotEmpty) 'unit': _unitCtrl.text.trim(),
      if (!widget.isEdit && _itemType == ItemType.inventory)
        'quantityOnHand': double.tryParse(_qtyCtrl.text) ?? 0,
      if (_incomeAccountId != null) 'incomeAccountId': _incomeAccountId,
      if (_inventoryAssetAccountId != null && _itemType == ItemType.inventory)
        'inventoryAssetAccountId': _inventoryAssetAccountId,
      if (_cogsAccountId != null && _itemType != ItemType.service)
        'cogsAccountId': _cogsAccountId,
      if (_expenseAccountId != null && _itemType == ItemType.service)
        'expenseAccountId': _expenseAccountId,
    };
    final ApiResult<ItemModel> result = widget.isEdit
        ? await ref.read(itemsProvider.notifier).updateItem(widget.id!, body)
        : await ref.read(itemsProvider.notifier).createItem(body);
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit ? 'تم تعديل الصنف بنجاح' : 'تم إضافة الصنف بنجاح',
            ),
          ),
        );
        context.popOrGo(AppRoutes.items);
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.label,
    required this.value,
    required this.accounts,
    required this.onChanged,
    this.validator,
  });
  final String label;
  final String? value;
  final List<AccountModel> accounts;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final safeValue = accounts.any((a) => a.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: accounts
          .map(
            (a) => DropdownMenuItem<String>(
              value: a.id,
              child: Text('${a.code} - ${a.name}'),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

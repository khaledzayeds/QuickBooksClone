// item_form_screen.dart
// item_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_result.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
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
  final _formKey          = GlobalKey<FormState>();
  final _nameCtrl         = TextEditingController();
  final _skuCtrl          = TextEditingController();
  final _barcodeCtrl      = TextEditingController();
  final _unitCtrl         = TextEditingController();
  final _salesPriceCtrl   = TextEditingController(text: '0');
  final _purchasePriceCtrl= TextEditingController(text: '0');
  final _qtyCtrl          = TextEditingController(text: '0');

  ItemType _itemType = ItemType.inventory;
  bool     _loading  = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadItem();
  }

  Future<void> _loadItem() async {
    final result = await ref
        .read(itemsRepositoryProvider)
        .getItem(widget.id!);
    result.when(
      success: (item) {
        _nameCtrl.text          = item.name;
        _skuCtrl.text           = item.sku ?? '';
        _barcodeCtrl.text       = item.barcode ?? '';
        _unitCtrl.text          = item.unit ?? '';
        _salesPriceCtrl.text    = item.salesPrice.toString();
        _purchasePriceCtrl.text = item.purchasePrice.toString();
        _qtyCtrl.text           = item.quantityOnHand.toString();
        setState(() => _itemType = item.itemType);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'تعديل صنف' : 'صنف جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Item Type ─────────────────────────
            DropdownButtonFormField<ItemType>(
              initialValue: _itemType,
              decoration: const InputDecoration(labelText: 'نوع الصنف *'),
              items: ItemType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label),
                      ))
                  .toList(),
              onChanged: widget.isEdit
                  ? null // لا يتغير نوع الصنف بعد الإنشاء
                  : (v) => setState(() => _itemType = v!),
            ),
            const SizedBox(height: 16),

            // ── Name ──────────────────────────────
            AppTextField(
              label:     'اسم الصنف *',
              controller: _nameCtrl,
              hint:      'مثال: طابعة حرارية',
              validator: (v) =>
                  v == null || v.isEmpty ? 'اسم الصنف مطلوب' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label:      'كود الصنف (SKU)',
                    controller: _skuCtrl,
                    hint:       'INV-001',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label:      'الباركود',
                    controller: _barcodeCtrl,
                    hint:       '6221000000',
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

            // ── Prices ────────────────────────────
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label:       'سعر البيع *',
                    controller:  _salesPriceCtrl,
                    hint:        '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null) return 'رقم غير صحيح';
                      if (n < 0)     return 'لا يمكن أن يكون سالباً';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label:       'سعر الشراء *',
                    controller:  _purchasePriceCtrl,
                    hint:        '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null) return 'رقم غير صحيح';
                      if (n < 0)     return 'لا يمكن أن يكون سالباً';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Opening Qty (create + inventory only) ──
            if (!widget.isEdit && _itemType == ItemType.inventory) ...[
              AppTextField(
                label:       'الكمية الافتتاحية',
                controller:  _qtyCtrl,
                hint:        '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null) return 'رقم غير صحيح';
                  if (n < 0)     return 'لا يمكن أن تكون سالبة';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                '* إذا كانت الكمية > 0 مع سعر شراء > 0، سيتم إنشاء قيد مخزون افتتاحي',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.5),
                    ),
              ),
            ],

            const SizedBox(height: 32),

            AppButton(
              label:    widget.isEdit ? 'حفظ التعديلات' : 'إضافة الصنف',
              loading:  _loading,
              expanded: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final body = <String, dynamic>{
      'name':          _nameCtrl.text.trim(),
      'itemType':      _itemType.value,
      'salesPrice':    double.tryParse(_salesPriceCtrl.text) ?? 0,
      'purchasePrice': double.tryParse(_purchasePriceCtrl.text) ?? 0,
      if (_skuCtrl.text.isNotEmpty)     'sku':     _skuCtrl.text.trim(),
      if (_barcodeCtrl.text.isNotEmpty) 'barcode': _barcodeCtrl.text.trim(),
      if (_unitCtrl.text.isNotEmpty)    'unit':    _unitCtrl.text.trim(),
      if (!widget.isEdit && _itemType == ItemType.inventory)
        'quantityOnHand': double.tryParse(_qtyCtrl.text) ?? 0,
    };

    final ApiResult<ItemModel> result = widget.isEdit
        ? await ref
            .read(itemsProvider.notifier)
            .updateItem(widget.id!, body)
        : await ref.read(itemsProvider.notifier).createItem(body);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit
                ? 'تم تعديل الصنف بنجاح'
                : 'تم إضافة الصنف بنجاح'),
          ),
        );
        context.pop();
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}
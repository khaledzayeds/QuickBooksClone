// vendor_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/api/api_result.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/models/vendor_model.dart';
import '../providers/vendors_provider.dart';

class VendorFormScreen extends ConsumerStatefulWidget {
  const VendorFormScreen({super.key, this.id});
  final String? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends ConsumerState<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _openBalCtrl = TextEditingController(text: '0');
  String _currency = 'EGP';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadVendor();
  }

  Future<void> _loadVendor() async {
    final result = await ref.read(vendorsRepositoryProvider).getVendor(widget.id!);
    result.when(
      success: (vendor) {
        _nameCtrl.text = vendor.displayName;
        _companyCtrl.text = vendor.companyName ?? '';
        _emailCtrl.text = vendor.email ?? '';
        _phoneCtrl.text = vendor.phone ?? '';
        setState(() => _currency = vendor.currency);
      },
      failure: (_) {},
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _openBalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'تعديل مورد' : 'مورد جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AppTextField(
              label: 'الاسم *',
              controller: _nameCtrl,
              hint: 'الاسم الكامل للمورد',
              validator: (value) => value == null || value.isEmpty ? 'الاسم مطلوب' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'اسم الشركة', controller: _companyCtrl, hint: 'اختياري'),
            const SizedBox(height: 16),
            AppTextField(
              label: 'البريد الإلكتروني',
              controller: _emailCtrl,
              hint: 'example@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                if (!value.contains('@')) return 'بريد إلكتروني غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'رقم الهاتف',
              controller: _phoneCtrl,
              hint: '01000000000',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(labelText: 'العملة'),
              items: const [
                DropdownMenuItem(value: 'EGP', child: Text('جنيه مصري (EGP)')),
                DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
                DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
              ],
              onChanged: (value) => setState(() => _currency = value!),
            ),
            const SizedBox(height: 16),
            if (!widget.isEdit) ...[
              AppTextField(
                label: 'الرصيد الافتتاحي',
                controller: _openBalCtrl,
                hint: '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  if (number == null) return 'أدخل رقماً صحيحاً';
                  if (number < 0) return 'الرصيد لا يمكن أن يكون سالباً';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                '* إذا كان للمورد رصيد سابق، سيتم إنشاء قيد افتتاحي تلقائياً',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
              ),
            ],
            const SizedBox(height: 32),
            AppButton(
              label: widget.isEdit ? 'حفظ التعديلات' : 'إضافة المورد',
              loading: _loading,
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
      'displayName': _nameCtrl.text.trim(),
      if (_companyCtrl.text.isNotEmpty) 'companyName': _companyCtrl.text.trim(),
      if (_emailCtrl.text.isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      'currency': _currency,
      if (!widget.isEdit) 'openingBalance': double.tryParse(_openBalCtrl.text) ?? 0,
    };

    final ApiResult<VendorModel> result = widget.isEdit
        ? await ref.read(vendorsProvider.notifier).updateVendor(widget.id!, body)
        : await ref.read(vendorsProvider.notifier).createVendor(body);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? 'تم تعديل المورد بنجاح' : 'تم إضافة المورد بنجاح')),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.vendors);
        }
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      ),
    );
  }
}

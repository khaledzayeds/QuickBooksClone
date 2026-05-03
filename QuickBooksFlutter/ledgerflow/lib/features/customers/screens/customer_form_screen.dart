// customer_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/navigation/safe_navigation.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/customers_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.id});
  final String? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
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
    if (widget.isEdit) _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final result = await ref.read(customersRepositoryProvider).getCustomer(widget.id!);
    result.when(
      success: (customer) {
        _nameCtrl.text = customer.displayName;
        _companyCtrl.text = customer.companyName ?? '';
        _emailCtrl.text = customer.email ?? '';
        _phoneCtrl.text = customer.phone ?? '';
        setState(() => _currency = customer.currency);
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
      appBar: AppBar(title: Text(widget.isEdit ? 'تعديل عميل' : 'عميل جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AppTextField(
              label: 'الاسم *',
              controller: _nameCtrl,
              hint: 'الاسم الكامل للعميل',
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
                '* إذا كان للعميل رصيد سابق، سيتم إنشاء قيد افتتاحي تلقائياً',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
              ),
            ],
            const SizedBox(height: 32),
            AppButton(
              label: widget.isEdit ? 'حفظ التعديلات' : 'إضافة العميل',
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

    final result = widget.isEdit
        ? await ref.read(customersProvider.notifier).updateCustomer(widget.id!, body)
        : await ref.read(customersProvider.notifier).createCustomer(body);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? 'تم تعديل العميل بنجاح' : 'تم إضافة العميل بنجاح')),
        );
        context.popOrGo(AppRoutes.customers);
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      ),
    );
  }
}

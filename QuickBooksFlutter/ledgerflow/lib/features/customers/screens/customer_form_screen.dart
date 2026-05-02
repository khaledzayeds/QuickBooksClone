// customer_form_screen.dart
// customer_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

import '../providers/customers_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.id});
  final String? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<CustomerFormScreen> createState() =>
      _CustomerFormScreenState();
}

class _CustomerFormScreenState
    extends ConsumerState<CustomerFormScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _companyCtrl  = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _openBalCtrl  = TextEditingController(text: '0');
  String _currency    = 'EGP';
  bool _loading       = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final result = await ref
        .read(customersRepositoryProvider)
        .getCustomer(widget.id!);
    result.when(
      success: (c) {
        _nameCtrl.text    = c.displayName;
        _companyCtrl.text = c.companyName ?? '';
        _emailCtrl.text   = c.email ?? '';
        _phoneCtrl.text   = c.phone ?? '';
        setState(() => _currency = c.currency);
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
      appBar: AppBar(
        title: Text(widget.isEdit ? 'تعديل عميل' : 'عميل جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AppTextField(
              label: 'الاسم *',
              controller: _nameCtrl,
              hint: 'الاسم الكامل للعميل',
              validator: (v) =>
                  v == null || v.isEmpty ? 'الاسم مطلوب' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'اسم الشركة',
              controller: _companyCtrl,
              hint: 'اختياري',
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'البريد الإلكتروني',
              controller: _emailCtrl,
              hint: 'example@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (!v.contains('@')) return 'بريد إلكتروني غير صحيح';
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

            // Currency
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(labelText: 'العملة'),
              items: const [
                DropdownMenuItem(value: 'EGP', child: Text('جنيه مصري (EGP)')),
                DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
                DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
              ],
              onChanged: (v) => setState(() => _currency = v!),
            ),
            const SizedBox(height: 16),

            // Opening balance (create only)
            if (!widget.isEdit) ...[
              AppTextField(
                label: 'الرصيد الافتتاحي',
                controller: _openBalCtrl,
                hint: '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null) return 'أدخل رقماً صحيحاً';
                  if (n < 0) return 'الرصيد لا يمكن أن يكون سالباً';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                '* إذا كان للعميل رصيد سابق، سيتم إنشاء قيد افتتاحي تلقائياً',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: (0.5 * 255).toDouble()),
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
      if (_emailCtrl.text.isNotEmpty)   'email':       _emailCtrl.text.trim(),
      if (_phoneCtrl.text.isNotEmpty)   'phone':       _phoneCtrl.text.trim(),
      'currency': _currency,
      if (!widget.isEdit)
        'openingBalance': double.tryParse(_openBalCtrl.text) ?? 0,
    };

    final result = widget.isEdit
        ? await ref
            .read(customersProvider.notifier)
            .updateCustomer(widget.id!, body)
        : await ref
            .read(customersProvider.notifier)
            .createCustomer(body);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit
                ? 'تم تعديل العميل بنجاح'
                : 'تم إضافة العميل بنجاح'),
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
// customer_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/navigation/safe_navigation.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/models/customer_model.dart';
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
  bool _loadingCustomer = false;
  CustomerModel? _loadedCustomer;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() => _loadingCustomer = true);
    final result = await ref
        .read(customersRepositoryProvider)
        .getCustomer(widget.id!);
    if (!mounted) return;
    result.when(
      success: (customer) {
        _nameCtrl.text = customer.displayName;
        _companyCtrl.text = customer.companyName ?? '';
        _emailCtrl.text = customer.email ?? '';
        _phoneCtrl.text = customer.phone ?? '';
        setState(() {
          _loadedCustomer = customer;
          _currency = customer.currency;
          _loadingCustomer = false;
        });
      },
      failure: (error) {
        setState(() => _loadingCustomer = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      },
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = _CustomerFormText.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? text.editCustomer : text.newCustomer),
        actions: [
          TextButton.icon(
            onPressed: _loading
                ? null
                : () => context.popOrGo(AppRoutes.customers),
            icon: const Icon(Icons.close),
            label: Text(text.cancel),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loadingCustomer
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
                              CircleAvatar(
                                backgroundColor: cs.primaryContainer,
                                child: Icon(
                                  Icons.person_outline,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isEdit
                                          ? text.editCustomerProfile
                                          : text.createCustomerProfile,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      text.customerRecordHint,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_loadedCustomer != null) ...[
                            const SizedBox(height: 16),
                            _CustomerStatusBanner(customer: _loadedCustomer!),
                          ],
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final two = constraints.maxWidth >= 760;
                              final name = AppTextField(
                                label: text.displayNameRequired,
                                controller: _nameCtrl,
                                hint: text.customerDisplayName,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? text.displayNameRequiredMsg
                                    : null,
                              );
                              final company = AppTextField(
                                label: text.companyName,
                                controller: _companyCtrl,
                                hint: text.optionalCompanyName,
                              );
                              final email = AppTextField(
                                label: text.email,
                                controller: _emailCtrl,
                                hint: 'customer@example.com',
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return null;
                                  }
                                  if (!value.contains('@')) {
                                    return text.invalidEmail;
                                  }
                                  return null;
                                },
                              );
                              final phone = AppTextField(
                                label: text.phone,
                                controller: _phoneCtrl,
                                hint: '01000000000',
                                keyboardType: TextInputType.phone,
                              );

                              if (!two) {
                                return Column(
                                  children: [
                                    name,
                                    const SizedBox(height: 16),
                                    company,
                                    const SizedBox(height: 16),
                                    email,
                                    const SizedBox(height: 16),
                                    phone,
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: name),
                                      const SizedBox(width: 12),
                                      Expanded(child: company),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: email),
                                      const SizedBox(width: 12),
                                      Expanded(child: phone),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _currency,
                            decoration: InputDecoration(
                              labelText: text.currency,
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: 'EGP',
                                child: Text(text.egyptianPound),
                              ),
                              DropdownMenuItem<String>(
                                value: 'USD',
                                child: Text(text.usDollar),
                              ),
                              DropdownMenuItem<String>(
                                value: 'SAR',
                                child: Text(text.saudiRiyal),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _currency = value!),
                          ),
                          if (!widget.isEdit) ...[
                            const SizedBox(height: 16),
                            AppTextField(
                              label: text.openingBalance,
                              controller: _openBalCtrl,
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                final number = double.tryParse(value ?? '');
                                if (number == null) {
                                  return text.enterValidNumber;
                                }
                                if (number < 0) {
                                  return text.openingBalanceCannotBeNegative;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            _InfoBox(
                              icon: Icons.account_balance_outlined,
                              text: text.openingBalanceHint,
                            ),
                          ],
                          const SizedBox(height: 32),
                          AppButton(
                            label: widget.isEdit
                                ? text.saveChanges
                                : text.createCustomer,
                            loading: _loading,
                            expanded: true,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
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
      if (_companyCtrl.text.trim().isNotEmpty)
        'companyName': _companyCtrl.text.trim(),
      if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      'currency': _currency,
      if (!widget.isEdit)
        'openingBalance': double.tryParse(_openBalCtrl.text) ?? 0,
    };

    final result = widget.isEdit
        ? await ref
              .read(customersProvider.notifier)
              .updateCustomer(widget.id!, body)
        : await ref.read(customersProvider.notifier).createCustomer(body);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit
                  ? _CustomerFormText.of(context).customerUpdated
                  : _CustomerFormText.of(context).customerCreated,
            ),
          ),
        );
        context.popOrGo(AppRoutes.customers);
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      ),
    );
  }
}

class _CustomerStatusBanner extends StatelessWidget {
  const _CustomerStatusBanner({required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = _CustomerFormText.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            customer.isActive
                ? Icons.check_circle_outline
                : Icons.block_outlined,
            color: customer.isActive ? cs.primary : cs.error,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text.statusLine(customer))),
        ],
      ),
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
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: cs.onSecondaryContainer)),
          ),
        ],
      ),
    );
  }
}

class _CustomerFormText {
  const _CustomerFormText(this.ar);
  final bool ar;

  static _CustomerFormText of(BuildContext context) =>
      _CustomerFormText(Localizations.localeOf(context).languageCode == 'ar');

  String get editCustomer => ar ? 'تعديل عميل' : 'Edit Customer';
  String get newCustomer => ar ? 'عميل جديد' : 'New Customer';
  String get cancel => ar ? 'إلغاء' : 'Cancel';
  String get editCustomerProfile =>
      ar ? 'تعديل ملف العميل' : 'Edit customer profile';
  String get createCustomerProfile =>
      ar ? 'إنشاء ملف عميل' : 'Create customer profile';
  String get customerRecordHint => ar
      ? 'سجلات العملاء تدير الفواتير والمدفوعات وأرصدة العملاء وكشوف الحساب وتقارير المبيعات.'
      : 'Customer records drive invoices, payments, customer credits, statements, and sales reports.';
  String get displayNameRequired => ar ? 'اسم العرض *' : 'Display Name *';
  String get customerDisplayName =>
      ar ? 'اسم عرض العميل' : 'Customer display name';
  String get displayNameRequiredMsg =>
      ar ? 'اسم العرض مطلوب' : 'Display name is required';
  String get companyName => ar ? 'اسم الشركة' : 'Company Name';
  String get optionalCompanyName =>
      ar ? 'اسم الشركة اختياري' : 'Optional company name';
  String get email => ar ? 'البريد' : 'Email';
  String get phone => ar ? 'الهاتف' : 'Phone';
  String get invalidEmail =>
      ar ? 'عنوان البريد غير صحيح' : 'Invalid email address';
  String get currency => ar ? 'العملة' : 'Currency';
  String get egyptianPound =>
      ar ? 'الجنيه المصري (EGP)' : 'Egyptian Pound (EGP)';
  String get usDollar => ar ? 'الدولار الأمريكي (USD)' : 'US Dollar (USD)';
  String get saudiRiyal => ar ? 'الريال السعودي (SAR)' : 'Saudi Riyal (SAR)';
  String get openingBalance => ar ? 'الرصيد الافتتاحي' : 'Opening Balance';
  String get enterValidNumber =>
      ar ? 'أدخل رقمًا صحيحًا' : 'Enter a valid number';
  String get openingBalanceCannotBeNegative => ar
      ? 'الرصيد الافتتاحي لا يمكن أن يكون سالبًا'
      : 'Opening balance cannot be negative';
  String get openingBalanceHint => ar
      ? 'إذا كان العميل مدينًا بالفعل، سينشئ الرصيد الافتتاحي قيد مديونية افتتاحي تلقائيًا.'
      : 'If this customer already owes money, opening balance will create an opening receivable posting automatically.';
  String get saveChanges => ar ? 'حفظ التعديلات' : 'Save Changes';
  String get createCustomer => ar ? 'إنشاء عميل' : 'Create Customer';
  String get customerUpdated =>
      ar ? 'تم تحديث العميل بنجاح' : 'Customer updated successfully';
  String get customerCreated =>
      ar ? 'تم إنشاء العميل بنجاح' : 'Customer created successfully';

  String statusLine(CustomerModel customer) {
    final status = customer.isActive
        ? (ar ? 'نشط' : 'Active')
        : (ar ? 'غير نشط' : 'Inactive');
    if (ar) {
      return 'الرصيد المفتوح: ${customer.balance.toStringAsFixed(2)} ${customer.currency} · الأرصدة: ${customer.creditBalance.toStringAsFixed(2)} ${customer.currency} · الحالة: $status';
    }
    return 'Open balance: ${customer.balance.toStringAsFixed(2)} ${customer.currency} · Credits: ${customer.creditBalance.toStringAsFixed(2)} ${customer.currency} · Status: $status';
  }
}

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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Customer' : 'New Customer'),
        actions: [
          TextButton.icon(
            onPressed: _loading
                ? null
                : () => context.popOrGo(AppRoutes.customers),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
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
                                          ? 'Edit customer profile'
                                          : 'Create customer profile',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Customer records drive invoices, payments, customer credits, statements, and sales reports.',
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
                                label: 'Display Name *',
                                controller: _nameCtrl,
                                hint: 'Customer display name',
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Display name is required'
                                    : null,
                              );
                              final company = AppTextField(
                                label: 'Company Name',
                                controller: _companyCtrl,
                                hint: 'Optional company name',
                              );
                              final email = AppTextField(
                                label: 'Email',
                                controller: _emailCtrl,
                                hint: 'customer@example.com',
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return null;
                                  if (!value.contains('@'))
                                    return 'Invalid email address';
                                  return null;
                                },
                              );
                              final phone = AppTextField(
                                label: 'Phone',
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
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem<String>(
                                value: 'EGP',
                                child: Text('Egyptian Pound (EGP)'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'USD',
                                child: Text('US Dollar (USD)'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'SAR',
                                child: Text('Saudi Riyal (SAR)'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _currency = value!),
                          ),
                          if (!widget.isEdit) ...[
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Opening Balance',
                              controller: _openBalCtrl,
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                final number = double.tryParse(value ?? '');
                                if (number == null)
                                  return 'Enter a valid number';
                                if (number < 0)
                                  return 'Opening balance cannot be negative';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            _InfoBox(
                              icon: Icons.account_balance_outlined,
                              text:
                                  'If this customer already owes money, opening balance will create an opening receivable posting automatically.',
                            ),
                          ],
                          const SizedBox(height: 32),
                          AppButton(
                            label: widget.isEdit
                                ? 'Save Changes'
                                : 'Create Customer',
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
                  ? 'Customer updated successfully'
                  : 'Customer created successfully',
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
          Expanded(
            child: Text(
              'Open balance: ${customer.balance.toStringAsFixed(2)} ${customer.currency} • Credits: ${customer.creditBalance.toStringAsFixed(2)} ${customer.currency} • Status: ${customer.isActive ? 'Active' : 'Inactive'}',
            ),
          ),
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

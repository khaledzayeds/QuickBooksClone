// vendor_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/api/api_result.dart';
import '../../../core/navigation/safe_navigation.dart';
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
  bool _loadingVendor = false;
  VendorModel? _loadedVendor;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadVendor();
  }

  Future<void> _loadVendor() async {
    setState(() => _loadingVendor = true);
    final result = await ref
        .read(vendorsRepositoryProvider)
        .getVendor(widget.id!);
    if (!mounted) return;
    result.when(
      success: (vendor) {
        _nameCtrl.text = vendor.displayName;
        _companyCtrl.text = vendor.companyName ?? '';
        _emailCtrl.text = vendor.email ?? '';
        _phoneCtrl.text = vendor.phone ?? '';
        setState(() {
          _loadedVendor = vendor;
          _currency = vendor.currency;
          _loadingVendor = false;
        });
      },
      failure: (error) {
        setState(() => _loadingVendor = false);
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
        title: Text(widget.isEdit ? 'Edit Vendor' : 'New Vendor'),
        actions: [
          TextButton.icon(
            onPressed: _loading
                ? null
                : () => context.popOrGo(AppRoutes.vendors),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loadingVendor
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
                                  Icons.store_outlined,
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
                                          ? 'Edit vendor profile'
                                          : 'Create vendor profile',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Vendor records drive purchase orders, bills, inventory receiving, vendor credits, and vendor payments.',
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
                          if (_loadedVendor != null) ...[
                            const SizedBox(height: 16),
                            _VendorStatusBanner(vendor: _loadedVendor!),
                          ],
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final two = constraints.maxWidth >= 760;
                              final name = AppTextField(
                                label: 'Display Name *',
                                controller: _nameCtrl,
                                hint: 'Vendor display name',
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
                                hint: 'vendor@example.com',
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

                              if (!two)
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
                                  'If you already owe this vendor money, opening balance will create an opening payable posting automatically.',
                            ),
                          ],
                          const SizedBox(height: 32),
                          AppButton(
                            label: widget.isEdit
                                ? 'Save Changes'
                                : 'Create Vendor',
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

    final ApiResult<VendorModel> result = widget.isEdit
        ? await ref
              .read(vendorsProvider.notifier)
              .updateVendor(widget.id!, body)
        : await ref.read(vendorsProvider.notifier).createVendor(body);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit
                  ? 'Vendor updated successfully'
                  : 'Vendor created successfully',
            ),
          ),
        );
        context.popOrGo(AppRoutes.vendors);
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      ),
    );
  }
}

class _VendorStatusBanner extends StatelessWidget {
  const _VendorStatusBanner({required this.vendor});
  final VendorModel vendor;

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
            vendor.isActive ? Icons.check_circle_outline : Icons.block_outlined,
            color: vendor.isActive ? cs.primary : cs.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Open payable: ${vendor.balance.toStringAsFixed(2)} ${vendor.currency} • Vendor credits: ${vendor.creditBalance.toStringAsFixed(2)} ${vendor.currency} • Status: ${vendor.isActive ? 'Active' : 'Inactive'}',
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

// account_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/constants/api_enums.dart';
import '../../../core/navigation/safe_navigation.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/models/account_model.dart';
import '../providers/accounts_provider.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.id});
  final String? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  AccountType _selectedType = AccountType.expense;
  String? _parentId;
  bool _loading = false;
  bool _loadingAccount = false;
  AccountModel? _loadedAccount;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadAccount();
  }

  Future<void> _loadAccount() async {
    setState(() => _loadingAccount = true);
    final result = await ref
        .read(accountsRepositoryProvider)
        .getAccount(widget.id!);
    if (!mounted) return;
    result.when(
      success: (account) {
        _codeCtrl.text = account.code;
        _nameCtrl.text = account.name;
        _descCtrl.text = account.description ?? '';
        setState(() {
          _loadedAccount = account;
          _selectedType = account.accountType;
          _parentId = account.parentId;
          _loadingAccount = false;
        });
      },
      failure: (error) {
        setState(() => _loadingAccount = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      },
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Account' : 'New Account'),
        actions: [
          TextButton.icon(
            onPressed: _loading
                ? null
                : () => context.popOrGo(AppRoutes.chartOfAccounts),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loadingAccount
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
                                  Icons.account_tree_outlined,
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
                                          ? 'Edit chart account'
                                          : 'Create chart account',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Use stable account codes because transactions, posting, and reports depend on them.',
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
                          if (_loadedAccount != null) ...[
                            const SizedBox(height: 16),
                            _LoadedAccountBanner(account: _loadedAccount!),
                          ],
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final twoColumns = constraints.maxWidth >= 760;
                              final codeField = AppTextField(
                                label: 'Account Code *',
                                controller: _codeCtrl,
                                hint: 'Example: 1100',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final trimmed = value?.trim() ?? '';
                                  if (trimmed.isEmpty)
                                    return 'Account code is required';
                                  if (trimmed.length < 3)
                                    return 'Use a clear account code, e.g. 1000';
                                  return null;
                                },
                              );
                              final nameField = AppTextField(
                                label: 'Account Name *',
                                controller: _nameCtrl,
                                hint: 'Example: Accounts Receivable',
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Account name is required'
                                    : null,
                              );
                              final typeField =
                                  DropdownButtonFormField<AccountType>(
                                    initialValue: _selectedType,
                                    decoration: const InputDecoration(
                                      labelText: 'Account Type *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: AccountType.values.map((type) {
                                      final dummy = AccountModel(
                                        id: '',
                                        code: '',
                                        name: '',
                                        accountType: type,
                                        balance: 0,
                                        isActive: true,
                                      );
                                      return DropdownMenuItem<AccountType>(
                                        value: type,
                                        child: Text(dummy.accountTypeName),
                                      );
                                    }).toList(),
                                    onChanged: (value) =>
                                        setState(() => _selectedType = value!),
                                  );
                              final descField = AppTextField(
                                label: 'rescription',
                                controller: _descCtrl,
                                hint: 'Optional internal description',
                                maxLines: 3,
                              );

                              if (!twoColumns) {
                                return Column(
                                  children: [
                                    codeField,
                                    const SizedBox(height: 16),
                                    nameField,
                                    const SizedBox(height: 16),
                                    typeField,
                                    const SizedBox(height: 16),
                                    descField,
                                  ],
                                );
                              }

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: codeField),
                                      const SizedBox(width: 16),
                                      Expanded(child: nameField),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  typeField,
                                  const SizedBox(height: 16),
                                  descField,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _TypeHelp(accountType: _selectedType),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: widget.isEdit
                                      ? 'Save Changes'
                                      : 'Create Account',
                                  loading: _loading,
                                  expanded: true,
                                  onPressed: _submit,
                                ),
                              ),
                            ],
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

    final body = {
      'code': _codeCtrl.text.trim(),
      'name': _nameCtrl.text.trim(),
      'accountType': _selectedType.value,
      if (_descCtrl.text.trim().isNotEmpty)
        'description': _descCtrl.text.trim(),
      if (_parentId != null) 'parentId': _parentId,
    };

    final result = widget.isEdit
        ? await ref
              .read(accountsProvider.notifier)
              .updateAccount(widget.id!, body)
        : await ref.read(accountsProvider.notifier).createAccount(body);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit
                  ? 'Account updated successfully'
                  : 'Account created successfully',
            ),
          ),
        );
        context.popOrGo(AppRoutes.chartOfAccounts);
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      ),
    );
  }
}

class _LoadedAccountBanner extends StatelessWidget {
  const _LoadedAccountBanner({required this.account});
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            account.isActive
                ? Icons.check_circle_outline
                : Icons.block_outlined,
            color: account.isActive ? cs.primary : cs.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Current balance: ${account.balance.toStringAsFixed(2)} EGP • Status: ${account.isActive ? 'Active' : 'Inactive'}',
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeHelp extends StatelessWidget {
  const _TypeHelp({required this.accountType});
  final AccountType accountType;

  @override
  Widget build(BuildContext context) {
    final dummy = AccountModel(
      id: '',
      code: '',
      name: '',
      accountType: accountType,
      balance: 0,
      isActive: true,
    );
    final cs = Theme.of(context).colorScheme;
    final normalSide = dummy.isDebitNormal ? 'Debit-normal' : 'Credit-normal';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: cs.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${dummy.accountTypeName} is $normalSide. This controls how balances appear in reports and posting summaries.',
              style: TextStyle(color: cs.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

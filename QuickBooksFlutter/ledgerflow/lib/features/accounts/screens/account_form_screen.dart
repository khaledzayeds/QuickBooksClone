// account_form_screen.dart
// account_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_enums.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/models/account_model.dart';
import '../providers/accounts_provider.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.id});
  final String? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<AccountFormScreen> createState() =>
      _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _codeCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();

  AccountType _selectedType = AccountType.expense;
  String? _parentId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadAccount();
  }

  Future<void> _loadAccount() async {
    final result = await ref
        .read(accountsRepositoryProvider)
        .getAccount(widget.id!);
    result.when(
      success: (a) {
        _codeCtrl.text  = a.code;
        _nameCtrl.text  = a.name;
        _descCtrl.text  = a.description ?? '';
        setState(() {
          _selectedType = a.accountType;
          _parentId     = a.parentId;
        });
      },
      failure: (_) {},
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'تعديل حساب' : 'حساب جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Code ──────────────────────────────
            AppTextField(
              label: 'كود الحساب *',
              controller: _codeCtrl,
              hint: 'مثال: 1100',
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v == null || v.isEmpty ? 'كود الحساب مطلوب' : null,
            ),
            const SizedBox(height: 16),

            // ── Name ──────────────────────────────
            AppTextField(
              label: 'اسم الحساب *',
              controller: _nameCtrl,
              hint: 'مثال: النقدية',
              validator: (v) =>
                  v == null || v.isEmpty ? 'اسم الحساب مطلوب' : null,
            ),
            const SizedBox(height: 16),

            // ── Account Type ──────────────────────
            DropdownButtonFormField<AccountType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'نوع الحساب *'),
              items: AccountType.values.map((t) {
                final dummy = AccountModel(
                  id: '', code: '', name: '',
                  accountType: t, balance: 0, isActive: true,
                );
                return DropdownMenuItem(
                  value: t,
                  child: Text(dummy.accountTypeName),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),

            // ── Description ───────────────────────
            AppTextField(
              label: 'الوصف',
              controller: _descCtrl,
              hint: 'وصف اختياري',
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // ── Submit ────────────────────────────
            AppButton(
              label: widget.isEdit ? 'حفظ التعديلات' : 'إضافة الحساب',
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

    final body = {
      'code':        _codeCtrl.text.trim(),
      'name':        _nameCtrl.text.trim(),
      'accountType': _selectedType.value,
      if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text.trim(),
      if (_parentId != null) 'parentId': _parentId,
    };

    final result = widget.isEdit
        ? await ref
            .read(accountsProvider.notifier)
            .updateAccount(widget.id!, body)
        : await ref
            .read(accountsProvider.notifier)
            .createAccount(body);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit
                ? 'تم تعديل الحساب بنجاح'
                : 'تم إضافة الحساب بنجاح'),
          ),
        );
        context.pop();
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message), backgroundColor: Colors.red),
      ),
    );
  }
}
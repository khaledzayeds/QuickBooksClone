// write_check_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_enums.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../data/models/banking_models.dart';
import '../providers/banking_provider.dart';

class WriteCheckScreen extends ConsumerStatefulWidget {
  const WriteCheckScreen({super.key});

  @override
  ConsumerState<WriteCheckScreen> createState() => _WriteCheckScreenState();
}

class _WriteCheckScreenState extends ConsumerState<WriteCheckScreen> {
  String? bankId;
  String? expenseId;
  DateTime date = DateTime.now();
  final amount = TextEditingController();
  final payee = TextEditingController();
  final memo = TextEditingController();

  @override
  void dispose() {
    amount.dispose();
    payee.dispose();
    memo.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = double.tryParse(amount.text.trim()) ?? 0;
    if (bankId == null || bankId!.isEmpty) return error('Select bank account.');
    if (expenseId == null || expenseId!.isEmpty) return error('Select expense/offset account.');
    if (bankId == expenseId) return error('Accounts must be different.');
    if (value <= 0) return error('Enter a positive amount.');

    ref.read(bankCheckSavingProvider.notifier).state = true;
    final result = await ref.read(bankingActionsProvider).createCheck(
          CreateBankCheckDto(
            bankAccountId: bankId!,
            expenseAccountId: expenseId!,
            checkDate: date,
            amount: value,
            payee: payee.text,
            memo: memo.text,
          ),
        );
    ref.read(bankCheckSavingProvider.notifier).state = false;
    if (!mounted) return;
    result.when(
      success: (_) {
        ref.read(selectedBankAccountIdProvider.notifier).state = bankId;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check saved.')));
        if (context.canPop()) context.pop();
      },
      failure: (e) => error(e.message),
    );
  }

  void error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error));
  }

  @override
  Widget build(BuildContext context) {
    final banks = ref.watch(bankAccountsProvider);
    final accounts = ref.watch(accountsProvider);
    final saving = ref.watch(bankCheckSavingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Write Check / Spend Money')),
      body: banks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (bankList) => accounts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (accountList) {
            final activeBanks = bankList.where((a) => a.isActive).toList();
            final expenseAccounts = accountList
                .where((a) => a.isActive)
                .where((a) => a.accountType != AccountType.accountsReceivable && a.accountType != AccountType.accountsPayable)
                .toList();
            final safeBank = activeBanks.any((a) => a.id == bankId) ? bankId : null;
            final safeExpense = expenseAccounts.any((a) => a.id == expenseId) ? expenseId : null;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: safeBank,
                          decoration: const InputDecoration(labelText: 'Pay From', border: OutlineInputBorder()),
                          items: activeBanks.map((a) => DropdownMenuItem(value: a.id, child: Text(a.displayName))).toList(),
                          onChanged: (v) => setState(() => bankId = v),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: safeExpense,
                          decoration: const InputDecoration(labelText: 'Expense / Offset Account', border: OutlineInputBorder()),
                          items: expenseAccounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.code} - ${a.name}'))).toList(),
                          onChanged: (v) => setState(() => expenseId = v),
                        ),
                        const SizedBox(height: 16),
                        _DateField(label: 'Check Date', value: date, onChanged: (v) => setState(() => date = v)),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Amount',
                          controller: amount,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(label: 'Payee', controller: payee),
                        const SizedBox(height: 16),
                        AppTextField(label: 'Memo', controller: memo, maxLines: 3),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _Actions(saving: saving, label: 'Save Check', onSave: save),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onChanged});
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2020), lastDate: DateTime(2030));
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          child: Text('${value.day}/${value.month}/${value.year}'),
        ),
      );
}

class _Actions extends StatelessWidget {
  const _Actions({required this.saving, required this.label, required this.onSave});
  final bool saving;
  final String label;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(onPressed: saving ? null : () => context.canPop() ? context.pop() : null, child: const Text('Cancel')),
            const SizedBox(width: 12),
            FilledButton(onPressed: saving ? null : onSave, child: Text(label)),
          ],
        ),
      );
}

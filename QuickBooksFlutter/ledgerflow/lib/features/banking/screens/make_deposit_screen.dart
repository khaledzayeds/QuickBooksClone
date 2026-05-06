// make_deposit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_enums.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../data/models/banking_models.dart';
import '../providers/banking_provider.dart';

class MakeDepositScreen extends ConsumerStatefulWidget {
  const MakeDepositScreen({super.key});

  @override
  ConsumerState<MakeDepositScreen> createState() => _MakeDepositScreenState();
}

class _MakeDepositScreenState extends ConsumerState<MakeDepositScreen> {
  String? bankId;
  String? offsetId;
  DateTime date = DateTime.now();
  final amount = TextEditingController();
  final receivedFrom = TextEditingController();
  final memo = TextEditingController();

  @override
  void dispose() {
    amount.dispose();
    receivedFrom.dispose();
    memo.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = double.tryParse(amount.text.trim()) ?? 0;
    if (bankId == null || bankId!.isEmpty) return error('Select deposit account.');
    if (offsetId == null || offsetId!.isEmpty) return error('Select offset account.');
    if (bankId == offsetId) return error('Accounts must be different.');
    if (value <= 0) return error('Enter a positive amount.');

    ref.read(bankDepositSavingProvider.notifier).state = true;
    final result = await ref.read(bankingActionsProvider).createDeposit(
          CreateBankDepositDto(
            depositAccountId: bankId!,
            offsetAccountId: offsetId!,
            depositDate: date,
            amount: value,
            receivedFrom: receivedFrom.text,
            memo: memo.text,
          ),
        );
    ref.read(bankDepositSavingProvider.notifier).state = false;
    if (!mounted) return;
    result.when(
      success: (_) {
        ref.read(selectedBankAccountIdProvider.notifier).state = bankId;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deposit saved.')));
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
    final saving = ref.watch(bankDepositSavingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Make Deposit')),
      body: banks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (bankList) => accounts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (accountList) {
            final activeBanks = bankList.where((a) => a.isActive).toList();
            final offsets = accountList
                .where((a) => a.isActive)
                .where((a) => a.accountType != AccountType.accountsReceivable && a.accountType != AccountType.accountsPayable)
                .toList();
            final safeBank = activeBanks.any((a) => a.id == bankId) ? bankId : null;
            final safeOffset = offsets.any((a) => a.id == offsetId) ? offsetId : null;

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
                          decoration: const InputDecoration(labelText: 'Deposit To', border: OutlineInputBorder()),
                          items: activeBanks.map((a) => DropdownMenuItem(value: a.id, child: Text(a.displayName))).toList(),
                          onChanged: (v) => setState(() => bankId = v),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: safeOffset,
                          decoration: const InputDecoration(labelText: 'From / Offset Account', border: OutlineInputBorder()),
                          items: offsets.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.code} - ${a.name}'))).toList(),
                          onChanged: (v) => setState(() => offsetId = v),
                        ),
                        const SizedBox(height: 16),
                        _DateField(label: 'Deposit Date', value: date, onChanged: (v) => setState(() => date = v)),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Amount',
                          controller: amount,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(label: 'Received From', controller: receivedFrom),
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
      bottomNavigationBar: _Actions(saving: saving, label: 'Save Deposit', onSave: save),
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

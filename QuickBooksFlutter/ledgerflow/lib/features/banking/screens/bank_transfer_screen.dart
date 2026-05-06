// bank_transfer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_text_field.dart';
import '../data/models/banking_models.dart';
import '../providers/banking_provider.dart';

class BankTransferScreen extends ConsumerStatefulWidget {
  const BankTransferScreen({super.key});

  @override
  ConsumerState<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends ConsumerState<BankTransferScreen> {
  String? _fromAccountId;
  String? _toAccountId;
  DateTime _transferDate = DateTime.now();
  final _amountCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    if (_fromAccountId == null || _fromAccountId!.isEmpty) {
      _error('Select the account to transfer from.');
      return;
    }
    if (_toAccountId == null || _toAccountId!.isEmpty) {
      _error('Select the account to transfer to.');
      return;
    }
    if (_fromAccountId == _toAccountId) {
      _error('Transfer accounts must be different.');
      return;
    }
    if (amount <= 0) {
      _error('Enter a positive transfer amount.');
      return;
    }

    ref.read(bankTransferSavingProvider.notifier).state = true;
    final result = await ref.read(bankingActionsProvider).createTransfer(
          CreateBankTransferDto(
            fromAccountId: _fromAccountId!,
            toAccountId: _toAccountId!,
            transferDate: _transferDate,
            amount: amount,
            memo: _memoCtrl.text,
          ),
        );
    ref.read(bankTransferSavingProvider.notifier).state = false;

    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank transfer saved.')));
        ref.read(selectedBankAccountIdProvider.notifier).state = _fromAccountId;
        if (context.canPop()) {
          context.pop();
        }
      },
      failure: (error) => _error(error.message),
    );
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error));
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(bankAccountsProvider);
    final saving = ref.watch(bankTransferSavingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Transfer'),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: saving ? null : _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (accounts) {
          final activeAccounts = accounts.where((account) => account.isActive).toList();
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Transfer Funds', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _AccountDropdown(
                              label: 'Transfer From',
                              value: _fromAccountId,
                              accounts: activeAccounts,
                              onChanged: (value) => setState(() => _fromAccountId = value),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _AccountDropdown(
                              label: 'Transfer To',
                              value: _toAccountId,
                              accounts: activeAccounts,
                              onChanged: (value) => setState(() => _toAccountId = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerField(
                              value: _transferDate,
                              onChanged: (date) => setState(() => _transferDate = date),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              label: 'Amount',
                              controller: _amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Memo',
                        controller: _memoCtrl,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: saving ? null : () => context.canPop() ? context.pop() : null,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.swap_horiz),
              label: const Text('Save Transfer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.label,
    required this.value,
    required this.accounts,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<BankAccountModel> accounts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = accounts.any((account) => account.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.account_balance_outlined),
      ),
      items: accounts
          .map(
            (account) => DropdownMenuItem<String>(
              value: account.id,
              child: Text('${account.displayName} — ${account.balance.toStringAsFixed(2)}'),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Transfer Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text('${value.day}/${value.month}/${value.year}'),
      ),
    );
  }
}

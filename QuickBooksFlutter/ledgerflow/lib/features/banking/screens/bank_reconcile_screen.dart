// bank_reconcile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_text_field.dart';
import '../data/models/banking_models.dart';
import '../providers/banking_provider.dart';

class BankReconcileScreen extends ConsumerStatefulWidget {
  const BankReconcileScreen({super.key});

  @override
  ConsumerState<BankReconcileScreen> createState() =>
      _BankReconcileScreenState();
}

class _BankReconcileScreenState extends ConsumerState<BankReconcileScreen> {
  String? accountId;
  DateTime statementDate = DateTime.now();
  final endingBalance = TextEditingController();

  @override
  void dispose() {
    endingBalance.dispose();
    super.dispose();
  }

  Future<void> preview() async {
    final value = double.tryParse(endingBalance.text.trim()) ?? 0;
    if (accountId == null || accountId!.isEmpty)
      return error('Select bank account.');

    ref.read(bankReconcilePreviewSavingProvider.notifier).state = true;
    final result = await ref
        .read(bankingActionsProvider)
        .previewReconcile(
          BankReconcilePreviewDto(
            accountId: accountId!,
            statementDate: statementDate,
            statementEndingBalance: value,
          ),
        );
    ref.read(bankReconcilePreviewSavingProvider.notifier).state = false;

    if (!mounted) return;
    result.when(success: (_) {}, failure: (e) => error(e.message));
  }

  void error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(bankAccountsProvider);
    final saving = ref.watch(bankReconcilePreviewSavingProvider);
    final previewModel = ref.watch(bankReconcilePreviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reconcile')),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (accounts) {
          final activeAccounts = accounts.where((a) => a.isActive).toList();
          final safeAccount = activeAccounts.any((a) => a.id == accountId)
              ? accountId
              : null;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Statement Preview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: safeAccount,
                        decoration: const InputDecoration(
                          labelText: 'Bank Account',
                          border: OutlineInputBorder(),
                        ),
                        items: activeAccounts
                            .map<DropdownMenuItem<String>>(
                              (
                                BankAccountModel account,
                              ) => DropdownMenuItem<String>(
                                value: account.id,
                                child: Text(
                                  '${account.displayName} — ${account.balance.toStringAsFixed(2)}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => accountId = v),
                      ),
                      const SizedBox(height: 16),
                      _DateField(
                        label: 'Statement Date',
                        value: statementDate,
                        onChanged: (v) => setState(() => statementDate = v),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Statement Ending Balance',
                        controller: endingBalance,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: saving ? null : preview,
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.fact_check_outlined),
                        label: const Text('Preview Reconciliation'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (previewModel != null) _PreviewCard(preview: previewModel),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});
  final BankReconcilePreviewModel preview;

  @override
  Widget build(BuildContext context) {
    final color = preview.isBalanced
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    preview.accountName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Chip(
                  label: Text(preview.isBalanced ? 'Balanced' : 'Difference'),
                  backgroundColor: color.withValues(alpha: 0.14),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _AmountRow(label: 'Book Balance', amount: preview.bookBalance),
            _AmountRow(
              label: 'Statement Ending Balance',
              amount: preview.statementEndingBalance,
            ),
            _AmountRow(
              label: 'Difference',
              amount: preview.difference,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              'Lines included through statement date: ${preview.registerLines.length}',
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.amount, this.color});
  final String label;
  final double amount;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          amount.toStringAsFixed(2),
          style: TextStyle(fontWeight: FontWeight.w900, color: color),
        ),
      ],
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Text('${value.day}/${value.month}/${value.year}'),
    ),
  );
}

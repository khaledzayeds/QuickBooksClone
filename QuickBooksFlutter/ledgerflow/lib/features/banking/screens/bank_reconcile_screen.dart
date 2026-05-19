// bank_reconcile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
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
    if (accountId == null || accountId!.isEmpty) {
      return error('Select bank account.');
    }

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

    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (accounts) {
        final activeAccounts = accounts.where((a) => a.isActive).toList();
        final safeAccount = activeAccounts.any((a) => a.id == accountId)
            ? accountId
            : null;
        final selected = activeAccounts
            .where((account) => account.id == safeAccount)
            .firstOrNull;
        return TransactionWorkspaceShell(
          workspaceName: 'Reconcile workspace',
          saving: saving,
          posting: false,
          isEdit: false,
          readOnly: false,
          showPagination: false,
          showSaveDraft: false,
          showSaveAndPrint: false,
          showPrint: true,
          showEmail: false,
          showEditNotes: false,
          showVoid: false,
          onFind: () => context.go(AppRoutes.bankingRegister),
          onNew: _clear,
          onSave: saving ? null : preview,
          onClear: _clear,
          onClose: () => context.go(AppRoutes.bankingRegister),
          contextPanel: _ReconcileSidePanel(
            account: selected,
            preview: previewModel,
          ),
          formContent: Column(
            children: [
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF264D5B),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF183642)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const _StripLabel('BANK ACCOUNT'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CompactBankDropdown(
                              value: safeAccount,
                              accounts: activeAccounts,
                              onChanged: (v) => setState(() => accountId = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 150,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 300,
                              child: Text(
                                'Reconcile',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w300,
                                      color: const Color(0xFF243E4A),
                                    ),
                              ),
                            ),
                            SizedBox(
                              width: 300,
                              child: Column(
                                children: [
                                  _DateField(
                                    label: 'Statement Date',
                                    value: statementDate,
                                    onChanged: (v) =>
                                        setState(() => statementDate = v),
                                  ),
                                  const SizedBox(height: 8),
                                  AppTextField(
                                    label: 'Statement Ending Balance',
                                    controller: endingBalance,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[-0-9.]'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: previewModel == null
                      ? const Center(
                          child: Text(
                            'Preview reconciliation to compare book and statement balances.',
                            style: TextStyle(
                              color: Color(0xFF60747D),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : _PreviewCard(preview: previewModel),
                ),
              ),
              Container(
                height: 88,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F8F9),
                  border: Border(top: BorderSide(color: Color(0xFFB7C3CB))),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Preview checks the statement balance against the current register book balance.',
                        style: TextStyle(
                          color: Color(0xFF53656E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: saving ? null : preview,
                      style: _smallButton(),
                      child: Text(saving ? 'Previewing...' : 'Preview'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: _clear,
                      style: _smallButton(),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clear() {
    setState(() {
      accountId = null;
      statementDate = DateTime.now();
      endingBalance.clear();
    });
    ref.read(bankReconcilePreviewProvider.notifier).state = null;
  }

  ButtonStyle _smallButton() => OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    side: const BorderSide(color: Color(0xFF8FA1AB)),
  );
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

class _ReconcileSidePanel extends StatelessWidget {
  const _ReconcileSidePanel({required this.account, required this.preview});
  final BankAccountModel? account;
  final BankReconcilePreviewModel? preview;

  @override
  Widget build(BuildContext context) {
    if (account == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'Select a bank account to preview reconciliation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF2D4854),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          decoration: const BoxDecoration(
            color: Color(0xFF264D5B),
            border: Border(bottom: BorderSide(color: Color(0xFF183642))),
          ),
          child: Text(
            account!.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _SideBlock(
          title: 'Register',
          rows: [
            _InfoPair('Current balance', account!.balance.toStringAsFixed(2)),
            _InfoPair(
              'Difference',
              preview == null ? '-' : preview!.difference.toStringAsFixed(2),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactBankDropdown extends StatelessWidget {
  const _CompactBankDropdown({
    required this.value,
    required this.accounts,
    required this.onChanged,
  });

  final String? value;
  final List<BankAccountModel> accounts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = accounts.any((account) => account.id == value)
        ? value
        : null;
    return SizedBox(
      height: 30,
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(),
        ),
        hint: const Text('Select bank'),
        items: accounts
            .map(
              (account) => DropdownMenuItem<String>(
                value: account.id,
                child: Text(account.displayName),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _StripLabel extends StatelessWidget {
  const _StripLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _InfoPair {
  const _InfoPair(this.label, this.value);
  final String label;
  final String value;
}

class _SideBlock extends StatelessWidget {
  const _SideBlock({required this.title, required this.rows});
  final String title;
  final List<_InfoPair> rows;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFB8C6CE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF2D4854),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(row.label, overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
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

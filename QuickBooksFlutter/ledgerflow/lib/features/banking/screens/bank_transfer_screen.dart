// bank_transfer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/qb/qb_widgets.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
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
    final result = await ref
        .read(bankingActionsProvider)
        .createTransfer(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bank transfer saved.')));
        ref.read(selectedBankAccountIdProvider.notifier).state = _fromAccountId;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.bankingRegister);
        }
      },
      failure: (error) => _error(error.message),
    );
  }

  void _error(String message) {
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
    final saving = ref.watch(bankTransferSavingProvider);

    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (accounts) {
        final activeAccounts = accounts
            .where((account) => account.isActive)
            .toList();
        final fromAccount = activeAccounts
            .where((account) => account.id == _fromAccountId)
            .firstOrNull;
        final toAccount = activeAccounts
            .where((account) => account.id == _toAccountId)
            .firstOrNull;
        final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

        return TransactionWorkspaceShell(
          workspaceName: 'Bank transfer workspace',
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
          onSave: saving ? null : _save,
          onClear: _clear,
          onClose: () => context.go(AppRoutes.bankingRegister),
          formContent: _TransferWorkspace(
            accounts: activeAccounts,
            fromAccountId: _fromAccountId,
            toAccountId: _toAccountId,
            transferDate: _transferDate,
            amountCtrl: _amountCtrl,
            memoCtrl: _memoCtrl,
            onFromChanged: (value) => setState(() => _fromAccountId = value),
            onToChanged: (value) => setState(() => _toAccountId = value),
            onDateChanged: (date) => setState(() => _transferDate = date),
            onChanged: () => setState(() {}),
            onSave: saving ? null : _save,
            onClear: _clear,
            saving: saving,
          ),
          contextPanel: _TransferContextPanel(
            fromAccount: fromAccount,
            toAccount: toAccount,
            amount: amount,
            memo: _memoCtrl.text,
          ),
        );
      },
    );
  }

  void _clear() {
    setState(() {
      _fromAccountId = null;
      _toAccountId = null;
      _transferDate = DateTime.now();
      _amountCtrl.clear();
      _memoCtrl.clear();
    });
  }
}

class _TransferWorkspace extends StatelessWidget {
  const _TransferWorkspace({
    required this.accounts,
    required this.fromAccountId,
    required this.toAccountId,
    required this.transferDate,
    required this.amountCtrl,
    required this.memoCtrl,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onDateChanged,
    required this.onChanged,
    required this.onClear,
    required this.saving,
    this.onSave,
  });

  final List<BankAccountModel> accounts;
  final String? fromAccountId;
  final String? toAccountId;
  final DateTime transferDate;
  final TextEditingController amountCtrl;
  final TextEditingController memoCtrl;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onChanged;
  final VoidCallback onClear;
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  border: Border(bottom: BorderSide(color: Color(0xFF183642))),
                ),
                child: Row(
                  children: [
                    const QbStripLabel('TRANSFER FROM'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CompactAccountDropdown(
                        value: fromAccountId,
                        accounts: accounts,
                        onChanged: onFromChanged,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const QbStripLabel('TRANSFER TO'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CompactAccountDropdown(
                        value: toAccountId,
                        accounts: accounts,
                        onChanged: onToChanged,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 175,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 320,
                        child: Text(
                          'Transfer Funds',
                          style: Theme.of(context).textTheme.headlineMedium
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
                            QbStackedField(
                              label: 'TRANSFER DATE',
                              child: QbDateBox(
                                text:
                                    '${transferDate.day}/${transferDate.month}/${transferDate.year}',
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: transferDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) onDateChanged(picked);
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppTextField(
                              label: 'Amount',
                              controller: amountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              onChanged: (_) => onChanged(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: AppTextField(
                          label: 'Memo',
                          controller: memoCtrl,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Transfer moves cash between two active bank accounts.',
              style: TextStyle(
                color: Color(0xFF60747D),
                fontWeight: FontWeight.w700,
              ),
            ),
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
                  'Save posts a withdrawal from the source bank and a deposit to the destination bank.',
                  style: TextStyle(
                    color: Color(0xFF53656E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: onSave,
                style: _smallButton(),
                child: Text(saving ? 'Saving...' : 'Save & Close'),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: onClear,
                style: _smallButton(),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ButtonStyle _smallButton() => OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    side: const BorderSide(color: Color(0xFF8FA1AB)),
  );
}

class _TransferContextPanel extends StatelessWidget {
  const _TransferContextPanel({
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.memo,
  });

  final BankAccountModel? fromAccount;
  final BankAccountModel? toAccount;
  final double amount;
  final String memo;

  @override
  Widget build(BuildContext context) {
    if (fromAccount == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'Select transfer accounts to preview the bank movement.',
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
          decoration: const BoxDecoration(color: Color(0xFF264D5B)),
          child: const Text(
            'Bank Transfer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ),
        QbSideSection(
          title: 'Transfer Preview',
          child: Column(
            children: [
              QbInfoRow(label: 'From', value: fromAccount!.name),
              QbInfoRow(label: 'To', value: toAccount?.name ?? '-'),
              QbInfoRow(label: 'Amount', value: amount.toStringAsFixed(2)),
            ],
          ),
        ),
        Expanded(
          child: QbSideSection(
            title: 'Memo',
            child: Text(
              memo.trim().isEmpty ? 'No memo added.' : memo,
              style: const TextStyle(color: Color(0xFF4E616A)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactAccountDropdown extends StatelessWidget {
  const _CompactAccountDropdown({
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

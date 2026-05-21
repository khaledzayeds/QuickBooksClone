// write_check_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../core/constants/api_enums.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../../core/widgets/qb/qb_widgets.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
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
  final _moneyFmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  double get _amountValue => double.tryParse(amount.text.trim()) ?? 0;

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
    if (expenseId == null || expenseId!.isEmpty) {
      return error('Select expense/offset account.');
    }
    if (bankId == expenseId) return error('Accounts must be different.');
    if (value <= 0) return error('Enter a positive amount.');

    ref.read(bankCheckSavingProvider.notifier).state = true;
    final result = await ref
        .read(bankingActionsProvider)
        .createCheck(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Check saved.')));
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.bankingRegister);
        }
      },
      failure: (e) => error(e.message),
    );
  }

  void error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _clear() {
    setState(() {
      bankId = null;
      expenseId = null;
      date = DateTime.now();
      amount.clear();
      payee.clear();
      memo.clear();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) setState(() => date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final banks = ref.watch(bankAccountsProvider);
    final accounts = ref.watch(accountsProvider);
    final saving = ref.watch(bankCheckSavingProvider);

    return banks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (bankList) => accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (accountList) {
          final activeBanks = bankList.where((a) => a.isActive).toList();
          final expenseAccounts = accountList
              .where((a) => a.isActive)
              .where(
                (a) =>
                    a.accountType != AccountType.accountsReceivable &&
                    a.accountType != AccountType.accountsPayable,
              )
              .toList();
          final safeBank = activeBanks.any((a) => a.id == bankId)
              ? bankId
              : null;
          final safeExpense = expenseAccounts.any((a) => a.id == expenseId)
              ? expenseId
              : null;

          final selectedBank = activeBanks
              .where((account) => account.id == safeBank)
              .firstOrNull;
          final selectedExpense = expenseAccounts
              .where((account) => account.id == safeExpense)
              .firstOrNull;

          return TransactionWorkspaceShell(
            workspaceName: 'Write check workspace',
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
            onSave: saving ? null : save,
            onClear: _clear,
            onClose: () => context.go(AppRoutes.bankingRegister),
            formContent: Column(
              children: [
                _CheckHeader(
                  banks: activeBanks,
                  accounts: expenseAccounts,
                  bankId: safeBank,
                  expenseId: safeExpense,
                  date: date,
                  dateText: _dateFmt.format(date),
                  amount: _amountValue,
                  money: _moneyFmt.format,
                  onBankChanged: (value) => setState(() => bankId = value),
                  onExpenseChanged: (value) =>
                      setState(() => expenseId = value),
                  onPickDate: _pickDate,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _CheckEntryPanel(
                      amountCtrl: amount,
                      payeeCtrl: payee,
                      memoCtrl: memo,
                      bankName:
                          selectedBank?.displayName ?? 'Select pay account',
                      expenseName:
                          selectedExpense?.name ?? 'Select expense account',
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ),
                _CheckFooter(
                  amount: _amountValue,
                  money: _moneyFmt.format,
                  saving: saving,
                  onClear: _clear,
                  onSave: saving ? null : save,
                ),
              ],
            ),
            contextPanel: _CheckContextPanel(
              bank: selectedBank,
              expense: selectedExpense,
              amount: _amountValue,
              payee: payee.text,
              memo: memo.text,
              money: _moneyFmt.format,
            ),
          );
        },
      ),
    );
  }
}

class _CheckHeader extends StatelessWidget {
  const _CheckHeader({
    required this.banks,
    required this.accounts,
    required this.bankId,
    required this.expenseId,
    required this.date,
    required this.dateText,
    required this.amount,
    required this.money,
    required this.onBankChanged,
    required this.onExpenseChanged,
    required this.onPickDate,
  });

  final List<BankAccountModel> banks;
  final List<AccountModel> accounts;
  final String? bankId;
  final String? expenseId;
  final DateTime date;
  final String dateText;
  final double amount;
  final String Function(double value) money;
  final ValueChanged<String?> onBankChanged;
  final ValueChanged<String?> onExpenseChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final bank = banks.where((account) => account.id == bankId).firstOrNull;

    return Container(
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
                const QbStripLabel('PAY FROM'),
                const SizedBox(width: 8),
                Expanded(
                  child: _BankDropdown(
                    value: bankId,
                    banks: banks,
                    onChanged: onBankChanged,
                  ),
                ),
                const SizedBox(width: 16),
                const QbStripLabel('EXPENSE / OFFSET ACCOUNT'),
                const SizedBox(width: 8),
                Expanded(
                  child: _AccountDropdown(
                    value: expenseId,
                    accounts: accounts,
                    onChanged: onExpenseChanged,
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
                    width: 330,
                    child: Text(
                      'Write Check / Spend Money',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF243E4A),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: Column(
                      children: [
                        QbHorizontalField(
                          label: 'CHECK DATE',
                          labelWidth: 94,
                          child: QbDateBox(
                            text: dateText,
                            enabled: true,
                            onTap: onPickDate,
                          ),
                        ),
                        const SizedBox(height: 6),
                        QbHorizontalField(
                          label: 'CHECK #',
                          labelWidth: 94,
                          child: const QbStaticBox(text: 'AUTO'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _StatBox(
                          label: 'CURRENT BANK BALANCE',
                          value: bank == null ? '-' : money(bank.balance),
                          accent: false,
                        ),
                        const SizedBox(height: 6),
                        _StatBox(
                          label: 'THIS CHECK',
                          value: money(amount),
                          accent: true,
                        ),
                        const SizedBox(height: 6),
                        _StatBox(
                          label: 'AFTER CHECK',
                          value: bank == null
                              ? '-'
                              : money(bank.balance - amount),
                          accent: false,
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
    );
  }
}

class _CheckEntryPanel extends StatelessWidget {
  const _CheckEntryPanel({
    required this.amountCtrl,
    required this.payeeCtrl,
    required this.memoCtrl,
    required this.bankName,
    required this.expenseName,
    required this.onChanged,
  });

  final TextEditingController amountCtrl;
  final TextEditingController payeeCtrl;
  final TextEditingController memoCtrl;
  final String bankName;
  final String expenseName;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF9EADB6)),
      ),
      child: Column(
        children: [
          Container(
            height: 30,
            color: const Color(0xFFDDE8ED),
            child: const Row(
              children: [
                _HeaderCell('PAYEE', flex: 3),
                _HeaderCell('EXPENSE ACCOUNT', flex: 3),
                _HeaderCell('PAY FROM', flex: 3),
                _HeaderCell('MEMO', flex: 4),
                _HeaderCell('AMOUNT', flex: 2, right: true),
              ],
            ),
          ),
          Container(
            height: 42,
            color: const Color(0xFFDDEFF4),
            child: Row(
              children: [
                _InputCell(
                  controller: payeeCtrl,
                  flex: 3,
                  onChanged: onChanged,
                ),
                _ReadCell(expenseName, flex: 3),
                _ReadCell(bankName, flex: 3),
                _InputCell(controller: memoCtrl, flex: 4, onChanged: onChanged),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    child: TextField(
                      controller: amountCtrl,
                      textAlign: TextAlign.end,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 7,
                        ),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'One-line check entry. Save posts a bank credit and expense debit.',
                style: TextStyle(
                  color: Color(0xFF60747D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckFooter extends StatelessWidget {
  const _CheckFooter({
    required this.amount,
    required this.money,
    required this.saving,
    required this.onClear,
    this.onSave,
  });

  final double amount;
  final String Function(double value) money;
  final bool saving;
  final VoidCallback onClear;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              'Check credits the selected bank account and debits the selected expense account.',
              style: TextStyle(
                color: Color(0xFF53656E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 330,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F1F4),
                border: Border.all(color: const Color(0xFF9DB2BC)),
              ),
              child: _AmountRow(label: 'CHECK TOTAL', value: money(amount)),
            ),
          ),
          const SizedBox(width: 16),
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
    );
  }

  ButtonStyle _smallButton() => OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    side: const BorderSide(color: Color(0xFF8FA1AB)),
  );
}

class _CheckContextPanel extends StatelessWidget {
  const _CheckContextPanel({
    required this.bank,
    required this.expense,
    required this.amount,
    required this.payee,
    required this.memo,
    required this.money,
  });

  final BankAccountModel? bank;
  final AccountModel? expense;
  final double amount;
  final String payee;
  final String memo;
  final String Function(double value) money;

  @override
  Widget build(BuildContext context) {
    if (bank == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_outlined,
                size: 38,
                color: Color(0xFF8CA0AA),
              ),
              SizedBox(height: 12),
              Text(
                'Select pay from account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2D4854),
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Choose a bank account to preview the check effect.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF667A84), height: 1.35),
              ),
            ],
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bank!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Write check',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFD7E6EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
          color: const Color(0xFFFFE7C4),
          child: Text(
            amount <= 0
                ? 'Enter amount before saving.'
                : 'Check is ready to post.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF714600),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        QbSideSection(
          title: 'Bank Effect',
          child: Column(
            children: [
              QbInfoRow(label: 'Current balance', value: money(bank!.balance)),
              QbInfoRow(label: 'Check amount', value: money(amount)),
              const Divider(height: 14),
              QbInfoRow(
                label: 'After check',
                value: money(bank!.balance - amount),
                strong: true,
              ),
            ],
          ),
        ),
        QbSideSection(
          title: 'Entry Preview',
          child: Column(
            children: [
              QbInfoRow(label: 'Credit', value: bank!.name),
              QbInfoRow(label: 'Debit', value: expense?.name ?? '-'),
              QbInfoRow(
                label: 'Payee',
                value: payee.trim().isEmpty ? '-' : payee.trim(),
              ),
            ],
          ),
        ),
        Expanded(
          child: QbSideSection(
            title: 'Memo',
            child: Text(
              memo.trim().isEmpty ? 'No memo added.' : memo.trim(),
              style: const TextStyle(color: Color(0xFF4E616A)),
            ),
          ),
        ),
      ],
    );
  }
}

class _BankDropdown extends StatelessWidget {
  const _BankDropdown({
    required this.value,
    required this.banks,
    required this.onChanged,
  });

  final String? value;
  final List<BankAccountModel> banks;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(),
        ),
        hint: const Text('Select bank'),
        items: banks
            .map(
              (account) => DropdownMenuItem(
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

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.value,
    required this.accounts,
    required this.onChanged,
  });

  final String? value;
  final List<AccountModel> accounts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(),
        ),
        hint: const Text('Select account'),
        items: accounts
            .map(
              (account) => DropdownMenuItem(
                value: account.id,
                child: Text('${account.code}  ${account.name}'),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex, this.right = false});
  final String text;
  final int flex;
  final bool right;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        text,
        textAlign: right ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF53656E),
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _ReadCell extends StatelessWidget {
  const _ReadCell(this.text, {required this.flex});
  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Container(
      height: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFB8C6CE))),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF273F4B),
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _InputCell extends StatelessWidget {
  const _InputCell({
    required this.controller,
    required this.flex,
    required this.onChanged,
  });
  final TextEditingController controller;
  final int flex;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        ),
        onChanged: (_) => onChanged(),
      ),
    ),
  );
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFE7F1F4) : Colors.white,
        border: Border.all(
          color: accent ? const Color(0xFF8EABB7) : const Color(0xFFB7C3CB),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: QbFieldLabel(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF213D49),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
      ),
    ],
  );
}

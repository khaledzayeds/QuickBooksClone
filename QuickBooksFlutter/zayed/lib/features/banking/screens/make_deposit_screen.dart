// make_deposit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../core/constants/api_enums.dart';
import '../../../core/widgets/qb/qb_widgets.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../printing/data/models/print_data_contracts.dart';
import '../../printing/widgets/document_print_preview_dialog.dart';
import '../data/models/banking_models.dart';
import '../providers/banking_provider.dart';

class MakeDepositScreen extends ConsumerStatefulWidget {
  const MakeDepositScreen({super.key});

  @override
  ConsumerState<MakeDepositScreen> createState() => _MakeDepositScreenState();
}

class _MakeDepositScreenState extends ConsumerState<MakeDepositScreen> {
  String? _bankId;
  String? _offsetId;
  DateTime _depositDate = DateTime.now();
  final _amountCtrl = TextEditingController();
  final _receivedFromCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final _moneyFmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('dd/MM/yyyy');
  List<BankAccountModel> _printBanks = const [];
  List<AccountModel> _printOffsets = const [];

  double get _amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _receivedFromCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _depositDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) setState(() => _depositDate = picked);
  }

  void _clear() {
    setState(() {
      _bankId = null;
      _offsetId = null;
      _depositDate = DateTime.now();
      _amountCtrl.clear();
      _receivedFromCtrl.clear();
      _memoCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (_bankId == null || _bankId!.isEmpty) {
      _showError('Select deposit account.');
      return;
    }
    if (_offsetId == null || _offsetId!.isEmpty) {
      _showError('Select from account.');
      return;
    }
    if (_bankId == _offsetId) {
      _showError('Deposit and from account must be different.');
      return;
    }
    if (_amount <= 0) {
      _showError('Enter a positive amount.');
      return;
    }

    ref.read(bankDepositSavingProvider.notifier).state = true;
    final result = await ref
        .read(bankingActionsProvider)
        .createDeposit(
          CreateBankDepositDto(
            depositAccountId: _bankId!,
            offsetAccountId: _offsetId!,
            depositDate: _depositDate,
            amount: _amount,
            receivedFrom: _receivedFromCtrl.text,
            memo: _memoCtrl.text,
          ),
        );
    ref.read(bankDepositSavingProvider.notifier).state = false;
    if (!mounted) return;

    result.when(
      success: (_) {
        ref.read(selectedBankAccountIdProvider.notifier).state = _bankId;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Deposit saved.')));
        context.go(AppRoutes.bankingRegister);
      },
      failure: (error) => _showError(error.message),
    );
  }

  Future<void> _printDraft(
    List<BankAccountModel> banks,
    List<AccountModel> offsets,
  ) async {
    if (_bankId == null || _offsetId == null || _amount <= 0) {
      _showError('Complete deposit details before printing.');
      return;
    }
    final bank = banks.where((item) => item.id == _bankId).firstOrNull;
    final offset = offsets.where((item) => item.id == _offsetId).firstOrNull;
    final data = DocumentPrintDataModel(
      documentId: 'draft-deposit',
      documentType: 'deposit',
      documentNumber: 'AUTO',
      status: 'Draft',
      company: const PrintCompanyModel(
        companyName: 'Zayed',
        currency: 'EGP',
        country: 'Egypt',
      ),
      customer: PrintCustomerModel(
        customerId: _offsetId ?? '',
        displayName: _receivedFromCtrl.text.trim().isEmpty
            ? offset?.name ?? 'From Account'
            : _receivedFromCtrl.text.trim(),
        currency: 'EGP',
        openBalance: 0,
        creditBalance: 0,
      ),
      partyLabel: 'Account',
      partyType: 'Account',
      payment: PrintPaymentModel(
        depositAccountId: _bankId,
        depositAccountName: bank?.displayName,
        paymentMethod: 'Deposit',
      ),
      documentDate: _depositDate,
      dueDate: _depositDate,
      subtotal: _amount,
      discountAmount: 0,
      taxAmount: 0,
      totalAmount: _amount,
      paidAmount: _amount,
      creditAppliedAmount: 0,
      returnedAmount: 0,
      balanceDue: 0,
      lines: [
        PrintLineModel(
          lineNumber: 1,
          itemId: _offsetId ?? '',
          itemName: offset?.name ?? 'Deposit line',
          description: _memoCtrl.text.trim().isEmpty
              ? 'Bank deposit'
              : _memoCtrl.text.trim(),
          quantity: 1,
          unitPrice: _amount,
          discountPercent: 0,
          taxRatePercent: 0,
          taxAmount: 0,
          lineTotal: _amount,
        ),
      ],
      summaryRows: [
        PrintSummaryRowModel(
          label: 'Deposit Total',
          amount: _amount,
          isStrong: true,
        ),
      ],
      generatedAt: DateTime.now(),
      notes: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      terms: bank == null ? null : 'Deposit to ${bank.displayName}',
    );
    await printDocumentDataUsingSettings(
      context: context,
      ref: ref,
      data: data,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final banksAsync = ref.watch(bankAccountsProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final saving = ref.watch(bankDepositSavingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: SafeArea(
        child: Column(
          children: [
            _DepositCommandBar(
              saving: saving,
              onFind: () => context.go(AppRoutes.bankingRegister),
              onNew: _clear,
              onSave: saving ? null : _save,
              onPrint: saving
                  ? null
                  : () => _printDraft(_printBanks, _printOffsets),
              onClear: _clear,
              onClose: () => context.go(AppRoutes.dashboard),
            ),
            Expanded(
              child: banksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (bankList) => accountsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text(error.toString())),
                  data: (accountList) {
                    final banks = bankList
                        .where((account) => account.isActive)
                        .toList();
                    final offsets = accountList
                        .where((account) => account.isActive)
                        .where(
                          (account) =>
                              account.accountType !=
                                  AccountType.accountsReceivable &&
                              account.accountType !=
                                  AccountType.accountsPayable,
                        )
                        .toList();
                    _printBanks = banks;
                    _printOffsets = offsets;
                    final selectedBank = banks
                        .where((account) => account.id == _bankId)
                        .firstOrNull;
                    final selectedOffset = offsets
                        .where((account) => account.id == _offsetId)
                        .firstOrNull;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(10, 8, 0, 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFB9C3CA),
                              ),
                            ),
                            child: Column(
                              children: [
                                _DepositHeader(
                                  banks: banks,
                                  offsets: offsets,
                                  bankId: _bankId,
                                  offsetId: _offsetId,
                                  depositDate: _depositDate,
                                  dateText: _dateFmt.format(_depositDate),
                                  amount: _amount,
                                  money: _moneyFmt.format,
                                  onBankChanged: (value) =>
                                      setState(() => _bankId = value),
                                  onOffsetChanged: (value) =>
                                      setState(() => _offsetId = value),
                                  onPickDate: _pickDate,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: _DepositEntryTable(
                                      amountCtrl: _amountCtrl,
                                      receivedFromCtrl: _receivedFromCtrl,
                                      memoCtrl: _memoCtrl,
                                      bankName:
                                          selectedBank?.displayName ??
                                          'Select deposit account',
                                      offsetName:
                                          selectedOffset?.name ??
                                          'Select from account',
                                      onChanged: () => setState(() {}),
                                    ),
                                  ),
                                ),
                                _DepositFooter(
                                  amount: _amount,
                                  money: _moneyFmt.format,
                                  saving: saving,
                                  onSave: saving ? null : _save,
                                  onClear: _clear,
                                ),
                              ],
                            ),
                          ),
                        ),
                        _DepositSidePanel(
                          bank: selectedBank,
                          offset: selectedOffset,
                          amount: _amount,
                          receivedFrom: _receivedFromCtrl.text,
                          memo: _memoCtrl.text,
                          money: _moneyFmt.format,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const _ShortcutStrip(),
          ],
        ),
      ),
    );
  }
}

class _DepositCommandBar extends StatelessWidget {
  const _DepositCommandBar({
    required this.saving,
    required this.onFind,
    required this.onNew,
    required this.onClear,
    required this.onClose,
    this.onSave,
    this.onPrint,
  });

  final bool saving;
  final VoidCallback onFind;
  final VoidCallback onNew;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final VoidCallback? onSave;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F6F7),
        border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const _Tool(icon: Icons.arrow_back, label: 'Prev'),
          const _Tool(icon: Icons.arrow_forward, label: 'Next'),
          _Tool(icon: Icons.search, label: 'Find', onTap: onFind),
          _Tool(icon: Icons.note_add_outlined, label: 'New', onTap: onNew),
          _Tool(
            icon: saving ? Icons.hourglass_top : Icons.save_outlined,
            label: saving ? 'Saving' : 'Save',
            onTap: onSave,
          ),
          _Tool(icon: Icons.delete_outline, label: 'Clear', onTap: onClear),
          const _Separator(),
          _Tool(
            icon: Icons.print_outlined,
            label: 'Print',
            onTap: saving ? null : onPrint,
          ),
          const Spacer(),
          _Tool(icon: Icons.close, label: 'Close', onTap: onClose),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _DepositHeader extends StatelessWidget {
  const _DepositHeader({
    required this.banks,
    required this.offsets,
    required this.bankId,
    required this.offsetId,
    required this.depositDate,
    required this.dateText,
    required this.amount,
    required this.money,
    required this.onBankChanged,
    required this.onOffsetChanged,
    required this.onPickDate,
  });

  final List<BankAccountModel> banks;
  final List<AccountModel> offsets;
  final String? bankId;
  final String? offsetId;
  final DateTime depositDate;
  final String dateText;
  final double amount;
  final String Function(double value) money;
  final ValueChanged<String?> onBankChanged;
  final ValueChanged<String?> onOffsetChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final safeBank = banks.any((account) => account.id == bankId)
        ? bankId
        : null;
    final safeOffset = offsets.any((account) => account.id == offsetId)
        ? offsetId
        : null;
    final bank = banks.where((account) => account.id == safeBank).firstOrNull;

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
                const QbStripLabel('DEPOSIT TO'),
                const SizedBox(width: 8),
                Expanded(
                  child: _BankDropdown(
                    value: safeBank,
                    banks: banks,
                    onChanged: onBankChanged,
                  ),
                ),
                const SizedBox(width: 16),
                const QbStripLabel('FROM ACCOUNT'),
                const SizedBox(width: 8),
                Expanded(
                  child: _AccountDropdown(
                    value: safeOffset,
                    accounts: offsets,
                    onChanged: onOffsetChanged,
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
                      'Record Deposit',
                      style: Theme.of(context).textTheme.headlineMedium
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
                          label: 'DATE',
                          labelWidth: 86,
                          child: QbDateBox(
                            text: dateText,
                            enabled: true,
                            onTap: onPickDate,
                          ),
                        ),
                        const SizedBox(height: 6),
                        QbHorizontalField(
                          label: 'DEPOSIT #',
                          labelWidth: 86,
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
                          label: 'THIS DEPOSIT',
                          value: money(amount),
                          accent: true,
                        ),
                        const SizedBox(height: 6),
                        _StatBox(
                          label: 'AFTER DEPOSIT',
                          value: bank == null
                              ? '-'
                              : money(bank.balance + amount),
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

class _DepositEntryTable extends StatelessWidget {
  const _DepositEntryTable({
    required this.amountCtrl,
    required this.receivedFromCtrl,
    required this.memoCtrl,
    required this.bankName,
    required this.offsetName,
    required this.onChanged,
  });

  final TextEditingController amountCtrl;
  final TextEditingController receivedFromCtrl;
  final TextEditingController memoCtrl;
  final String bankName;
  final String offsetName;
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
                _HeaderCell('RECEIVED FROM', flex: 3),
                _HeaderCell('FROM ACCOUNT', flex: 3),
                _HeaderCell('DEPOSIT TO', flex: 3),
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
                _InputCell(controller: receivedFromCtrl, flex: 3),
                _ReadCell(offsetName, flex: 3),
                _ReadCell(bankName, flex: 3),
                _InputCell(controller: memoCtrl, flex: 4),
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
                'One-line manual deposit. Customer payment batches can be connected here later.',
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

class _DepositFooter extends StatelessWidget {
  const _DepositFooter({
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
              'Deposit creates a bank debit and credits the selected from account.',
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
              child: _AmountRow(
                label: 'DEPOSIT TOTAL',
                value: money(amount),
                strong: true,
              ),
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

class _DepositSidePanel extends StatefulWidget {
  const _DepositSidePanel({
    required this.bank,
    required this.offset,
    required this.amount,
    required this.receivedFrom,
    required this.memo,
    required this.money,
  });

  final BankAccountModel? bank;
  final AccountModel? offset;
  final double amount;
  final String receivedFrom;
  final String memo;
  final String Function(double value) money;

  @override
  State<_DepositSidePanel> createState() => _DepositSidePanelState();
}

class _DepositSidePanelState extends State<_DepositSidePanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: _expanded ? 258 : 38,
      margin: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F8),
        border: Border.all(color: const Color(0xFFB9C3CA)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (_expanded) Positioned.fill(child: _content(context)),
          Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: const Color(0xFFE6EEF2),
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    _expanded ? Icons.chevron_right : Icons.chevron_left,
                    color: const Color(0xFF2B4A56),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    final bank = widget.bank;
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
                'Select deposit account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2D4854),
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Choose a bank account to preview the deposit effect.',
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
                bank.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Record deposit',
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
            widget.amount <= 0
                ? 'Enter amount before saving.'
                : 'Deposit is ready to post.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF714600),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        QbSideSection(
          title: 'Deposit Summary',
          child: Column(
            children: [
              QbInfoRow(
                label: 'Current balance',
                value: widget.money(bank.balance),
              ),
              QbInfoRow(
                label: 'Deposit amount',
                value: widget.money(widget.amount),
              ),
              const Divider(height: 14),
              QbInfoRow(
                label: 'After deposit',
                value: widget.money(bank.balance + widget.amount),
                strong: true,
              ),
            ],
          ),
        ),
        QbSideSection(
          title: 'Entry Preview',
          child: Column(
            children: [
              QbInfoRow(label: 'Debit', value: bank.name),
              QbInfoRow(label: 'Credit', value: widget.offset?.name ?? '-'),
              QbInfoRow(
                label: 'Received from',
                value: widget.receivedFrom.trim().isEmpty
                    ? '-'
                    : widget.receivedFrom.trim(),
              ),
            ],
          ),
        ),
        Expanded(
          child: QbSideSection(
            title: 'Memo',
            child: Text(
              widget.memo.trim().isEmpty
                  ? 'No memo added.'
                  : widget.memo.trim(),
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
  const _InputCell({required this.controller, required this.flex});
  final TextEditingController controller;
  final int flex;

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

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? const Color(0xFF234C5D) : const Color(0xFF7D8B93);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: enabled ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 48,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: const Color(0xFFC4D0D6),
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
      Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    ],
  );
}

class _ShortcutStrip extends StatelessWidget {
  const _ShortcutStrip();

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    alignment: Alignment.centerLeft,
    decoration: const BoxDecoration(
      color: Color(0xFFD4DDE3),
      border: Border(top: BorderSide(color: Color(0xFFAFBBC4))),
    ),
    child: Text(
      'Record deposit workspace  •  Save posts deposit  •  Esc Close',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: const Color(0xFF33434C),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

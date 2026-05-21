// journal_entry_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../../../core/widgets/qb/qb_widgets.dart';
import '../../../core/constants/api_enums.dart' show AccountType;
import '../../../core/widgets/app_text_field.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../data/models/journal_entry_model.dart';
import '../providers/journal_entries_provider.dart';

class JournalEntryLineState {
  String? accountId;
  String description = '';
  double debit = 0;
  double credit = 0;
}

class JournalEntryFormState {
  DateTime entryDate = DateTime.now();
  String memo = '';
  List<JournalEntryLineState> lines = [
    JournalEntryLineState(),
    JournalEntryLineState(),
  ];

  double get totalDebit => lines.fold(0, (sum, line) => sum + line.debit);
  double get totalCredit => lines.fold(0, (sum, line) => sum + line.credit);
  bool get isBalanced => totalDebit > 0 && totalDebit == totalCredit;
}

final journalEntryFormProvider =
    StateProvider.autoDispose<JournalEntryFormState>(
      (ref) => JournalEntryFormState(),
    );
final journalEntrySavingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class JournalEntryFormScreen extends ConsumerWidget {
  const JournalEntryFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(journalEntryFormProvider);
    final saving = ref.watch(journalEntrySavingProvider);

    return TransactionWorkspaceShell(
      workspaceName: 'Journal entry workspace',
      saving: saving,
      posting: false,
      isEdit: false,
      readOnly: false,
      showPagination: false,
      showSaveAndPrint: false,
      showPrint: true,
      showEmail: false,
      showEditNotes: false,
      showVoid: false,
      onFind: () => context.go(AppRoutes.journalEntries),
      onNew: () {
        ref.read(journalEntryFormProvider.notifier).state =
            JournalEntryFormState();
      },
      onSaveDraft: saving ? null : () => _save(context, ref, saveMode: 1),
      onSave: saving ? null : () => _save(context, ref, saveMode: 2),
      onClear: () {
        ref.read(journalEntryFormProvider.notifier).state =
            JournalEntryFormState();
      },
      onClose: () => context.canPop()
          ? context.pop()
          : context.go(AppRoutes.journalEntries),
      formContent: Column(
        children: [
          _HeaderCard(form: form),
          Expanded(child: _LinesCard(form: form)),
          _JournalFooter(
            form: form,
            saving: saving,
            onSave: () => _save(context, ref, saveMode: 2),
          ),
        ],
      ),
      contextPanel: _JournalContextPanel(form: form),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    required int saveMode,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.read(journalEntryFormProvider);
    final validLines = form.lines
        .where(
          (line) =>
              line.accountId != null &&
              line.accountId!.isNotEmpty &&
              (line.debit > 0 || line.credit > 0),
        )
        .toList();

    if (validLines.length < 2) {
      _error(context, l10n.selectAtLeastOneLine);
      return;
    }

    for (final line in validLines) {
      if (line.debit > 0 && line.credit > 0) {
        _error(context, l10n.enterPositiveAmount);
        return;
      }
    }

    final totalDebit = validLines.fold<double>(
      0,
      (sum, line) => sum + line.debit,
    );
    final totalCredit = validLines.fold<double>(
      0,
      (sum, line) => sum + line.credit,
    );
    if (totalDebit <= 0 || totalCredit <= 0 || totalDebit != totalCredit) {
      _error(context, l10n.totalAmount);
      return;
    }

    final dto = CreateJournalEntryDto(
      entryDate: form.entryDate,
      memo: form.memo,
      saveMode: saveMode,
      lines: validLines
          .map(
            (line) => CreateJournalEntryLineDto(
              accountId: line.accountId!,
              description: line.description,
              debit: line.debit,
              credit: line.credit,
            ),
          )
          .toList(),
    );

    ref.read(journalEntrySavingProvider.notifier).state = true;
    final result = await ref.read(journalEntriesProvider.notifier).create(dto);
    ref.read(journalEntrySavingProvider.notifier).state = false;

    if (!context.mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.poCreatedSuccess)));
        context.go(AppRoutes.journalEntries);
      },
      failure: (error) => _error(context, error.message),
    );
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static void _error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({required this.form});

  final JournalEntryFormState form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

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
                const QbStripLabel('JOURNAL ENTRY'),
                const SizedBox(width: 8),
                const Expanded(child: QbStaticBox(text: 'General Journal')),
                const SizedBox(width: 16),
                const QbStripLabel('STATUS'),
                const SizedBox(width: 8),
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  color: form.isBalanced
                      ? const Color(0xFFD9F0DE)
                      : const Color(0xFFFFE4E4),
                  child: Text(
                    form.isBalanced ? 'BALANCED' : 'NOT BALANCED',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: form.isBalanced
                          ? const Color(0xFF1B7D2B)
                          : const Color(0xFFC62828),
                      fontWeight: FontWeight.w900,
                    ),
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
                    width: 320,
                    child: Text(
                      l10n.newText,
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
                        QbHorizontalField(
                          label: 'DATE',
                          labelWidth: 76,
                          child: QbDateBox(
                            text: JournalEntryFormScreen._dateOnly(
                              form.entryDate,
                            ),
                            enabled: false,
                          ),
                        ),
                        const SizedBox(height: 6),
                        QbHorizontalField(
                          label: 'ENTRY #',
                          labelWidth: 76,
                          child: const QbStaticBox(text: 'AUTO'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        QbStackedField(
                          label: l10n.memoInternal,
                          child: AppTextField(
                            label: '',
                            initialValue: form.memo,
                            onChanged: (value) {
                              form.memo = value;
                              _update(ref, form);
                            },
                          ),
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

class _LinesCard extends ConsumerWidget {
  const _LinesCard({required this.form});

  final JournalEntryFormState form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF9EADB6)),
        ),
        child: Column(
          children: [
            Container(
              height: 30,
              color: const Color(0xFFDDE8ED),
              child: Row(
                children: [
                  _HeaderCell(l10n.chartOfAccounts, flex: 4),
                  _HeaderCell(l10n.description, flex: 4),
                  _HeaderCell('DEBIT', flex: 2, right: true),
                  _HeaderCell('CREDIT', flex: 2, right: true),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ...form.lines.asMap().entries.map(
                    (entry) => _JournalLineRow(
                      index: entry.key,
                      line: entry.value,
                      form: form,
                      shaded: entry.key.isEven,
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () {
                        form.lines.add(JournalEntryLineState());
                        _update(ref, form);
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.addLine),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalLineRow extends ConsumerWidget {
  const _JournalLineRow({
    required this.index,
    required this.line,
    required this.form,
    required this.shaded,
  });

  final int index;
  final JournalEntryLineState line;
  final JournalEntryFormState form;
  final bool shaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.maybeWhen(
      data: (data) => data
          .where(
            (account) =>
                account.isActive &&
                account.accountType != AccountType.accountsReceivable &&
                account.accountType != AccountType.accountsPayable,
          )
          .toList(),
      orElse: () => <AccountModel>[],
    );
    final safeAccountId =
        accounts.any((account) => account.id == line.accountId)
        ? line.accountId
        : null;

    return Container(
      height: 52,
      color: shaded ? const Color(0xFFDDEFF4) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: DropdownButtonFormField<String>(
                initialValue: safeAccountId,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                items: accounts
                    .map<DropdownMenuItem<String>>(
                      (AccountModel account) => DropdownMenuItem<String>(
                        value: account.id,
                        child: Text(
                          '${account.code} - ${account.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  line.accountId = value;
                  _update(ref, form);
                },
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: AppTextField(
                label: '',
                initialValue: line.description,
                onChanged: (value) {
                  line.description = value;
                  _update(ref, form);
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: AppTextField(
                label: '',
                initialValue: line.debit == 0
                    ? ''
                    : line.debit.toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  line.debit = double.tryParse(value) ?? 0;
                  if (line.debit > 0) line.credit = 0;
                  _update(ref, form);
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: AppTextField(
                label: '',
                initialValue: line.credit == 0
                    ? ''
                    : line.credit.toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  line.credit = double.tryParse(value) ?? 0;
                  if (line.credit > 0) line.debit = 0;
                  _update(ref, form);
                },
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: form.lines.length <= 2
                  ? null
                  : () {
                      form.lines.removeAt(index);
                      _update(ref, form);
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalFooter extends StatelessWidget {
  const _JournalFooter({
    required this.form,
    required this.saving,
    required this.onSave,
  });

  final JournalEntryFormState form;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F9),
        border: Border(top: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Debits and credits must balance before posting the journal entry.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF53656E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 360,
            child: Column(
              children: [
                _TotalLine(
                  label: 'TOTAL DEBIT',
                  value: '${form.totalDebit.toStringAsFixed(2)} ${l10n.egp}',
                ),
                _TotalLine(
                  label: 'TOTAL CREDIT',
                  value: '${form.totalCredit.toStringAsFixed(2)} ${l10n.egp}',
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: form.isBalanced
                        ? const Color(0xFFE7F1F4)
                        : const Color(0xFFFFECEC),
                    border: Border.all(
                      color: form.isBalanced
                          ? const Color(0xFF9DB2BC)
                          : const Color(0xFFE18B8B),
                    ),
                  ),
                  child: _TotalLine(
                    label: 'STATUS',
                    value: form.isBalanced ? 'Balanced' : 'Needs balance',
                    strong: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          OutlinedButton(
            onPressed: saving ? null : onSave,
            style: _smallButton(),
            child: Text(saving ? 'Saving...' : 'Save & Close'),
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

class _JournalContextPanel extends StatelessWidget {
  const _JournalContextPanel({required this.form});

  final JournalEntryFormState form;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final difference = (form.totalDebit - form.totalCredit).abs();
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
            'Journal Entry',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
          color: form.isBalanced
              ? const Color(0xFFDFF0E4)
              : const Color(0xFFFFE7C4),
          child: Text(
            form.isBalanced
                ? 'Ready to post.'
                : 'Difference ${difference.toStringAsFixed(2)} ${l10n.egp}.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: form.isBalanced
                  ? const Color(0xFF1B7D2B)
                  : const Color(0xFF714600),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        QbSideSection(
          title: 'Totals',
          child: Column(
            children: [
              QbInfoRow(
                label: 'Debit',
                value: '${form.totalDebit.toStringAsFixed(2)} ${l10n.egp}',
              ),
              QbInfoRow(
                label: 'Credit',
                value: '${form.totalCredit.toStringAsFixed(2)} ${l10n.egp}',
              ),
              const Divider(height: 14),
              QbInfoRow(
                label: 'Difference',
                value: '${difference.toStringAsFixed(2)} ${l10n.egp}',
                strong: true,
              ),
            ],
          ),
        ),
        Expanded(
          child: QbSideSection(
            title: 'Memo',
            child: Text(
              form.memo.trim().isEmpty ? 'No memo added.' : form.memo.trim(),
              style: const TextStyle(color: Color(0xFF4E616A)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
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

void _update(WidgetRef ref, JournalEntryFormState old) {
  ref.read(journalEntryFormProvider.notifier).state = JournalEntryFormState()
    ..entryDate = old.entryDate
    ..memo = old.memo
    ..lines = List.from(old.lines);
}

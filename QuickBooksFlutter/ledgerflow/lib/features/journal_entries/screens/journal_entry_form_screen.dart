// journal_entry_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../../../core/constants/api_enums.dart' show AccountType;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final form = ref.watch(journalEntryFormProvider);
    final saving = ref.watch(journalEntrySavingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newText),
        actions: [
          AppButton(
            label: l10n.cancel,
            variant: AppButtonVariant.secondary,
            onPressed: saving
                ? null
                : () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.journalEntries),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.saveDraft,
            variant: AppButtonVariant.secondary,
            loading: saving,
            onPressed: saving ? null : () => _save(context, ref, saveMode: 1),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.save,
            loading: saving,
            onPressed: saving ? null : () => _save(context, ref, saveMode: 2),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _HeaderCard(form: form),
          const SizedBox(height: 24),
          _LinesCard(form: form),
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _TotalsCard(form: form),
          ),
        ],
      ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: l10n.billDate,
                    readOnly: true,
                    initialValue: JournalEntryFormScreen._dateOnly(
                      form.entryDate,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: l10n.memoInternal,
                    initialValue: form.memo,
                    onChanged: (value) {
                      form.memo = value;
                      _update(ref, form);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(flex: 3, child: Text(l10n.chartOfAccounts)),
                Expanded(flex: 2, child: Text(l10n.description)),
                Expanded(child: Text(l10n.amount)),
                Expanded(child: Text(l10n.amount)),
                const SizedBox(width: 40),
              ],
            ),
            const Divider(),
            ...form.lines.asMap().entries.map(
              (entry) => _JournalLineRow(
                index: entry.key,
                line: entry.value,
                form: form,
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () {
                  form.lines.add(JournalEntryLineState());
                  _update(ref, form);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addLine),
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
  });

  final int index;
  final JournalEntryLineState line;
  final JournalEntryFormState form;

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: DropdownButtonFormField<String>(
                initialValue: safeAccountId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: accounts
                    .map<DropdownMenuItem<String>>(
                      (AccountModel account) => DropdownMenuItem<String>(
                        value: account.id,
                        child: Text('${account.code} - ${account.name}'),
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
            flex: 2,
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

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.form});

  final JournalEntryFormState form;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _row(
                l10n.totalAmount,
                '${form.totalDebit.toStringAsFixed(2)} ${l10n.egp}',
              ),
              const SizedBox(height: 8),
              _row(
                l10n.totalAmount,
                '${form.totalCredit.toStringAsFixed(2)} ${l10n.egp}',
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.statusPosted,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    form.isBalanced
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: form.isBalanced ? cs.primary : cs.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

void _update(WidgetRef ref, JournalEntryFormState old) {
  ref.read(journalEntryFormProvider.notifier).state = JournalEntryFormState()
    ..entryDate = old.entryDate
    ..memo = old.memo
    ..lines = List.from(old.lines);
}

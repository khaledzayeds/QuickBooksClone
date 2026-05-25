// journal_entry_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/journal_entry_model.dart';
import '../providers/journal_entries_provider.dart';

class JournalEntryDetailsScreen extends ConsumerWidget {
  const JournalEntryDetailsScreen({super.key, required this.id});

  final String id;

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref,
    String label,
    Future<void> Function() action,
  ) async {
    await action();
    if (!context.mounted) return;
    ref.invalidate(journalEntryDetailsProvider(id));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(journalEntryDetailsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
        actions: [
          entryAsync.maybeWhen(
            data: (entry) => _JournalActions(
              entry: entry,
              onRun: (label, action) => _runAction(context, ref, label, action),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(journalEntryDetailsProvider(id)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: entryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (entry) => _DetailsBody(entry: entry),
      ),
    );
  }
}

class _JournalActions extends ConsumerWidget {
  const _JournalActions({required this.entry, required this.onRun});

  final JournalEntryModel entry;
  final Future<void> Function(String label, Future<void> Function() action)
  onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(journalEntriesProvider.notifier);
    if (entry.isVoid) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!entry.isPosted)
          TextButton(
            onPressed: () => onRun(
              'Journal entry posted.',
              () async => notifier.post(entry.id),
            ),
            child: const Text('Post'),
          ),
        if (entry.isPosted)
          IconButton(
            tooltip: 'Void journal entry',
            onPressed: () => onRun(
              'Journal entry voided.',
              () async => notifier.voidEntry(entry.id),
            ),
            icon: Icon(
              Icons.block_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.entry});
  final JournalEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.entryNumber.isEmpty
                            ? 'Journal Entry'
                            : entry.entryNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusChip(
                      label: entry.isVoid
                          ? 'Void'
                          : entry.isPosted
                          ? 'Posted'
                          : 'Draft',
                    ),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Entry date',
                  value: fmt.format(entry.entryDate),
                ),
                _InfoRow(
                  label: 'Memo',
                  value: entry.memo.isEmpty ? '-' : entry.memo,
                ),
                if (entry.postedTransactionId != null &&
                    entry.postedTransactionId!.isNotEmpty)
                  _InfoRow(
                    label: 'Posted transaction',
                    value: entry.postedTransactionId!,
                  ),
                if (entry.reversalTransactionId != null &&
                    entry.reversalTransactionId!.isNotEmpty)
                  _InfoRow(
                    label: 'Reversal transaction',
                    value: entry.reversalTransactionId!,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lines',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Divider(height: 20),
                if (entry.lines.isEmpty)
                  const Text('No lines.')
                else
                  ...entry.lines.map((line) => _LineTile(line: line)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 360,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _AmountRow(label: 'Total debit', amount: entry.totalDebit),
                    const SizedBox(height: 8),
                    _AmountRow(
                      label: 'Total credit',
                      amount: entry.totalCredit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line});
  final JournalEntryLineModel line;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.account_balance_outlined),
    title: Text(
      '${line.accountCode ?? ''} ${line.accountName ?? line.accountId}'.trim(),
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(line.description.isEmpty ? '-' : line.description),
    trailing: Text(
      'Dr ${line.debit.toStringAsFixed(2)} / Cr ${line.credit.toStringAsFixed(2)}',
      style: const TextStyle(fontWeight: FontWeight.w900),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = label == 'Void'
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.14),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).hintColor)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.amount});
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount.toStringAsFixed(2), style: style),
      ],
    );
  }
}

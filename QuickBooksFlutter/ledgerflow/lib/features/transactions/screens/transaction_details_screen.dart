// transaction_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/transaction_model.dart';
import '../providers/transactions_provider.dart';

class TransactionDetailsScreen extends ConsumerWidget {
  const TransactionDetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionDetailsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting Transaction'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(transactionDetailsProvider(id)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: transactionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (transaction) => _DetailsBody(transaction: transaction),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.transaction});

  final TransactionModel transaction;

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
                        transaction.referenceNumber.isEmpty
                            ? transaction.transactionType
                            : transaction.referenceNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusChip(transaction: transaction),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(label: 'Type', value: transaction.transactionType),
                _InfoRow(
                  label: 'Date',
                  value: fmt.format(transaction.transactionDate),
                ),
                if (transaction.sourceEntityType != null &&
                    transaction.sourceEntityType!.isNotEmpty)
                  _InfoRow(
                    label: 'Source',
                    value: transaction.sourceEntityType!,
                  ),
                if (transaction.sourceEntityId != null &&
                    transaction.sourceEntityId!.isNotEmpty)
                  _InfoRow(
                    label: 'Source id',
                    value: transaction.sourceEntityId!,
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
                if (transaction.lines.isEmpty)
                  const Text('No lines.')
                else
                  ...transaction.lines.map((line) => _LineTile(line: line)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 380,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _AmountRow(
                      label: 'Total debit',
                      amount: transaction.totalDebit,
                    ),
                    const SizedBox(height: 8),
                    _AmountRow(
                      label: 'Total credit',
                      amount: transaction.totalCredit,
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

  final TransactionLineModel line;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.account_balance_outlined),
      title: Text(
        '${line.accountCode ?? ''} ${line.accountName ?? line.accountId}'
            .trim(),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(line.description.isEmpty ? '-' : line.description),
      trailing: Text(
        'Dr ${line.debit.toStringAsFixed(2)} / Cr ${line.credit.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final color = transaction.isVoided
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Chip(
      label: Text(transaction.isVoided ? 'Void' : transaction.status),
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

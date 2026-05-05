// estimate_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/estimate_model.dart';
import '../providers/estimates_provider.dart';

class EstimateDetailsScreen extends ConsumerWidget {
  const EstimateDetailsScreen({super.key, required this.id});

  final String id;

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref,
    String label,
    Future<void> Function() action,
  ) async {
    await action();
    if (!context.mounted) return;
    ref.invalidate(estimateDetailsProvider(id));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estimateAsync = ref.watch(estimateDetailsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimate'),
        actions: [
          estimateAsync.maybeWhen(
            data: (estimate) => _EstimateActions(
              estimate: estimate,
              onRun: (label, action) => _runAction(context, ref, label, action),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(estimateDetailsProvider(id)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: estimateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (estimate) => _DetailsBody(estimate: estimate),
      ),
    );
  }
}

class _EstimateActions extends ConsumerWidget {
  const _EstimateActions({required this.estimate, required this.onRun});

  final EstimateModel estimate;
  final Future<void> Function(String label, Future<void> Function() action)
  onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (estimate.isCancelled || estimate.isAccepted || estimate.isDeclined)
      return const SizedBox.shrink();
    final notifier = ref.read(estimatesProvider.notifier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () =>
              onRun('Estimate sent.', () async => notifier.send(estimate.id)),
          child: const Text('Send'),
        ),
        TextButton(
          onPressed: () => onRun(
            'Estimate accepted.',
            () async => notifier.accept(estimate.id),
          ),
          child: const Text('Accept'),
        ),
        TextButton(
          onPressed: () => onRun(
            'Estimate declined.',
            () async => notifier.decline(estimate.id),
          ),
          child: const Text('Decline'),
        ),
        IconButton(
          tooltip: 'Cancel estimate',
          onPressed: () => onRun(
            'Estimate cancelled.',
            () async => notifier.cancel(estimate.id),
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
  const _DetailsBody({required this.estimate});

  final EstimateModel estimate;

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
                        estimate.estimateNumber.isEmpty
                            ? 'Estimate'
                            : estimate.estimateNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusChip(label: _statusLabel(estimate)),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Customer',
                  value: estimate.customerName ?? estimate.customerId,
                ),
                _InfoRow(
                  label: 'Estimate date',
                  value: fmt.format(estimate.estimateDate),
                ),
                _InfoRow(
                  label: 'Expiration date',
                  value: fmt.format(estimate.expirationDate),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _LinesCard(lines: estimate.lines),
        const SizedBox(height: 16),
        _TotalsCard(
          subtotal: estimate.subtotal,
          taxAmount: estimate.taxAmount,
          totalAmount: estimate.totalAmount,
        ),
      ],
    );
  }

  static String _statusLabel(EstimateModel estimate) {
    if (estimate.isCancelled) return 'Cancelled';
    if (estimate.isAccepted) return 'Accepted';
    if (estimate.isDeclined) return 'Declined';
    if (estimate.sentAt != null) return 'Sent';
    return 'Draft';
  }
}

class _LinesCard extends StatelessWidget {
  const _LinesCard({required this.lines});
  final List<EstimateLineModel> lines;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lines',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Divider(height: 20),
          if (lines.isEmpty)
            const Text('No lines.')
          else
            ...lines.map((line) => _LineTile(line: line)),
        ],
      ),
    ),
  );
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line});
  final EstimateLineModel line;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      line.description,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      'Qty ${line.quantity.toStringAsFixed(2)} x ${line.unitPrice.toStringAsFixed(2)}',
    ),
    trailing: Text(
      line.lineTotal.toStringAsFixed(2),
      style: const TextStyle(fontWeight: FontWeight.w900),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = label == 'Cancelled' || label == 'Declined'
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

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
  });
  final double subtotal;
  final double taxAmount;
  final double totalAmount;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: SizedBox(
      width: 360,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _AmountRow(label: 'Subtotal', amount: subtotal),
              const SizedBox(height: 8),
              _AmountRow(label: 'Tax', amount: taxAmount),
              const Divider(height: 24),
              _AmountRow(label: 'Total', amount: totalAmount, isTotal: true),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });
  final String label;
  final double amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount.toStringAsFixed(2), style: style),
      ],
    );
  }
}

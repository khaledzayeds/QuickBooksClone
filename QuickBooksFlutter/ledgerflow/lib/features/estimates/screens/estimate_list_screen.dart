// estimate_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../data/models/estimate_model.dart';
import '../providers/estimates_provider.dart';

class EstimateListScreen extends ConsumerWidget {
  const EstimateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final estimatesAsync = ref.watch(estimatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.estimates),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => ref.read(estimatesProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: () => context.go('/sales/estimates/new'),
              icon: const Icon(Icons.add),
              label: Text('${l10n.newText} ${l10n.estimates}'),
            ),
          ),
        ],
      ),
      body: estimatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(estimatesProvider.notifier).refresh(),
        ),
        data: (estimates) {
          if (estimates.isEmpty) return const _EmptyState();

          return RefreshIndicator(
            onRefresh: () => ref.read(estimatesProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: estimates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _EstimateCard(estimate: estimates[index]),
            ),
          );
        },
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.estimate});

  final EstimateModel estimate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final statusLabel = estimate.isCancelled
        ? l10n.statusCancelled
        : estimate.isAccepted
            ? l10n.statusOpen
            : estimate.isDeclined
                ? l10n.statusClosed
                : estimate.sentAt != null
                    ? l10n.statusPosted
                    : l10n.statusDraft;

    final statusColor = estimate.isCancelled || estimate.isDeclined ? cs.error : cs.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: estimate.isCancelled || estimate.isDeclined ? cs.errorContainer : cs.primaryContainer,
                child: Icon(
                  estimate.isCancelled || estimate.isDeclined ? Icons.block : Icons.request_quote_outlined,
                  color: estimate.isCancelled || estimate.isDeclined ? cs.onErrorContainer : cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estimate.estimateNumber.isEmpty ? '-' : estimate.estimateNumber,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(estimate.customerName ?? '-'),
                    const SizedBox(height: 4),
                    Text(
                      '${_date(estimate.estimateDate)} • ${l10n.dueDate}: ${_date(estimate.expirationDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${estimate.totalAmount.toStringAsFixed(2)} ${l10n.egp}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.request_quote_outlined, size: 56),
            const SizedBox(height: 16),
            Text(l10n.estimates, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.underDevelopment, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/sales/estimates/new'),
              icon: const Icon(Icons.add),
              label: Text('${l10n.newText} ${l10n.estimates}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

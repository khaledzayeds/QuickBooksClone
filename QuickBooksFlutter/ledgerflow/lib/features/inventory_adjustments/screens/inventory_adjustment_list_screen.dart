// inventory_adjustment_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../data/models/inventory_adjustment_model.dart';
import '../providers/inventory_adjustments_provider.dart';

class InventoryAdjustmentListScreen extends ConsumerWidget {
  const InventoryAdjustmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final adjustmentsAsync = ref.watch(inventoryAdjustmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventoryAdjustments),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () =>
                ref.read(inventoryAdjustmentsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.inventoryAdjustmentNew),
              icon: const Icon(Icons.add),
              label: Text(l10n.newInventoryAdjustment),
            ),
          ),
        ],
      ),
      body: adjustmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.read(inventoryAdjustmentsProvider.notifier).refresh(),
        ),
        data: (adjustments) {
          if (adjustments.isEmpty) return const _EmptyState();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(inventoryAdjustmentsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: adjustments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _InventoryAdjustmentCard(adjustment: adjustments[index]),
            ),
          );
        },
      ),
    );
  }
}

class _InventoryAdjustmentCard extends StatelessWidget {
  const _InventoryAdjustmentCard({required this.adjustment});

  final InventoryAdjustmentModel adjustment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isIncrease = adjustment.isIncrease;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.inventoryAdjustmentDetails.replaceFirst(
            ':id',
            adjustment.id,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isIncrease
                    ? cs.primaryContainer
                    : cs.errorContainer,
                child: Icon(
                  isIncrease
                      ? Icons.add_box_outlined
                      : Icons.indeterminate_check_box_outlined,
                  color: isIncrease
                      ? cs.onPrimaryContainer
                      : cs.onErrorContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adjustment.adjustmentNumber.isEmpty
                          ? '-'
                          : adjustment.adjustmentNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(adjustment.itemName ?? '-'),
                    const SizedBox(height: 4),
                    Text(
                      '${_date(adjustment.adjustmentDate)} • ${adjustment.adjustmentAccountName ?? l10n.chartOfAccounts}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (adjustment.reason != null &&
                        adjustment.reason!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.reason}: ${adjustment.reason}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    adjustment.quantityChange.toStringAsFixed(2),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isIncrease ? cs.primary : cs.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${adjustment.totalCost.toStringAsFixed(2)} ${l10n.egp}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.posted,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
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

  static String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
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
            const Icon(Icons.tune_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              l10n.noInventoryAdjustments,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.startWithNewInventoryAdjustment,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.inventoryAdjustmentNew),
              icon: const Icon(Icons.add),
              label: Text(l10n.newInventoryAdjustment),
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
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
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

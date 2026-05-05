// inventory_adjustment_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/inventory_adjustment_model.dart';
import '../providers/inventory_adjustments_provider.dart';

class InventoryAdjustmentDetailsScreen extends ConsumerWidget {
  const InventoryAdjustmentDetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adjustmentAsync = ref.watch(inventoryAdjustmentDetailsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Adjustment'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.invalidate(inventoryAdjustmentDetailsProvider(id)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: adjustmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (adjustment) => _DetailsBody(adjustment: adjustment),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.adjustment});

  final InventoryAdjustmentModel adjustment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    final isIncrease = adjustment.isIncrease;

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
                        adjustment.adjustmentNumber.isEmpty
                            ? 'Inventory Adjustment'
                            : adjustment.adjustmentNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusChip(isIncrease: isIncrease),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Item',
                  value: adjustment.itemName ?? adjustment.itemId,
                ),
                _InfoRow(
                  label: 'Adjustment date',
                  value: fmt.format(adjustment.adjustmentDate),
                ),
                _InfoRow(
                  label: 'Adjustment account',
                  value:
                      adjustment.adjustmentAccountName ??
                      adjustment.adjustmentAccountId,
                ),
                if (adjustment.reason != null && adjustment.reason!.isNotEmpty)
                  _InfoRow(label: 'Reason', value: adjustment.reason!),
                if (adjustment.postedTransactionId != null &&
                    adjustment.postedTransactionId!.isNotEmpty)
                  _InfoRow(
                    label: 'Posted transaction',
                    value: adjustment.postedTransactionId!,
                  ),
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
                      label: 'Quantity change',
                      value: adjustment.quantityChange.toStringAsFixed(2),
                    ),
                    const SizedBox(height: 8),
                    _AmountRow(
                      label: 'Unit cost',
                      value: adjustment.unitCost.toStringAsFixed(2),
                    ),
                    const Divider(height: 24),
                    _AmountRow(
                      label: 'Total cost',
                      value: adjustment.totalCost.toStringAsFixed(2),
                      isTotal: true,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isIncrease});

  final bool isIncrease;

  @override
  Widget build(BuildContext context) {
    final color = isIncrease
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Chip(
      label: Text(isIncrease ? 'Increase' : 'Decrease'),
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
  const _AmountRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });
  final String label;
  final String value;
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
        Text(value, style: style),
      ],
    );
  }
}

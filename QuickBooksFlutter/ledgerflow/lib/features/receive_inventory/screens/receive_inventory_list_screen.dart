// receive_inventory_list_screen.dart
// Fully localized and aligned with QuickBooks aesthetic.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../data/models/receive_inventory_model.dart';
import '../providers/receive_inventory_provider.dart';

class ReceiveInventoryListScreen extends ConsumerWidget {
  const ReceiveInventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiveInventoryListProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventoryReceipts),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retry,
            onPressed: () => ref.invalidate(receiveInventoryListProvider),
          ),
        ],
      ),
      body: receiptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(receiveInventoryListProvider),
        ),
        data: (receipts) {
          if (receipts.isEmpty) {
            return _EmptyState(
                onNew: () => context.push(AppRoutes.receiveInventoryNew));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(receiveInventoryListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: receipts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final receipt = receipts[index];
                return _ReceiptCard(
                  receipt: receipt,
                  onTap: () => context.push(
                    AppRoutes.receiveInventoryDetails
                        .replaceFirst(':id', receipt.id),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.newReceipt),
        onPressed: () => context.push(AppRoutes.receiveInventoryNew),
      ),
    );
  }
}

// ── Receipt Card ─────────────────────────────────────────────────────────
class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt, required this.onTap});
  final ReceiveInventoryModel receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n  = AppLocalizations.of(context)!;
    final title = receipt.receiptNumber.isEmpty
        ? '${l10n.receipt} #${receipt.id.substring(0, 8)}'
        : receipt.receiptNumber;

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.inventory_2_outlined,
              color: theme.colorScheme.primary),
        ),
        title: Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(receipt.vendorName),
            const SizedBox(height: 2),
            Text(
              '${receipt.receiptDate.day}/${receipt.receiptDate.month}/${receipt.receiptDate.year}  •  ${receipt.lines.length} ${l10n.items}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(receipt.status, // We should localize status too eventually
              style: const TextStyle(fontSize: 11)),
          backgroundColor: theme.colorScheme.primaryContainer,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(l10n.noInventoryReceipts,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(l10n.startReceivingFromPO),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.newReceipt),
            onPressed: onNew,
          ),
        ],
      ),
    );
  }
}

// ── Error State ──────────────────────────────────────────────────────────
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
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

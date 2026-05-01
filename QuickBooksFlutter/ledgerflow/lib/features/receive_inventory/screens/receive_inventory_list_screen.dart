import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/models/receive_inventory_model.dart';
import '../providers/receive_inventory_provider.dart';

class ReceiveInventoryListScreen extends ConsumerWidget {
  const ReceiveInventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiveInventoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('استلام المخزون'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
            return _EmptyState(onNew: () => context.push(AppRoutes.receiveInventoryNew));
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
                    AppRoutes.receiveInventoryDetails.replaceFirst(':id', receipt.id),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('استلام جديد'),
        onPressed: () => context.push(AppRoutes.receiveInventoryNew),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt, required this.onTap});

  final ReceiveInventoryModel receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = receipt.receiptNumber.isEmpty ? 'استلام #${receipt.id}' : receipt.receiptNumber;

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(receipt.vendorName),
            const SizedBox(height: 2),
            Text('عدد السطور: ${receipt.lines.length}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text('لا توجد سندات استلام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('ابدأ باستلام مخزون من أمر شراء مفتوح'),
          const SizedBox(height: 24),
          ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('استلام جديد'), onPressed: onNew),
        ],
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
            OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'), onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

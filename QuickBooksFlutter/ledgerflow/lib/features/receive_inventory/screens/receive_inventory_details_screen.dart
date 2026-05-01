// receive_inventory_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../providers/receive_inventory_provider.dart';

class ReceiveInventoryDetailsScreen extends ConsumerWidget {
  const ReceiveInventoryDetailsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiveInventoryDetailsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الاستلام | Receipt Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث | Refresh',
            onPressed: () =>
                ref.invalidate(receiveInventoryDetailsProvider(id)),
          ),
        ],
      ),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة | Retry'),
                onPressed: () =>
                    ref.invalidate(receiveInventoryDetailsProvider(id)),
              ),
            ],
          ),
        ),
        data: (receipt) {
          final date =
              DateFormat('yyyy/MM/dd').format(receipt.receiptDate);
          final title = receipt.receiptNumber.isEmpty
              ? 'استلام #${receipt.id.substring(0, 8)}'
              : receipt.receiptNumber;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Header Card ──────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                          ),
                          Chip(
                            label: Text(receipt.status,
                                style: const TextStyle(fontSize: 12)),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                          label: 'المورد | Vendor',
                          value: receipt.vendorName),
                      _InfoRow(
                          label: 'تاريخ الاستلام | Date',
                          value: date),
                      if (receipt.purchaseOrderId.isNotEmpty)
                        _InfoRow(
                          label: 'أمر الشراء | Purchase Order',
                          value: receipt.purchaseOrderId,
                          isLink: true,
                          onTap: () => context.push(
                            AppRoutes.purchaseOrderDetails.replaceFirst(
                                ':id', receipt.purchaseOrderId),
                          ),
                        ),
                      if (receipt.notes != null &&
                          receipt.notes!.isNotEmpty)
                        _InfoRow(
                            label: 'ملاحظات | Notes',
                            value: receipt.notes!),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Lines ────────────────────────────────────
              Text('الأصناف المستلمة | Received Items',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              if (receipt.lines.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('لا توجد أصناف | No items'),
                  ),
                )
              else
                ...receipt.lines.map(
                  (line) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory_2_outlined,
                            size: 20,
                            color:
                                Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(line.itemName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text('ID: ${line.itemId.substring(0, 8)}…'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(line.quantityReceived.toStringAsFixed(2),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          const Text('مستلم | Received',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Info Row ─────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
  });
  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(color: Theme.of(context).hintColor)),
          const Spacer(),
          isLink
              ? GestureDetector(
                  onTap: onTap,
                  child: Text(value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline)),
                )
              : Flexible(
                  child: Text(value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
        ],
      ),
    );
  }
}

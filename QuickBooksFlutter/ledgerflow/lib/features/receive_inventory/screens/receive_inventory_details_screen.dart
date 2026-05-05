// receive_inventory_details_screen.dart
// Fully localized and aligned with QuickBooks aesthetic.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../providers/receive_inventory_provider.dart';

class ReceiveInventoryDetailsScreen extends ConsumerWidget {
  const ReceiveInventoryDetailsScreen({super.key, required this.id});
  final String id;

  bool _isVoidStatus(String status) => status.toLowerCase().contains('void') || status.toLowerCase().contains('cancel');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiveInventoryDetailsProvider(id));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.receipt} | ${l10n.orderDetails}'),
        actions: [
          receiptAsync.maybeWhen(
            data: (receipt) => !_isVoidStatus(receipt.status)
                ? TextButton.icon(
                    onPressed: () => context.push('${AppRoutes.purchaseBillNew}?receiptId=${receipt.id}'),
                    icon: const Icon(Icons.request_quote_outlined),
                    label: const Text('Create Bill'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retry,
            onPressed: () => ref.invalidate(receiveInventoryDetailsProvider(id)),
          ),
        ],
      ),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
                onPressed: () => ref.invalidate(receiveInventoryDetailsProvider(id)),
              ),
            ],
          ),
        ),
        data: (receipt) {
          final fmt = DateFormat('dd/MM/yyyy');
          final date = fmt.format(receipt.receiptDate);
          final title = receipt.receiptNumber.isEmpty ? '${l10n.receipt} #${receipt.id.substring(0, 8)}' : receipt.receiptNumber;
          final isFromPo = receipt.purchaseOrderId.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          ),
                          Chip(
                            label: Text(receipt.status, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _InfoRow(label: l10n.vendor, value: receipt.vendorName),
                      _InfoRow(label: l10n.receiptDate, value: date),
                      _InfoRow(label: 'Receipt Mode', value: isFromPo ? 'From Purchase Order' : 'Standalone'),
                      if (isFromPo)
                        _InfoRow(
                          label: l10n.purchaseOrders,
                          value: receipt.purchaseOrderId,
                          isLink: true,
                          onTap: () => context.push(AppRoutes.purchaseOrderDetails.replaceFirst(':id', receipt.purchaseOrderId)),
                        ),
                      if (receipt.notes != null && receipt.notes!.isNotEmpty) _InfoRow(label: l10n.notes, value: receipt.notes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.receivedItems, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (receipt.lines.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.underDevelopment),
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
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          line.purchaseOrderLineId == null ? Icons.inventory_2_outlined : Icons.receipt_long_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(line.itemName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(line.purchaseOrderLineId == null ? 'Manual line • ID: ${line.itemId.substring(0, 8)}…' : 'PO-linked line • ID: ${line.itemId.substring(0, 8)}…'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(line.quantityReceived.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('${line.unitCost.toStringAsFixed(2)} / unit', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SizedBox(
                  width: 320,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(receipt.totalAmount.toStringAsFixed(2), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        ],
                      ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.isLink = false, this.onTap});
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
          Text(label, style: TextStyle(color: Theme.of(context).hintColor)),
          const Spacer(),
          isLink
              ? GestureDetector(
                  onTap: onTap,
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
                  ),
                )
              : Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

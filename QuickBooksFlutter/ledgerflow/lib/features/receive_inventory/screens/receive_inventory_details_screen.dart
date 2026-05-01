import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/receive_inventory_provider.dart';

class ReceiveInventoryDetailsScreen extends ConsumerWidget {
  const ReceiveInventoryDetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiveInventoryDetailsProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الاستلام')),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (receipt) {
          final date = DateFormat('yyyy/MM/dd').format(receipt.receiptDate);
          final title = receipt.receiptNumber.isEmpty ? 'استلام #${receipt.id}' : receipt.receiptNumber;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'المورد', value: receipt.vendorName),
                      _InfoRow(label: 'تاريخ الاستلام', value: date),
                      _InfoRow(label: 'الحالة', value: receipt.status),
                      _InfoRow(label: 'أمر الشراء', value: receipt.purchaseOrderId),
                      if (receipt.notes != null && receipt.notes!.isNotEmpty)
                        _InfoRow(label: 'ملاحظات', value: receipt.notes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('الأصناف', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...receipt.lines.map(
                (line) => Card(
                  child: ListTile(
                    title: Text(line.itemName),
                    subtitle: Text('Item ID: ${line.itemId}'),
                    trailing: Text(
                      line.quantityReceived.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).hintColor)),
          const Spacer(),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

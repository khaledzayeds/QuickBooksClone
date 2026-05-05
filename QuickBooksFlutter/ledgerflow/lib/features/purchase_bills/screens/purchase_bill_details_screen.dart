// purchase_bill_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../data/models/purchase_bill_model.dart';
import '../providers/purchase_bills_provider.dart';

class PurchaseBillDetailsScreen extends ConsumerWidget {
  const PurchaseBillDetailsScreen({super.key, required this.id});
  final String id;

  Future<void> _voidBill(BuildContext context, WidgetRef ref, PurchaseBillModel bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.block_outlined, color: Theme.of(context).colorScheme.error),
        title: Text('Void ${bill.billNumber}?'),
        content: const Text('This will cancel the bill and reverse accounting activity when allowed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep Bill')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.block_outlined),
            label: const Text('Void'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final result = await ref.read(purchaseBillsRepositoryProvider).voidBill(bill.id);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(purchaseBillDetailsProvider(bill.id));
        ref.read(purchaseBillsProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bill ${bill.billNumber} voided.')));
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Theme.of(context).colorScheme.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final billAsync = ref.watch(purchaseBillDetailsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.purchaseBills),
        actions: [
          billAsync.maybeWhen(
            data: (bill) => bill.canPay
                ? TextButton.icon(
                    onPressed: () => context.push('${AppRoutes.vendorPaymentNew}?billId=${bill.id}'),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Pay Bill'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          billAsync.maybeWhen(
            data: (bill) => bill.canVoid
                ? IconButton(
                    tooltip: 'Void bill',
                    onPressed: () => _voidBill(context, ref, bill),
                    icon: Icon(Icons.block_outlined, color: Theme.of(context).colorScheme.error),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => ref.invalidate(purchaseBillDetailsProvider(id)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: billAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (bill) => _BillDetailsBody(bill: bill),
      ),
    );
  }
}

class _BillDetailsBody extends StatelessWidget {
  const _BillDetailsBody({required this.bill});
  final PurchaseBillModel bill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
                        bill.billNumber.isEmpty ? l10n.purchaseBills : bill.billNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    _StatusChip(bill: bill),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(label: l10n.vendor, value: bill.vendorName),
                _InfoRow(label: l10n.billDate, value: fmt.format(bill.billDate)),
                _InfoRow(label: l10n.dueDate, value: fmt.format(bill.dueDate)),
                if (bill.inventoryReceiptId != null && bill.inventoryReceiptId!.isNotEmpty)
                  _InfoRow(
                    label: 'Inventory Receipt',
                    value: bill.inventoryReceiptId!,
                    isLink: true,
                    onTap: () => context.push(AppRoutes.receiveInventoryDetails.replaceFirst(':id', bill.inventoryReceiptId!)),
                  ),
                if (bill.memo != null && bill.memo!.isNotEmpty) _InfoRow(label: l10n.memoInternal, value: bill.memo!),
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
                Text(l10n.items, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const Divider(height: 20),
                if (bill.lines.isEmpty)
                  Text(l10n.noRecentTransactions)
                else
                  ...bill.lines.map((line) => _LineTile(line: line)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 360,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _AmountRow(label: l10n.subtotal, amount: bill.subtotal),
                    const SizedBox(height: 8),
                    _AmountRow(label: l10n.tax, amount: bill.taxAmount),
                    const SizedBox(height: 8),
                    _AmountRow(label: l10n.amountPaid, amount: bill.amountPaid),
                    const SizedBox(height: 8),
                    _AmountRow(label: l10n.amountDue, amount: bill.balanceDue),
                    const Divider(height: 24),
                    _AmountRow(label: l10n.total, amount: bill.totalAmount, isTotal: true),
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
  const _StatusChip({required this.bill});
  final PurchaseBillModel bill;

  @override
  Widget build(BuildContext context) {
    final label = bill.isVoid
        ? 'Void'
        : bill.isPaid
            ? 'Paid'
            : bill.isPartiallyPaid
                ? 'Partially Paid'
                : bill.isDraft
                    ? 'Draft'
                    : 'Open';
    final color = bill.isVoid
        ? Theme.of(context).colorScheme.error
        : bill.isPaid
            ? Colors.green.shade800
            : bill.isPartiallyPaid
                ? Colors.orange.shade800
                : Theme.of(context).colorScheme.primary;

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.14),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line});
  final PurchaseBillLineModel line;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(line.inventoryReceiptLineId == null ? Icons.inventory_2_outlined : Icons.link_outlined),
      title: Text(line.description.isEmpty ? line.itemName : line.description, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('Qty ${line.quantity.toStringAsFixed(2)} × ${line.unitCost.toStringAsFixed(2)}'),
      trailing: Text(line.lineTotal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900)),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).hintColor)),
            const Spacer(),
            isLink
                ? GestureDetector(
                    onTap: onTap,
                    child: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                  )
                : Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.amount, this.isTotal = false});
  final String label;
  final double amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount.toStringAsFixed(2), style: style),
      ],
    );
  }
}

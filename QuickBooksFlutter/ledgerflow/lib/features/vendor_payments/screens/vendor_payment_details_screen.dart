// vendor_payment_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../purchase_bills/providers/purchase_bills_provider.dart';
import '../data/models/vendor_payment_model.dart';
import '../providers/vendor_payments_provider.dart';

class VendorPaymentDetailsScreen extends ConsumerWidget {
  const VendorPaymentDetailsScreen({super.key, required this.id});

  final String id;

  Future<void> _voidPayment(
    BuildContext context,
    WidgetRef ref,
    VendorPaymentModel payment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.block_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text('Void ${payment.paymentNumber}?'),
        content: const Text(
          'This reverses the vendor payment and restores bill balances when allowed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Payment'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.block_outlined),
            label: const Text('Void'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(vendorPaymentsProvider.notifier)
        .voidPayment(payment.id);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(vendorPaymentDetailsProvider(payment.id));
        for (final line in payment.lines) {
          ref.invalidate(purchaseBillDetailsProvider(line.purchaseBillId));
        }
        ref.read(purchaseBillsProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vendor payment ${payment.paymentNumber} voided.'),
          ),
        );
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(vendorPaymentDetailsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Payment'),
        actions: [
          paymentAsync.maybeWhen(
            data: (payment) => payment.status == 3
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Void payment',
                    onPressed: () => _voidPayment(context, ref, payment),
                    icon: Icon(
                      Icons.block_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(vendorPaymentDetailsProvider(id)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: paymentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (payment) => _PaymentBody(payment: payment),
      ),
    );
  }
}

class _PaymentBody extends StatelessWidget {
  const _PaymentBody({required this.payment});

  final VendorPaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    final isVoid = payment.status == 3;

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
                        payment.paymentNumber.isEmpty
                            ? 'Vendor Payment'
                            : payment.paymentNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusChip(isVoid: isVoid),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(label: 'Vendor', value: payment.vendorName),
                _InfoRow(
                  label: 'Payment date',
                  value: fmt.format(payment.paymentDate),
                ),
                _InfoRow(label: 'Payment method', value: payment.paymentMethod),
                _InfoRow(
                  label: 'Payment account',
                  value: payment.paymentAccountName,
                ),
                if (payment.memo != null && payment.memo!.isNotEmpty)
                  _InfoRow(label: 'Memo', value: payment.memo!),
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
                Text(
                  'Applied bills',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Divider(height: 20),
                if (payment.lines.isEmpty)
                  const Text('No bills on this payment.')
                else
                  ...payment.lines.map((line) => _LineTile(line: line)),
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
                child: _AmountRow(
                  label: 'Amount',
                  amount: payment.amount,
                  isTotal: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line});

  final VendorPaymentLineModel line;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.receipt_long_outlined),
      title: InkWell(
        onTap: () => context.push(
          AppRoutes.purchaseBillDetails.replaceFirst(
            ':id',
            line.purchaseBillId,
          ),
        ),
        child: Text(
          line.billNumber,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      trailing: Text(
        line.amount.toStringAsFixed(2),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isVoid});
  final bool isVoid;

  @override
  Widget build(BuildContext context) {
    final color = isVoid
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Chip(
      label: Text(isVoid ? 'Void' : 'Posted'),
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

// payment_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../data/models/payment_model.dart';
import '../providers/payments_provider.dart';

class PaymentDetailsScreen extends ConsumerWidget {
  const PaymentDetailsScreen({super.key, required this.id});

  final String id;

  Future<void> _voidPayment(
    BuildContext context,
    WidgetRef ref,
    PaymentModel payment,
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
          'This reverses the customer payment and restores the invoice balance when allowed.',
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
        .read(paymentsProvider.notifier)
        .voidPayment(payment.id);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(paymentDetailsProvider(payment.id));
        ref.invalidate(invoiceDetailProvider(payment.invoiceId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment ${payment.paymentNumber} voided.')),
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
    final paymentAsync = ref.watch(paymentDetailsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Payment'),
        actions: [
          paymentAsync.maybeWhen(
            data: (payment) => payment.isVoid
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
            onPressed: () => ref.invalidate(paymentDetailsProvider(id)),
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

  final PaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                        payment.paymentNumber.isEmpty
                            ? 'Customer Payment'
                            : payment.paymentNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusChip(isVoid: payment.isVoid),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Customer',
                  value: payment.customerName ?? payment.customerId,
                ),
                _InfoRow(
                  label: 'Payment date',
                  value: fmt.format(payment.paymentDate),
                ),
                _InfoRow(label: 'Payment method', value: payment.paymentMethod),
                _InfoRow(
                  label: 'Deposit account',
                  value: payment.depositAccountName ?? payment.depositAccountId,
                ),
                _InfoRow(
                  label: 'Invoice',
                  value: payment.invoiceNumber ?? payment.invoiceId,
                  isLink: true,
                  onTap: () => context.push(
                    AppRoutes.invoiceDetails.replaceFirst(
                      ':id',
                      payment.invoiceId,
                    ),
                  ),
                ),
                if (payment.postedTransactionId != null &&
                    payment.postedTransactionId!.isNotEmpty)
                  _InfoRow(
                    label: 'Posted transaction',
                    value: payment.postedTransactionId!,
                  ),
                if (payment.reversalTransactionId != null &&
                    payment.reversalTransactionId!.isNotEmpty)
                  _InfoRow(
                    label: 'Reversal transaction',
                    value: payment.reversalTransactionId!,
                  ),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).hintColor)),
        const Spacer(),
        Flexible(
          child: isLink
              ? InkWell(
                  onTap: onTap,
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
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

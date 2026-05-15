// vendor_payment_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../purchase_bills/providers/purchase_bills_provider.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
import '../../transactions/widgets/transaction_context_sidebar.dart';
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
    final payments = ref.watch(vendorPaymentsProvider).maybeWhen(
          data: (items) => items,
          orElse: () => <VendorPaymentModel>[],
        );

    final currentIdx = payments.indexWhere((p) => p.id == id);

    void navigateTo(int idx) {
      if (idx >= 0 && idx < payments.length) {
        context.go(AppRoutes.vendorPaymentDetails.replaceFirst(':id', payments[idx].id));
      }
    }

    return paymentAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (payment) => TransactionWorkspaceShell(
        workspaceName: 'Vendor payment workspace',
        saving: false,
        posting: false,
        isEdit: true,
        readOnly: true,
        onFind: () => context.go(AppRoutes.vendorPayments),
        onPrevious: currentIdx > 0 ? () => navigateTo(currentIdx - 1) : null,
        onNext: currentIdx < payments.length - 1 && currentIdx != -1
            ? () => navigateTo(currentIdx + 1)
            : null,
        onNew: () => context.go(AppRoutes.vendorPaymentNew),
        onVoid: payment.status == 3 ? null : () => _voidPayment(context, ref, payment),
        onClose: () => context.go(AppRoutes.vendorPayments),
        formContent: _PaymentBody(payment: payment),
        contextPanel: _PaymentContextPanel(
          total: payment.amount,
          currency: 'EGP',
          onViewAll: () => context.go(AppRoutes.purchaseBills),
        ),
      ),
    );
  }
}

class _PaymentContextPanel extends StatelessWidget {
  const _PaymentContextPanel({
    required this.total,
    required this.currency,
    this.onViewAll,
  });

  final double total;
  final String currency;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
            color: const Color(0xFF264D5B),
            child: Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SidebarStat(
                  label: 'TOTAL AMOUNT',
                  value: '${total.toStringAsFixed(2)} $currency',
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarStat extends StatelessWidget {
  const _SidebarStat({required this.label, required this.value, this.isTotal = false});
  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7D8B93), fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700, color: const Color(0xFF264D5B))),
        ],
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

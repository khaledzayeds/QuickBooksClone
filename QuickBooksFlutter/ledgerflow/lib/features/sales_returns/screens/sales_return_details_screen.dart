// sales_return_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../data/models/sales_return_model.dart';
import '../providers/sales_returns_provider.dart';

class SalesReturnDetailsScreen extends ConsumerWidget {
  const SalesReturnDetailsScreen({super.key, required this.id});

  final String id;

  Future<void> _voidReturn(
    BuildContext context,
    WidgetRef ref,
    SalesReturnModel salesReturn,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.block_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text('Void ${salesReturn.returnNumber}?'),
        content: const Text(
          'This reverses the sales return accounting and inventory effect when allowed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Return'),
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
        .read(salesReturnsProvider.notifier)
        .voidReturn(salesReturn.id);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(salesReturnDetailsProvider(salesReturn.id));
        ref.invalidate(invoiceDetailProvider(salesReturn.invoiceId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sales return ${salesReturn.returnNumber} voided.'),
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
    final salesReturnAsync = ref.watch(salesReturnDetailsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Return'),
        actions: [
          salesReturnAsync.maybeWhen(
            data: (salesReturn) => salesReturn.isVoid
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Void return',
                    onPressed: () => _voidReturn(context, ref, salesReturn),
                    icon: Icon(
                      Icons.block_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(salesReturnDetailsProvider(id)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: salesReturnAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (salesReturn) => _DetailsBody(salesReturn: salesReturn),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.salesReturn});

  final SalesReturnModel salesReturn;

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
                        salesReturn.returnNumber.isEmpty
                            ? 'Sales Return'
                            : salesReturn.returnNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusChip(isVoid: salesReturn.isVoid),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Customer',
                  value: salesReturn.customerName ?? salesReturn.customerId,
                ),
                _InfoRow(
                  label: 'Return date',
                  value: fmt.format(salesReturn.returnDate),
                ),
                _InfoRow(
                  label: 'Invoice',
                  value: salesReturn.invoiceNumber ?? salesReturn.invoiceId,
                  isLink: true,
                  onTap: () => context.push(
                    AppRoutes.invoiceDetails.replaceFirst(
                      ':id',
                      salesReturn.invoiceId,
                    ),
                  ),
                ),
                if (salesReturn.postedTransactionId != null &&
                    salesReturn.postedTransactionId!.isNotEmpty)
                  _InfoRow(
                    label: 'Posted transaction',
                    value: salesReturn.postedTransactionId!,
                  ),
                if (salesReturn.reversalTransactionId != null &&
                    salesReturn.reversalTransactionId!.isNotEmpty)
                  _InfoRow(
                    label: 'Reversal transaction',
                    value: salesReturn.reversalTransactionId!,
                  ),
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
                  'Returned lines',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Divider(height: 20),
                if (salesReturn.lines.isEmpty)
                  const Text('No lines on this sales return.')
                else
                  ...salesReturn.lines.map((line) => _LineTile(line: line)),
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
                  label: 'Total returned',
                  amount: salesReturn.totalAmount,
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

  final SalesReturnLineModel line;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.assignment_return_outlined),
      title: Text(
        line.description,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        'Qty ${line.quantity.toStringAsFixed(2)} x ${line.unitPrice.toStringAsFixed(2)}',
      ),
      trailing: Text(
        line.lineTotal.toStringAsFixed(2),
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

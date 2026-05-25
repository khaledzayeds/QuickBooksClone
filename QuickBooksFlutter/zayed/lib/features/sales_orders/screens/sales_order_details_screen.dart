// sales_order_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_result.dart';
import '../../invoices/providers/invoices_provider.dart' as invoices;
import '../data/models/sales_order_model.dart';
import '../providers/sales_orders_provider.dart';

class SalesOrderDetailsScreen extends ConsumerWidget {
  const SalesOrderDetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(salesOrderDetailsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Order'),
        actions: [
          orderAsync.maybeWhen(
            data: (order) => _SalesOrderActions(order: order),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(salesOrderDetailsProvider(id)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (order) => _DetailsBody(order: order),
      ),
    );
  }
}

class _SalesOrderActions extends ConsumerWidget {
  const _SalesOrderActions({required this.order});

  final SalesOrderModel order;

  Future<void> _runAction<T>(
    BuildContext context,
    WidgetRef ref,
    String label,
    Future<ApiResult<T>> Function() action,
  ) async {
    final result = await action();
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(salesOrderDetailsProvider(order.id));
        ref.invalidate(invoices.invoicesProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(label)));
      },
      failure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (order.isCancelled) return const SizedBox.shrink();
    final notifier = ref.read(salesOrdersProvider.notifier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!order.isOpen && !order.isClosed)
          TextButton(
            onPressed: () => _runAction(
              context,
              ref,
              'Sales order opened.',
              () => notifier.open(order.id),
            ),
            child: const Text('Open'),
          ),
        if (order.isOpen)
          TextButton(
            onPressed: () => _runAction(
              context,
              ref,
              'Sales order closed.',
              () => notifier.close(order.id),
            ),
            child: const Text('Close'),
          ),
        if (!order.isClosed)
          TextButton(
            onPressed: () => _runAction(
              context,
              ref,
              'Invoice created.',
              () => notifier.convertToInvoice(order.id),
            ),
            child: const Text('Create invoice'),
          ),
        if (!order.isClosed)
          IconButton(
            tooltip: 'Cancel sales order',
            onPressed: () => _runAction(
              context,
              ref,
              'Sales order cancelled.',
              () => notifier.cancel(order.id),
            ),
            icon: Icon(
              Icons.block_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.order});
  final SalesOrderModel order;

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
                        order.orderNumber.isEmpty
                            ? 'Sales Order'
                            : order.orderNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusChip(label: _statusLabel(order)),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Customer',
                  value: order.customerName ?? order.customerId,
                ),
                _InfoRow(
                  label: 'Order date',
                  value: fmt.format(order.orderDate),
                ),
                _InfoRow(
                  label: 'Expected date',
                  value: fmt.format(order.expectedDate),
                ),
                if (order.estimateId != null && order.estimateId!.isNotEmpty)
                  _InfoRow(label: 'Source estimate', value: order.estimateId!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _LinesCard(lines: order.lines),
        const SizedBox(height: 16),
        _TotalsCard(
          subtotal: order.subtotal,
          taxAmount: order.taxAmount,
          totalAmount: order.totalAmount,
        ),
      ],
    );
  }

  static String _statusLabel(SalesOrderModel order) {
    if (order.isCancelled) return 'Cancelled';
    if (order.isClosed) return 'Closed';
    if (order.isOpen) return 'Open';
    return 'Draft';
  }
}

class _LinesCard extends StatelessWidget {
  const _LinesCard({required this.lines});
  final List<SalesOrderLineModel> lines;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lines',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Divider(height: 20),
          if (lines.isEmpty)
            const Text('No lines.')
          else
            ...lines.map((line) => _LineTile(line: line)),
        ],
      ),
    ),
  );
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line});
  final SalesOrderLineModel line;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = label == 'Cancelled'
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Chip(
      label: Text(label),
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

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
  });
  final double subtotal;
  final double taxAmount;
  final double totalAmount;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: SizedBox(
      width: 360,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _AmountRow(label: 'Subtotal', amount: subtotal),
              const SizedBox(height: 8),
              _AmountRow(label: 'Tax', amount: taxAmount),
              const Divider(height: 24),
              _AmountRow(label: 'Total', amount: totalAmount, isTotal: true),
            ],
          ),
        ),
      ),
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

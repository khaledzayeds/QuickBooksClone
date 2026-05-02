// sales_receipt_details_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../providers/sales_receipts_state.dart';

class SalesReceiptDetailsPage extends ConsumerWidget {
  const SalesReceiptDetailsPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final receiptAsync = ref.watch(salesReceiptDetailsStateProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salesReceiptDetails),
        actions: [
          IconButton(
            tooltip: l10n.salesReceipts,
            onPressed: () => context.go(AppRoutes.salesReceipts),
            icon: const Icon(Icons.list_alt),
          ),
        ],
      ),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (receipt) => _DetailsBody(receipt: receipt),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.receipt});

  final SalesReceiptModel receipt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: receipt.isVoid ? cs.errorContainer : cs.primaryContainer,
                      child: Icon(
                        receipt.isVoid ? Icons.block : Icons.point_of_sale,
                        color: receipt.isVoid ? cs.onErrorContainer : cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.receiptNumber.isEmpty ? l10n.salesReceipt : receipt.receiptNumber,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            receipt.customerName.isEmpty ? l10n.customer : receipt.customerName,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(isVoid: receipt.isVoid),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _InfoTile(label: l10n.receiptDate, value: _formatDate(receipt.receiptDate)),
                    _InfoTile(label: l10n.paymentMethod, value: receipt.paymentMethod ?? '-'),
                    _InfoTile(label: l10n.depositAccount, value: receipt.depositAccountName ?? '-'),
                    _InfoTile(label: l10n.total, value: '${receipt.totalAmount.toStringAsFixed(2)} ${l10n.egp}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.items, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                _LinesTable(lines: receipt.lines),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _TotalsCard(receipt: receipt),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isVoid});

  final bool isVoid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Chip(
      label: Text(isVoid ? l10n.statusCancelled : l10n.paid),
      backgroundColor: isVoid ? cs.errorContainer : cs.primaryContainer,
      labelStyle: TextStyle(color: isVoid ? cs.onErrorContainer : cs.onPrimaryContainer),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _LinesTable extends StatelessWidget {
  const _LinesTable({required this.lines});

  final List<SalesReceiptLineModel> lines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (lines.isEmpty) return Text(l10n.noRecentTransactions);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(l10n.description)),
          DataColumn(label: Text(l10n.qty), numeric: true),
          DataColumn(label: Text(l10n.rate), numeric: true),
          DataColumn(label: Text(l10n.tax), numeric: true),
          DataColumn(label: Text(l10n.amount), numeric: true),
        ],
        rows: lines
            .map(
              (line) => DataRow(
                cells: [
                  DataCell(Text(line.description)),
                  DataCell(Text(line.quantity.toStringAsFixed(2))),
                  DataCell(Text(line.unitPrice.toStringAsFixed(2))),
                  DataCell(Text(line.taxAmount.toStringAsFixed(2))),
                  DataCell(Text(
                    line.lineTotal.toStringAsFixed(2),
                    style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary),
                  )),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.receipt});

  final SalesReceiptModel receipt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 320,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _AmountRow(label: l10n.subtotal, amount: receipt.subtotal),
              const SizedBox(height: 8),
              _AmountRow(label: l10n.tax, amount: receipt.taxAmount),
              const SizedBox(height: 8),
              _AmountRow(label: l10n.amountPaid, amount: receipt.paidAmount),
              const Divider(height: 24),
              _AmountRow(label: l10n.total, amount: receipt.totalAmount, isTotal: true),
            ],
          ),
        ),
      ),
    );
  }
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
        : Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount.toStringAsFixed(2), style: style),
      ],
    );
  }
}

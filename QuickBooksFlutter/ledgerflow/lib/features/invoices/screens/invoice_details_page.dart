// invoice_details_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../../printing/widgets/document_print_preview_dialog.dart';
import '../data/models/invoice_contracts.dart';
import '../providers/invoices_state.dart';

class InvoiceDetailsPage extends ConsumerWidget {
  const InvoiceDetailsPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final invoiceAsync = ref.watch(invoiceDetailsStateProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoices),
        actions: [
          IconButton(
            tooltip: 'Print preview',
            onPressed: () => showDocumentPrintPreviewDialog(
              context: context,
              ref: ref,
              documentType: 'invoice',
              documentId: id,
            ),
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: l10n.invoices,
            onPressed: () => context.go(AppRoutes.invoices),
            icon: const Icon(Icons.list_alt),
          ),
        ],
      ),
      body: invoiceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (invoice) => _DetailsBody(invoice: invoice),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.invoice});

  final InvoiceModel invoice;

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
                      backgroundColor: _statusColor(cs).withValues(alpha: 0.16),
                      child: Icon(_statusIcon, color: _statusColor(cs)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber.isEmpty ? l10n.invoices : invoice.invoiceNumber,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            invoice.customerName.isEmpty ? l10n.customer : invoice.customerName,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(invoice: invoice),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _InfoTile(label: l10n.billDate, value: _formatDate(invoice.invoiceDate)),
                    _InfoTile(label: l10n.dueDate, value: _formatDate(invoice.dueDate)),
                    _InfoTile(label: l10n.total, value: '${invoice.totalAmount.toStringAsFixed(2)} ${l10n.egp}'),
                    _InfoTile(label: l10n.amountDue, value: '${invoice.balanceDue.toStringAsFixed(2)} ${l10n.egp}'),
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
                _LinesTable(lines: invoice.lines),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _TotalsCard(invoice: invoice),
        ),
      ],
    );
  }

  IconData get _statusIcon {
    if (invoice.isVoid) return Icons.block;
    if (invoice.isPaid) return Icons.check_circle_outline;
    if (invoice.isPartiallyPaid) return Icons.timelapse;
    return Icons.receipt_long_outlined;
  }

  Color _statusColor(ColorScheme cs) {
    if (invoice.isVoid) return cs.error;
    if (invoice.isPaid) return cs.primary;
    if (invoice.isPartiallyPaid) return Colors.orange.shade800;
    return cs.secondary;
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.invoice});

  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final label = _statusLabel(l10n);
    final color = _statusColor(cs);

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.16),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }

  Color _statusColor(ColorScheme cs) {
    if (invoice.isVoid) return cs.error;
    if (invoice.isPaid) return cs.primary;
    if (invoice.isPartiallyPaid) return Colors.orange.shade800;
    return cs.secondary;
  }

  String _statusLabel(AppLocalizations l10n) {
    if (invoice.isVoid) return l10n.statusCancelled;
    if (invoice.isPaid) return l10n.statusPaid;
    if (invoice.isPartiallyPaid) return l10n.statusPartiallyPaid;
    if (invoice.isDraft) return l10n.statusDraft;
    return l10n.statusOpen;
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

  final List<InvoiceLineModel> lines;

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
  const _TotalsCard({required this.invoice});

  final InvoiceModel invoice;

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
              _AmountRow(label: l10n.subtotal, amount: invoice.subtotal),
              const SizedBox(height: 8),
              _AmountRow(label: l10n.tax, amount: invoice.taxAmount),
              const SizedBox(height: 8),
              _AmountRow(label: l10n.amountPaid, amount: invoice.paidAmount),
              const SizedBox(height: 8),
              _AmountRow(label: l10n.amountDue, amount: invoice.balanceDue),
              const Divider(height: 24),
              _AmountRow(label: l10n.total, amount: invoice.totalAmount, isTotal: true),
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

// invoices_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../data/models/invoice_contracts.dart';
import '../providers/invoices_state.dart';

class InvoicesListPage extends ConsumerWidget {
  const InvoicesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final invoicesAsync = ref.watch(invoicesStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoices),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => ref.read(invoicesStateProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.invoiceNew),
              icon: const Icon(Icons.add),
              label: Text(l10n.newText),
            ),
          ),
        ],
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(invoicesStateProvider.notifier).refresh(),
        ),
        data: (invoices) {
          if (invoices.isEmpty) return _EmptyState(l10n: l10n);
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _InvoiceCard(invoice: invoices[index]),
          );
        },
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/sales/invoices/${invoice.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.customerName.isEmpty ? l10n.customer : invoice.customerName,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(invoice.invoiceDate)} • ${l10n.dueDate}: ${_formatDate(invoice.dueDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${invoice.totalAmount.toStringAsFixed(2)} ${l10n.egp}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.amountDue}: ${invoice.balanceDue.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: invoice.balanceDue > 0 ? cs.error : cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusLabel(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(color: _statusColor(cs)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  String _statusLabel(AppLocalizations l10n) {
    if (invoice.isVoid) return l10n.statusCancelled;
    if (invoice.isPaid) return l10n.statusPaid;
    if (invoice.isPartiallyPaid) return l10n.statusPartiallyPaid;
    if (invoice.isDraft) return l10n.statusDraft;
    return l10n.statusOpen;
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 56),
            const SizedBox(height: 16),
            Text(l10n.invoices, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.creditSale, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.invoiceNew),
              icon: const Icon(Icons.add),
              label: Text(l10n.createInvoice),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

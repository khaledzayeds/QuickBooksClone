// invoice_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/invoice_model.dart';
import '../providers/invoices_provider.dart';

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('فواتير البيع الآجل'),
        actions: [
          AppButton(
            label: 'فاتورة جديدة',
            icon: Icons.add_outlined,
            onPressed: () => context.go(AppRoutes.invoiceNew),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: invoicesAsync.when(
        loading: () => const SkeletonList(),
        error: (error, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          message: 'تعذر تحميل الفواتير',
          description: error.toString(),
          actionLabel: 'إعادة المحاولة',
          onAction: () => ref.read(invoicesProvider.notifier).refresh(),
        ),
        data: (invoices) => invoices.isEmpty
            ? EmptyStateWidget(
                icon: Icons.receipt_long_outlined,
                message: 'لا توجد فواتير بيع آجل',
                description: 'ابدأ بإنشاء فاتورة جديدة للعميل',
                actionLabel: 'فاتورة جديدة',
                onAction: () => context.go(AppRoutes.invoiceNew),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(invoicesProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: invoices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _InvoiceCard(invoice: invoices[index]),
                ),
              ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice});

  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final date = _dateOnly(invoice.invoiceDate);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primary.withValues(alpha: 0.1),
          child: Icon(Icons.description_outlined, color: cs.primary),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                invoice.invoiceNumber.isEmpty ? 'فاتورة بدون رقم' : invoice.invoiceNumber,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            _StatusChip(status: invoice.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(invoice.customerName ?? 'عميل غير محدد'),
              const SizedBox(height: 4),
              Text('التاريخ: $date  •  المتبقي: ${invoice.balanceDue.toStringAsFixed(2)} ج.م'),
            ],
          ),
        ),
        trailing: Text(
          '${invoice.totalAmount.toStringAsFixed(2)} ج.م',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  static String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (status) {
      InvoiceStatus.paid => Colors.green,
      InvoiceStatus.partiallyPaid => Colors.orange,
      InvoiceStatus.voided => cs.error,
      InvoiceStatus.posted => cs.primary,
      _ => cs.outline,
    };

    return Chip(
      label: Text(status.label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.08),
      labelStyle: TextStyle(color: color),
    );
  }
}

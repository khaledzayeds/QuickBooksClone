// customer_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/customer_model.dart';
import '../providers/customers_provider.dart';

class CustomerDetailsScreen extends ConsumerWidget {
  const CustomerDetailsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          customerAsync.whenData((c) => AppButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go(AppRoutes.customerEdit.replaceFirst(':id', id)),
              )).value ??
              const SizedBox.shrink(),
          const SizedBox(width: 12),
        ],
      ),
      body: customerAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (customer) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _HeaderCard(customer: customer),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final left = Column(
                  children: [
                    _BalancesCard(customer: customer),
                    const SizedBox(height: 16),
                    _ContactCard(customer: customer),
                  ],
                );
                final right = Column(
                  children: [
                    _QuickActionsCard(customer: customer),
                    const SizedBox(height: 16),
                    _FutureActivityCard(customer: customer),
                  ],
                );

                if (!wide) return Column(children: [left, const SizedBox(height: 16), right]);
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 16), Expanded(child: right)]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: cs.primaryContainer,
              child: Text(customer.initials, style: theme.textTheme.headlineSmall?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.displayName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  if (customer.companyName?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(customer.companyName!, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(customer.isActive ? 'Active' : 'Inactive'), avatar: Icon(customer.isActive ? Icons.check_circle_outline : Icons.block_outlined, size: 18)),
                      Chip(label: Text(customer.currency), avatar: const Icon(Icons.attach_money_outlined, size: 18)),
                      if (customer.hasBalance) const Chip(label: Text('Open balance'), avatar: Icon(Icons.receipt_long_outlined, size: 18)),
                      if (customer.hasCreditBalance) const Chip(label: Text('Has credits'), avatar: Icon(Icons.credit_score_outlined, size: 18)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Customer record for invoices, receipts, credits, statements, and sales reports.', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalancesCard extends StatelessWidget {
  const _BalancesCard({required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Balances',
      children: [
        _MetricGrid(metrics: [
          _MetricData('Open balance', '${customer.balance.toStringAsFixed(2)} ${customer.currency}', Icons.receipt_long_outlined),
          _MetricData('Credit balance', '${customer.creditBalance.toStringAsFixed(2)} ${customer.currency}', Icons.credit_score_outlined),
          _MetricData('Net receivable', '${customer.netReceivable.toStringAsFixed(2)} ${customer.currency}', Icons.account_balance_outlined),
        ]),
        if (customer.balance > 0) ...[
          const SizedBox(height: 12),
          const _InfoBox(icon: Icons.info_outline, text: 'Customer has an open balance. Receive Payment and Customer Statement actions will use this balance later.'),
        ],
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.contact_mail_outlined,
      title: 'Contact information',
      children: [
        _InfoRow(label: 'Email', value: customer.email ?? '-'),
        _InfoRow(label: 'Phone', value: customer.phone ?? '-'),
        _InfoRow(label: 'Company', value: customer.companyName ?? '-'),
        _InfoRow(label: 'Currency', value: customer.currency),
        _InfoRow(label: 'Customer ID', value: customer.id),
        if (!customer.hasContactInfo) ...[
          const SizedBox(height: 12),
          const _InfoBox(icon: Icons.warning_amber_outlined, text: 'No phone or email is saved for this customer. Add contact information before using statement or notification workflows.'),
        ],
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.flash_on_outlined,
      title: 'Quick actions',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            AppButton(
              label: 'Create invoice',
              icon: Icons.description_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go('${AppRoutes.invoiceNew}?customerId=${customer.id}'),
            ),
            AppButton(
              label: 'Receive payment',
              icon: Icons.account_balance_wallet_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go('${AppRoutes.paymentNew}?customerId=${customer.id}'),
            ),
            AppButton(
              label: 'Edit customer',
              icon: Icons.edit_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(AppRoutes.customerEdit.replaceFirst(':id', customer.id)),
            ),
          ],
        ),
      ],
    );
  }
}

class _FutureActivityCard extends StatelessWidget {
  const _FutureActivityCard({required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.history_outlined,
      title: 'Related activity',
      children: const [
        _InfoBox(
          icon: Icons.pending_actions_outlined,
          text: 'Customer activity will later show invoices, sales receipts, payments, customer credits, sales returns, and statement history after transaction screens are polished.',
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.children});
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [CircleAvatar(backgroundColor: cs.primaryContainer, child: Icon(icon, color: cs.onPrimaryContainer)), const SizedBox(width: 12), Expanded(child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)))]),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 12, runSpacing: 12, children: metrics.map((metric) => _MetricCard(metric: metric)).toList());
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(metric.icon, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(metric.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)), const SizedBox(height: 4), Text(metric.value, style: const TextStyle(fontWeight: FontWeight.w900))])),
      ]),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: Text(label, style: TextStyle(color: cs.onSurfaceVariant))), Expanded(child: SelectableText(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w700)))]),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: cs.onSecondaryContainer), const SizedBox(width: 10), Expanded(child: Text(text, style: TextStyle(color: cs.onSecondaryContainer)))]),
    );
  }
}

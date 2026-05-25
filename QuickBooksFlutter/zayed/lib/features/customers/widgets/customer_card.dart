// customer_card.dart

import 'package:flutter/material.dart';
import '../data/models/customer_model.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
    this.onEdit,
    this.onToggleActive,
  });

  final CustomerModel customer;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: cs.primary.withValues(alpha: 0.10),
                child: Text(
                  customer.initials,
                  style: theme.textTheme.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: customer.isActive ? null : theme.disabledColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (customer.needsAttention)
                          Tooltip(
                            message: 'Customer has open balance',
                            child: Icon(Icons.warning_amber_outlined, color: cs.error, size: 20),
                          ),
                      ],
                    ),
                    if (customer.companyName?.isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(customer.companyName!, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniChip(label: customer.isActive ? 'Active' : 'Inactive', icon: customer.isActive ? Icons.check_circle_outline : Icons.block_outlined),
                        _MiniChip(label: customer.currency, icon: Icons.attach_money_outlined),
                        if (customer.phone?.isNotEmpty == true) _MiniChip(label: customer.phone!, icon: Icons.phone_outlined),
                        if (customer.email?.isNotEmpty == true) _MiniChip(label: customer.email!, icon: Icons.email_outlined),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _Metric(label: 'Open balance', value: '${customer.balance.toStringAsFixed(2)} ${customer.currency}'),
                        _Metric(label: 'Credit balance', value: '${customer.creditBalance.toStringAsFixed(2)} ${customer.currency}'),
                        _Metric(label: 'Net receivable', value: '${customer.netReceivable.toStringAsFixed(2)} ${customer.currency}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                  if (onToggleActive != null)
                    IconButton(
                      icon: Icon(
                        customer.isActive ? Icons.toggle_on_outlined : Icons.toggle_off_outlined,
                        color: customer.isActive ? cs.primary : theme.disabledColor,
                      ),
                      onPressed: onToggleActive,
                      tooltip: customer.isActive ? 'Make inactive' : 'Make active',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: cs.primary), const SizedBox(width: 4), Text(label, style: Theme.of(context).textTheme.labelSmall)]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(text: '$label: ', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

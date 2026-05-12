import 'package:flutter/material.dart';

import '../../customers/data/models/customer_model.dart';

class InvoiceHeaderPanel extends StatelessWidget {
  const InvoiceHeaderPanel({
    super.key,
    required this.customerField,
    required this.invoiceNumberField,
    required this.invoiceDateField,
    required this.dueDateField,
    required this.billingTermsField,
    required this.memoField,
    this.customer,
  });

  final Widget customerField;
  final Widget invoiceNumberField;
  final Widget invoiceDateField;
  final Widget dueDateField;
  final Widget billingTermsField;
  final Widget memoField;
  final CustomerModel? customer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.surface,
      child: Column(
        children: [
          Container(
            height: 42,
            color: cs.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 360, child: customerField),
                const SizedBox(width: 18),
                Text(
                  'Template',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 30,
                  constraints: const BoxConstraints(minWidth: 170),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Standard invoice',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 230,
                  child: Text(
                    'Invoice',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: cs.onSurface,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(width: 142, child: invoiceDateField),
                const SizedBox(width: 12),
                SizedBox(width: 142, child: invoiceNumberField),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 230,
                  child: _BillToBox(customer: customer),
                ),
                const Spacer(),
                SizedBox(width: 140, child: dueDateField),
                const SizedBox(width: 12),
                SizedBox(width: 130, child: billingTermsField),
                const SizedBox(width: 12),
                SizedBox(width: 270, child: memoField),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillToBox extends StatelessWidget {
  const _BillToBox({required this.customer});

  final CustomerModel? customer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final lines = <String>[
      if (customer?.displayName.trim().isNotEmpty == true) customer!.displayName,
      if (customer?.companyName?.trim().isNotEmpty == true) customer!.companyName!,
      if (customer?.phone?.trim().isNotEmpty == true) customer!.phone!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BILL TO', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          height: 86,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: lines.isEmpty
              ? Text('Select a customer', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lines.take(3).map((line) => Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)).toList(),
                ),
        ),
      ],
    );
  }
}

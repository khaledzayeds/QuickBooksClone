import 'package:flutter/material.dart';

class InvoiceHeaderPanel extends StatelessWidget {
  const InvoiceHeaderPanel({
    super.key,
    required this.customerField,
    required this.invoiceNumberField,
    required this.invoiceDateField,
    required this.dueDateField,
    required this.billingTermsField,
    required this.memoField,
  });

  final Widget customerField;
  final Widget invoiceNumberField;
  final Widget invoiceDateField;
  final Widget dueDateField;
  final Widget billingTermsField;
  final Widget memoField;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 3, child: customerField),
              const SizedBox(width: 12),
              SizedBox(width: 140, child: invoiceNumberField),
              const SizedBox(width: 12),
              SizedBox(width: 140, child: invoiceDateField),
              const SizedBox(width: 12),
              SizedBox(width: 140, child: dueDateField),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(width: 180, child: billingTermsField),
              const SizedBox(width: 12),
              Expanded(child: memoField),
            ],
          ),
        ],
      ),
    );
  }
}

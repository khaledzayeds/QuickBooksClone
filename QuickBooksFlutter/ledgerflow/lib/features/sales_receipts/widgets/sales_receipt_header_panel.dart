import 'package:flutter/material.dart';

class SalesReceiptHeaderPanel extends StatelessWidget {
  const SalesReceiptHeaderPanel({
    super.key,
    required this.numberField,
    required this.dateField,
    required this.referenceField,
    required this.customerField,
    required this.depositAccountField,
    required this.paymentMethodField,
  });

  final Widget numberField;
  final Widget dateField;
  final Widget referenceField;
  final Widget customerField;
  final Widget depositAccountField;
  final Widget paymentMethodField;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 130, child: numberField),
              const SizedBox(width: 12),
              SizedBox(width: 140, child: dateField),
              const SizedBox(width: 12),
              Expanded(child: referenceField),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(flex: 3, child: customerField),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: depositAccountField),
              const SizedBox(width: 12),
              SizedBox(width: 160, child: paymentMethodField),
            ],
          ),
        ],
      ),
    );
  }
}

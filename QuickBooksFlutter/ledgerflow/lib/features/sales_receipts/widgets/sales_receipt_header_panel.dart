import 'package:flutter/material.dart';

import '../../customers/data/models/customer_model.dart';

class SalesReceiptHeaderPanel extends StatelessWidget {
  const SalesReceiptHeaderPanel({
    super.key,
    required this.numberField,
    required this.dateField,
    required this.referenceField,
    required this.customerField,
    required this.depositAccountField,
    required this.paymentMethodField,
    this.customer,
  });

  final Widget numberField;
  final Widget dateField;
  final Widget referenceField;
  final Widget customerField;
  final Widget depositAccountField;
  final Widget paymentMethodField;
  final CustomerModel? customer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerName = customer?.displayName.trim();

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF264D5B),
              border: Border(bottom: BorderSide(color: Color(0xFF183642))),
            ),
            child: Row(
              children: [
                const _StripLabel('CUSTOMER:JOB'),
                const SizedBox(width: 8),
                Expanded(flex: 5, child: SizedBox(height: 30, child: customerField)),
                const SizedBox(width: 16),
                const _StripLabel('TEMPLATE'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF9BAAB2)),
                    ),
                    child: Text(
                      'Standard Sales Receipt',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF263C46),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 146,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 230,
                    child: Text(
                      'Sales Receipt',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF243E4A),
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: Column(
                      children: [
                        _HorizontalField(label: 'DATE', child: dateField),
                        const SizedBox(height: 8),
                        _HorizontalField(label: 'RECEIPT #', child: numberField),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('RECEIVED FROM'),
                        const SizedBox(height: 4),
                        Container(
                          height: 96,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFB7C3CB)),
                          ),
                          child: Text(
                            customerName == null || customerName.isEmpty ? 'Select a customer' : customerName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: customerName == null || customerName.isEmpty ? const Color(0xFF7B8B93) : const Color(0xFF253C47),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _StackedField(label: 'PAYMENT', child: paymentMethodField)),
                            const SizedBox(width: 10),
                            Expanded(child: _StackedField(label: 'REF / MEMO', child: referenceField)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _StackedField(label: 'DEPOSIT ACCOUNT', child: depositAccountField),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripLabel extends StatelessWidget {
  const _StripLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: const Color(0xFF53656E),
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _HorizontalField extends StatelessWidget {
  const _HorizontalField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 82, child: _FieldLabel(label)),
        Expanded(child: SizedBox(height: 34, child: child)),
      ],
    );
  }
}

class _StackedField extends StatelessWidget {
  const _StackedField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 4),
        SizedBox(height: 34, child: child),
      ],
    );
  }
}

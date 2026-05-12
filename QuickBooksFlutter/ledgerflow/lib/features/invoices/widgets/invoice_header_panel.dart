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
                _StripLabel('CUSTOMER:JOB'),
                const SizedBox(width: 8),
                SizedBox(width: 360, height: 30, child: customerField),
                const SizedBox(width: 22),
                _StripLabel('TEMPLATE'),
                const SizedBox(width: 8),
                Container(
                  width: 230,
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF9BAAB2)),
                  ),
                  child: Text(
                    'Custom Sales Receipt Intuit S...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF263C46),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'QuickBooks Desktop Style',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFDDE8EC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 164,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 220,
                    child: Text(
                      'Invoice',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF243E4A),
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: Column(
                      children: [
                        _HorizontalField(label: 'DATE', child: invoiceDateField),
                        const SizedBox(height: 8),
                        _HorizontalField(label: 'INVOICE #', child: invoiceNumberField),
                      ],
                    ),
                  ),
                  const SizedBox(width: 28),
                  SizedBox(width: 250, child: _BillToBox(customer: customer)),
                  const Spacer(),
                  SizedBox(
                    width: 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _StackedField(label: 'P.O. NO.', child: _StaticBox(text: ''))),
                            const SizedBox(width: 10),
                            Expanded(child: _StackedField(label: 'TERMS', child: billingTermsField)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _StackedField(label: 'DUE DATE', child: dueDateField),
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

class _HorizontalField extends StatelessWidget {
  const _HorizontalField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF53656E),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
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
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF53656E),
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        SizedBox(height: 34, child: child),
      ],
    );
  }
}

class _StaticBox extends StatelessWidget {
  const _StaticBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7C3CB)),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _BillToBox extends StatelessWidget {
  const _BillToBox({required this.customer});

  final CustomerModel? customer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = <String>[
      if (customer?.displayName.trim().isNotEmpty == true) customer!.displayName,
      if (customer?.companyName?.trim().isNotEmpty == true) customer!.companyName!,
      if (customer?.phone?.trim().isNotEmpty == true) customer!.phone!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BILL TO',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF53656E),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 104,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFB7C3CB)),
          ),
          child: lines.isEmpty
              ? Text(
                  'Select a customer',
                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7B8B93)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lines
                      .take(4)
                      .map(
                        (line) => Text(
                          line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF253C47),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

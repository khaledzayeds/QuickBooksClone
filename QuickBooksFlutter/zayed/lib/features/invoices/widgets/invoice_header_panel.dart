import 'package:flutter/material.dart';

import '../../customers/data/models/customer_model.dart';
import '../../../core/widgets/qb/qb_widgets.dart';

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
                const QbStripLabel('CUSTOMER:JOB'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: SizedBox(height: 30, child: customerField),
                ),
                const SizedBox(width: 16),
                const QbStripLabel('TEMPLATE'),
                const SizedBox(width: 8),
                const Expanded(
                  flex: 3,
                  child: QbStaticBox(text: 'Standard Invoice'),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 166),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 900;
                  final tight = constraints.maxWidth < 760;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: tight
                            ? 112
                            : compact
                            ? 150
                            : 210,
                        child: Text(
                          'Invoice',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF243E4A),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: tight
                            ? 206
                            : compact
                            ? 230
                            : 260,
                        child: Column(
                          children: [
                            QbHorizontalField(
                              label: 'DATE',
                              labelWidth: 74,
                              child: invoiceDateField,
                            ),
                            const SizedBox(height: 8),
                            QbHorizontalField(
                              label: 'INVOICE #',
                              labelWidth: 74,
                              child: invoiceNumberField,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: tight ? 12 : 20),
                      Expanded(flex: 4, child: _BillToBox(customer: customer)),
                      SizedBox(width: tight ? 12 : 20),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: QbStackedField(
                                    label: 'P.O. NO.',
                                    child: const QbStaticBox(text: ''),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: QbStackedField(
                                    label: 'TERMS',
                                    child: billingTermsField,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            QbStackedField(
                              label: 'DUE DATE',
                              child: dueDateField,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
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
    final lines = <String>[
      if (customer?.displayName.trim().isNotEmpty == true)
        customer!.displayName,
      if (customer?.companyName?.trim().isNotEmpty == true)
        customer!.companyName!,
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
          height: 96,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFB7C3CB)),
          ),
          child: lines.isEmpty
              ? Text(
                  'Select a customer',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7B8B93),
                  ),
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

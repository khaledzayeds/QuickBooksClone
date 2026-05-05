import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../printing/data/models/print_data_contracts.dart';
import '../../printing/services/a4_document_pdf_service.dart';
import '../../printing/services/thermal_document_pdf_service.dart';
import '../data/models/printing_settings_model.dart';

class PrintingTestPreviewCard extends StatelessWidget {
  const PrintingTestPreviewCard({super.key, required this.settings});

  final PrintingSettingsModel settings;

  bool get _a4Enabled => settings.printMode == PrintMode.a4 || settings.printMode == PrintMode.both;
  bool get _thermalEnabled => settings.printMode == PrintMode.thermal || settings.printMode == PrintMode.both;

  Future<void> _testA4(BuildContext context) async {
    try {
      final data = _sampleData();
      const service = A4DocumentPdfService();
      await Printing.layoutPdf(
        name: 'printing-settings-test-a4.pdf',
        onLayout: (_) => service.build(data, settings),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('A4 test failed: $error')));
      }
    }
  }

  Future<void> _testThermal(BuildContext context) async {
    try {
      final data = _sampleData();
      const service = ThermalDocumentPdfService();
      await Printing.layoutPdf(
        name: 'printing-settings-test-thermal.pdf',
        onLayout: (_) => service.build(data, settings),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thermal test failed: $error')));
      }
    }
  }

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
            Row(
              children: [
                CircleAvatar(backgroundColor: cs.primaryContainer, child: Icon(Icons.science_outlined, color: cs.onPrimaryContainer)),
                const SizedBox(width: 12),
                Expanded(child: Text('Test Print Preview', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Generate a sample A4 or thermal document using the current settings before testing real invoices.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _a4Enabled ? () => _testA4(context) : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Test A4 PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: _thermalEnabled ? () => _testThermal(context) : null,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text('Test Thermal ${settings.thermalWidth.label}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DocumentPrintDataModel _sampleData() {
    final now = DateTime.now();
    return DocumentPrintDataModel(
      documentId: 'sample-print-preview',
      documentType: 'Invoice',
      documentNumber: 'TEST-0001',
      status: 'Preview',
      company: const PrintCompanyModel(
        companyName: 'LedgerFlow Demo Company',
        legalName: 'LedgerFlow Trading LLC',
        email: 'info@example.com',
        phone: '+20 100 000 0000',
        currency: 'EGP',
        country: 'Egypt',
      ),
      customer: const PrintCustomerModel(
        customerId: 'sample-customer',
        displayName: 'Sample Customer / عميل تجريبي',
        email: 'customer@example.com',
        phone: '+20 111 222 3333',
        currency: 'EGP',
        openBalance: 1250,
        creditBalance: 150,
      ),
      payment: const PrintPaymentModel(
        depositAccountId: 'sample-bank',
        depositAccountName: 'Main Cash / Bank',
        paymentMethod: 'Cash',
        linkedPaymentId: 'sample-payment',
      ),
      documentDate: now,
      dueDate: now.add(const Duration(days: 14)),
      subtotal: 1150,
      discountAmount: 50,
      taxAmount: 154,
      totalAmount: 1254,
      paidAmount: 500,
      creditAppliedAmount: 0,
      returnedAmount: 0,
      balanceDue: 754,
      lines: const [
        PrintLineModel(
          lineNumber: 1,
          itemId: 'item-001',
          itemName: 'Kitchen Organizer',
          description: 'Kitchen Organizer / منظم مطبخ',
          quantity: 2,
          unitPrice: 250,
          discountPercent: 0,
          taxRatePercent: 14,
          taxAmount: 70,
          lineTotal: 570,
        ),
        PrintLineModel(
          lineNumber: 2,
          itemId: 'item-002',
          itemName: 'Storage Box',
          description: 'Storage Box / صندوق تخزين',
          quantity: 3,
          unitPrice: 200,
          discountPercent: 8.33,
          taxRatePercent: 14,
          taxAmount: 84,
          lineTotal: 684,
        ),
      ],
      summaryRows: const [
        PrintSummaryRowModel(label: 'Subtotal', amount: 1150, isStrong: false),
        PrintSummaryRowModel(label: 'Discount', amount: -50, isStrong: false),
        PrintSummaryRowModel(label: 'Tax', amount: 154, isStrong: false),
        PrintSummaryRowModel(label: 'Total', amount: 1254, isStrong: true),
        PrintSummaryRowModel(label: 'Paid', amount: -500, isStrong: false),
        PrintSummaryRowModel(label: 'Balance Due', amount: 754, isStrong: true),
      ],
      generatedAt: now,
      notes: 'This is a sample document generated from Printing Settings.',
      terms: 'Net 14',
    );
  }
}

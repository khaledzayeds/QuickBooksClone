import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../printing/data/models/print_data_contracts.dart';
import '../../printing/services/a4_document_pdf_service.dart';
import '../../printing/services/thermal_document_pdf_service.dart';
import '../data/models/printing_settings_model.dart';

class PrintingTestPreviewCard extends StatelessWidget {
  const PrintingTestPreviewCard({super.key, required this.settings});

  final PrintingSettingsModel settings;

  bool get _a4Enabled =>
      settings.printMode == PrintMode.a4 ||
      settings.printMode == PrintMode.both;
  bool get _thermalEnabled =>
      settings.printMode == PrintMode.thermal ||
      settings.printMode == PrintMode.both;

  Future<void> _testA4(BuildContext context) async {
    final text = _PrintingTestText.of(context);
    try {
      final data = _sampleData();
      const service = A4DocumentPdfService();
      await Printing.layoutPdf(
        name: 'printing-settings-test-a4.pdf',
        format: PdfPageFormat.a4,
        dynamicLayout: false,
        usePrinterSettings: false,
        forceCustomPrintPaper: true,
        onLayout: (_) => service.build(data, settings),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.a4TestFailed(error))));
      }
    }
  }

  Future<void> _testThermal(BuildContext context) async {
    final text = _PrintingTestText.of(context);
    try {
      final data = _sampleData();
      const service = ThermalDocumentPdfService();
      await Printing.layoutPdf(
        name: 'printing-settings-test-thermal.pdf',
        format: _thermalPageFormat(data, settings),
        dynamicLayout: false,
        usePrinterSettings: false,
        forceCustomPrintPaper: true,
        onLayout: (_) => service.build(data, settings),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.thermalTestFailed(error))));
      }
    }
  }

  PdfPageFormat _thermalPageFormat(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    final width = settings.thermalWidth.widthMillimeters * PdfPageFormat.mm;
    final lineHeight = settings.thermalWidth == ThermalWidth.mm58 ? 14.0 : 12.0;
    final longLineExtra =
        data.lines
            .where(
              (line) =>
                  (line.description.isNotEmpty
                          ? line.description
                          : line.itemName)
                      .length >
                  (settings.thermalWidth == ThermalWidth.mm58 ? 22 : 32),
            )
            .length *
        5;
    final notesExtra =
        ((data.notes ?? '').isNotEmpty ? 12 : 0) +
        ((settings.receiptFooterMessage ?? '').isNotEmpty ? 10 : 0);
    final heightMm =
        150 +
        (data.lines.length * lineHeight) +
        longLineExtra +
        notesExtra +
        50;
    final safeHeightMm = heightMm < 240 ? 240.0 : heightMm;
    return PdfPageFormat(width, safeHeightMm * PdfPageFormat.mm);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = _PrintingTestText.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(
                    Icons.science_outlined,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text.testPrintPreview,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text.testPrintPreviewHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _a4Enabled ? () => _testA4(context) : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(text.testA4Pdf),
                ),
                OutlinedButton.icon(
                  onPressed: _thermalEnabled
                      ? () => _testThermal(context)
                      : null,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(text.testThermal(settings.thermalWidth)),
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
    final arabic = settings.languageCode.toLowerCase().startsWith('ar');
    return DocumentPrintDataModel(
      documentId: 'sample-print-preview',
      documentType: arabic ? 'فاتورة مبيعات' : 'Invoice',
      documentNumber: 'TEST-0001',
      status: arabic ? 'معاينة' : 'Preview',
      company: PrintCompanyModel(
        companyName: arabic ? 'شركة زايد التجريبية' : 'Zayed Demo Company',
        legalName: arabic ? 'زايد للتجارة' : 'Zayed Trading LLC',
        email: 'info@example.com',
        phone: '+20 100 000 0000',
        currency: 'EGP',
        country: arabic ? 'مصر' : 'Egypt',
      ),
      customer: PrintCustomerModel(
        customerId: 'sample-customer',
        displayName: arabic ? 'عميل تجريبي' : 'Sample Customer',
        email: 'customer@example.com',
        phone: '+20 111 222 3333',
        currency: 'EGP',
        openBalance: 1250,
        creditBalance: 150,
      ),
      partyLabel: arabic ? 'العميل' : 'Customer',
      partyType: arabic ? 'عميل' : 'Customer',
      payment: PrintPaymentModel(
        depositAccountId: 'sample-bank',
        depositAccountName: arabic
            ? 'الخزينة / البنك الرئيسي'
            : 'Main Cash / Bank',
        paymentMethod: arabic ? 'نقدي' : 'Cash',
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
      lines: [
        PrintLineModel(
          lineNumber: 1,
          itemId: 'item-001',
          itemName: arabic ? 'منظم مطبخ' : 'Kitchen Organizer',
          description: arabic ? 'منظم مطبخ' : 'Kitchen Organizer',
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
          itemName: arabic ? 'صندوق تخزين' : 'Storage Box',
          description: arabic ? 'صندوق تخزين' : 'Storage Box',
          quantity: 3,
          unitPrice: 200,
          discountPercent: 8.33,
          taxRatePercent: 14,
          taxAmount: 84,
          lineTotal: 684,
        ),
      ],
      summaryRows: [
        PrintSummaryRowModel(
          label: arabic ? 'الإجمالي الفرعي' : 'Subtotal',
          amount: 1150,
          isStrong: false,
        ),
        PrintSummaryRowModel(
          label: arabic ? 'الخصم' : 'Discount',
          amount: -50,
          isStrong: false,
        ),
        PrintSummaryRowModel(
          label: arabic ? 'الضريبة' : 'Tax',
          amount: 154,
          isStrong: false,
        ),
        PrintSummaryRowModel(
          label: arabic ? 'الإجمالي' : 'Total',
          amount: 1254,
          isStrong: true,
        ),
        PrintSummaryRowModel(
          label: arabic ? 'المدفوع' : 'Paid',
          amount: -500,
          isStrong: false,
        ),
        PrintSummaryRowModel(
          label: arabic ? 'الرصيد المستحق' : 'Balance Due',
          amount: 754,
          isStrong: true,
        ),
      ],
      generatedAt: now,
      notes: arabic
          ? 'هذا مستند تجريبي تم إنشاؤه من إعدادات الطباعة.'
          : 'This is a sample document generated from Printing Settings.',
      terms: arabic ? 'صافي 14' : 'Net 14',
    );
  }
}

class _PrintingTestText {
  const _PrintingTestText(this.ar);

  final bool ar;

  static _PrintingTestText of(BuildContext context) =>
      _PrintingTestText(Localizations.localeOf(context).languageCode == 'ar');

  String get testPrintPreview =>
      ar ? 'اختبار معاينة الطباعة' : 'Test Print Preview';
  String get testPrintPreviewHint => ar
      ? 'أنشئ مستندًا تجريبيًا A4 أو حراريًا بالإعدادات الحالية قبل اختبار الفواتير الحقيقية.'
      : 'Generate a sample A4 or thermal document using the current settings before testing real invoices.';
  String get testA4Pdf => ar ? 'اختبار PDF A4' : 'Test A4 PDF';
  String testThermal(ThermalWidth width) =>
      ar ? 'اختبار حراري ${width.label}' : 'Test Thermal ${width.label}';
  String a4TestFailed(Object error) =>
      ar ? 'فشل اختبار A4: $error' : 'A4 test failed: $error';
  String thermalTestFailed(Object error) => ar
      ? 'فشل اختبار الطباعة الحرارية: $error'
      : 'Thermal test failed: $error';
}

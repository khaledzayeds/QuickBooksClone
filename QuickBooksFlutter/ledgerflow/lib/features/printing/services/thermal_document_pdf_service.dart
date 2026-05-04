// thermal_document_pdf_service.dart

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../settings/data/models/printing_settings_model.dart';
import '../data/models/print_data_contracts.dart';

class ThermalDocumentPdfService {
  const ThermalDocumentPdfService();

  Future<Uint8List> build(DocumentPrintDataModel data, PrintingSettingsModel settings) async {
    final doc = pw.Document();
    final pageWidth = settings.thermalWidth.widthMillimeters * PdfPageFormat.mm;
    final margin = settings.thermalWidth == ThermalWidth.mm58 ? 3 * PdfPageFormat.mm : 5 * PdfPageFormat.mm;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, double.infinity, marginAll: margin),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (settings.showLogo) _center('[ LOGO ]', fontSize: 8),
            _center(data.company.companyName, fontSize: 12, bold: true),
            if (settings.showCompanyAddress) _center(data.company.country, fontSize: 8),
            if ((data.company.phone ?? '').isNotEmpty) _center('Tel: ${data.company.phone}', fontSize: 8),
            if ((data.company.email ?? '').isNotEmpty) _center(data.company.email!, fontSize: 8),
            _divider(settings),
            _center(data.documentType.toUpperCase(), fontSize: 11, bold: true),
            _center('#${data.documentNumber}', fontSize: 10, bold: true),
            pw.SizedBox(height: 4),
            _kv('Date', _formatDate(data.documentDate)),
            _kv('Customer', data.customer.displayName),
            if (settings.showCustomerBalance) _kv('Balance', '${data.customer.openBalance.toStringAsFixed(2)} ${data.customer.currency}'),
            if ((data.payment?.paymentMethod ?? '').isNotEmpty) _kv('Pay', data.payment!.paymentMethod!),
            if ((data.payment?.depositAccountName ?? '').isNotEmpty) _kv('Deposit', data.payment!.depositAccountName!),
            _divider(settings),
            ...data.lines.map(_line),
            _divider(settings),
            ...data.summaryRows
                .where((row) => settings.showTaxSummary || row.label.toLowerCase() != 'tax')
                .map((row) => _amountRow(row.label, row.amount, data.company.currency, bold: row.isStrong)),
            _divider(settings),
            if ((settings.receiptFooterMessage ?? '').isNotEmpty) _center(settings.receiptFooterMessage!, fontSize: 9, bold: true),
            _center('Generated: ${_formatDateTime(data.generatedAt)}', fontSize: 7),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _line(PrintLineModel line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(line.description.isNotEmpty ? line.description : line.itemName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('${line.quantity.toStringAsFixed(2)} x ${line.unitPrice.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8))),
              pw.Text(line.lineTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _amountRow(String label, double amount, String currency, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: pw.TextStyle(fontSize: bold ? 10 : 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal))),
          pw.Text('${amount.toStringAsFixed(2)} $currency', style: pw.TextStyle(fontSize: bold ? 10 : 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  pw.Widget _kv(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 44, child: pw.Text('$label:', style: const pw.TextStyle(fontSize: 8))),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  pw.Widget _center(String text, {double fontSize = 8, bool bold = false}) {
    return pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
    );
  }

  pw.Widget _divider(PrintingSettingsModel settings) {
    final marks = settings.thermalWidth == ThermalWidth.mm58 ? '------------------------' : '--------------------------------';
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Text(marks, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  String _formatDateTime(DateTime date) => '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

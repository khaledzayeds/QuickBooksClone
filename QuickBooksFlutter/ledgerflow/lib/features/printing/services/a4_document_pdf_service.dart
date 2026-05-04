// a4_document_pdf_service.dart

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../settings/data/models/printing_settings_model.dart';
import '../data/models/print_data_contracts.dart';

class A4DocumentPdfService {
  const A4DocumentPdfService();

  Future<Uint8List> build(DocumentPrintDataModel data, PrintingSettingsModel settings) async {
    final doc = pw.Document();
    final margin = switch (settings.a4TemplateStyle) {
      A4TemplateStyle.compact => 20.0,
      A4TemplateStyle.classic => 32.0,
      A4TemplateStyle.modern => 28.0,
    };

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(margin),
        build: (context) => [
          _header(data, settings),
          pw.SizedBox(height: settings.a4TemplateStyle == A4TemplateStyle.compact ? 12 : 18),
          _partyAndMeta(data, settings),
          pw.SizedBox(height: settings.a4TemplateStyle == A4TemplateStyle.compact ? 12 : 18),
          _linesTable(data, settings),
          pw.SizedBox(height: 14),
          _summary(data, settings),
          if ((data.terms ?? '').isNotEmpty || (data.notes ?? '').isNotEmpty || (settings.invoiceFooterMessage ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _notes(data, settings),
          ],
        ],
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated: ${_formatDateTime(data.generatedAt)}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _header(DocumentPrintDataModel data, PrintingSettingsModel settings) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (settings.showLogo)
                pw.Container(
                  width: 46,
                  height: 46,
                  alignment: pw.Alignment.center,
                  margin: const pw.EdgeInsets.only(right: 10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500, width: .5), borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Text('LOGO', style: const pw.TextStyle(fontSize: 8)),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(data.company.companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    if ((data.company.legalName ?? '').isNotEmpty) pw.Text(data.company.legalName!),
                    if (settings.showCompanyAddress) pw.Text('${data.company.country} • ${data.company.currency}'),
                    if ((data.company.phone ?? '').isNotEmpty) pw.Text('Phone: ${data.company.phone}'),
                    if ((data.company.email ?? '').isNotEmpty) pw.Text('Email: ${data.company.email}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(data.documentType.toUpperCase(), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('#${data.documentNumber}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Text(data.status, style: const pw.TextStyle(fontSize: 9)),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _partyAndMeta(DocumentPrintDataModel data, PrintingSettingsModel settings) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _box(
            'Bill To',
            [
              pw.Text(data.customer.displayName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if ((data.customer.phone ?? '').isNotEmpty) pw.Text('Phone: ${data.customer.phone}'),
              if ((data.customer.email ?? '').isNotEmpty) pw.Text('Email: ${data.customer.email}'),
              if (settings.showCustomerBalance) ...[
                pw.Text('Balance: ${_money(data.customer.openBalance, data.customer.currency)}'),
                pw.Text('Credits: ${_money(data.customer.creditBalance, data.customer.currency)}'),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _box(
            'Document',
            [
              _kv('Date', _formatDate(data.documentDate)),
              _kv('Due date', _formatDate(data.dueDate)),
              if ((data.payment?.paymentMethod ?? '').isNotEmpty) _kv('Payment', data.payment!.paymentMethod!),
              if ((data.payment?.depositAccountName ?? '').isNotEmpty) _kv('Deposit', data.payment!.depositAccountName!),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _linesTable(DocumentPrintDataModel data, PrintingSettingsModel settings) {
    final headers = ['#', settings.showItemSku ? 'Item / SKU' : 'Item', 'Qty', 'Price', if (settings.showTaxSummary) 'Tax', 'Total'];
    final rows = data.lines
        .map((line) => [
              line.lineNumber.toString(),
              line.description.isNotEmpty ? line.description : line.itemName,
              line.quantity.toStringAsFixed(2),
              _money(line.unitPrice, data.company.currency),
              if (settings.showTaxSummary) _money(line.taxAmount, data.company.currency),
              _money(line.lineTotal, data.company.currency),
            ])
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: pw.EdgeInsets.all(settings.a4TemplateStyle == A4TemplateStyle.compact ? 3 : 5),
    );
  }

  pw.Widget _summary(DocumentPrintDataModel data, PrintingSettingsModel settings) {
    final rows = settings.showTaxSummary ? data.summaryRows : data.summaryRows.where((row) => row.label.toLowerCase() != 'tax').toList();
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 210,
        child: pw.Column(
          children: rows
              .map(
                (row) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text(row.label, style: pw.TextStyle(fontWeight: row.isStrong ? pw.FontWeight.bold : pw.FontWeight.normal))),
                      pw.Text(_money(row.amount, data.company.currency), style: pw.TextStyle(fontWeight: row.isStrong ? pw.FontWeight.bold : pw.FontWeight.normal)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  pw.Widget _notes(DocumentPrintDataModel data, PrintingSettingsModel settings) {
    return _box(
      'Notes / Terms',
      [
        if ((data.terms ?? '').isNotEmpty) pw.Text('Terms: ${data.terms}'),
        if ((data.notes ?? '').isNotEmpty) pw.Text(data.notes!),
        if ((settings.invoiceFooterMessage ?? '').isNotEmpty) pw.Text(settings.invoiceFooterMessage!),
      ],
    );
  }

  pw.Widget _box(String title, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: .5),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _kv(String label, String value) {
    return pw.Row(
      children: [
        pw.Expanded(child: pw.Text(label)),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  String _money(double value, String currency) => '${value.toStringAsFixed(2)} $currency';
  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  String _formatDateTime(DateTime date) => '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

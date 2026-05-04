// a4_document_pdf_service.dart

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/print_data_contracts.dart';

class A4DocumentPdfService {
  const A4DocumentPdfService();

  Future<Uint8List> build(DocumentPrintDataModel data) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          _header(data),
          pw.SizedBox(height: 18),
          _partyAndMeta(data),
          pw.SizedBox(height: 18),
          _linesTable(data),
          pw.SizedBox(height: 14),
          _summary(data),
          if ((data.terms ?? '').isNotEmpty || (data.notes ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _notes(data),
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

  pw.Widget _header(DocumentPrintDataModel data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(data.company.companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              if ((data.company.legalName ?? '').isNotEmpty) pw.Text(data.company.legalName!),
              if ((data.company.phone ?? '').isNotEmpty) pw.Text('Phone: ${data.company.phone}'),
              if ((data.company.email ?? '').isNotEmpty) pw.Text('Email: ${data.company.email}'),
              pw.Text('${data.company.country} • ${data.company.currency}'),
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

  pw.Widget _partyAndMeta(DocumentPrintDataModel data) {
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
              pw.Text('Balance: ${_money(data.customer.openBalance, data.customer.currency)}'),
              pw.Text('Credits: ${_money(data.customer.creditBalance, data.customer.currency)}'),
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

  pw.Widget _linesTable(DocumentPrintDataModel data) {
    final rows = <List<String>>[
      ['#', 'Item', 'Qty', 'Price', 'Tax', 'Total'],
      ...data.lines.map((line) => [
            line.lineNumber.toString(),
            line.description.isNotEmpty ? line.description : line.itemName,
            line.quantity.toStringAsFixed(2),
            _money(line.unitPrice, data.company.currency),
            _money(line.taxAmount, data.company.currency),
            _money(line.lineTotal, data.company.currency),
          ]),
    ];

    return pw.TableHelper.fromTextArray(
      headers: rows.first,
      data: rows.skip(1).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellPadding: const pw.EdgeInsets.all(5),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(44),
        3: const pw.FixedColumnWidth(70),
        4: const pw.FixedColumnWidth(64),
        5: const pw.FixedColumnWidth(78),
      },
    );
  }

  pw.Widget _summary(DocumentPrintDataModel data) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 210,
        child: pw.Column(
          children: data.summaryRows
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

  pw.Widget _notes(DocumentPrintDataModel data) {
    return _box(
      'Notes / Terms',
      [
        if ((data.terms ?? '').isNotEmpty) pw.Text('Terms: ${data.terms}'),
        if ((data.notes ?? '').isNotEmpty) pw.Text(data.notes!),
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

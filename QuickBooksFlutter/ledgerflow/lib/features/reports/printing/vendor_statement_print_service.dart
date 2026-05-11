import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class VendorStatementPrintLine {
  const VendorStatementPrintLine({
    required this.type,
    required this.number,
    required this.date,
    required this.amount,
    required this.status,
  });

  final String type;
  final String number;
  final DateTime date;
  final double amount;
  final String status;
}

class VendorStatementPrintModel {
  const VendorStatementPrintModel({
    required this.vendorName,
    required this.lines,
    this.fromDate,
    this.toDate,
    this.type = 'All',
    this.currency = 'EGP',
  });

  final String vendorName;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String type;
  final String currency;
  final List<VendorStatementPrintLine> lines;
}

class VendorStatementPrintService {
  const VendorStatementPrintService();

  Future<void> printStatement(VendorStatementPrintModel model) async {
    final bytes = await buildPdf(model);
    await Printing.layoutPdf(
      name: 'Vendor-Statement-${model.vendorName}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<Uint8List> buildPdf(VendorStatementPrintModel model) async {
    final font = await PdfGoogleFonts.notoNaskhArabicRegular();
    final boldFont = await PdfGoogleFonts.notoNaskhArabicBold();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: boldFont, fontFallback: [font]),
    );

    final dateFmt = DateFormat('dd/MM/yyyy');
    final moneyFmt = NumberFormat('#,##0.00');
    final total = model.lines.fold<double>(0, (sum, line) => sum + line.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('LedgerFlow', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Vendor Statement', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Vendor Statement', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(model.vendorName, style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(dateFmt.format(DateTime.now()), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(child: _kv('Vendor', model.vendorName)),
                pw.Expanded(child: _kv('Date range', model.fromDate == null || model.toDate == null ? 'All dates' : '${dateFmt.format(model.fromDate!)} - ${dateFmt.format(model.toDate!)}')),
                pw.Expanded(child: _kv('Type', model.type)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Transactions: ${model.lines.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Net amount: ${moneyFmt.format(total)} ${model.currency}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Type', 'Number', 'Status', 'Amount'],
            data: model.lines
                .map((line) => [
                      dateFmt.format(line.date),
                      line.type,
                      line.number,
                      line.status,
                      '${moneyFmt.format(line.amount)} ${model.currency}',
                    ])
                .toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignments: const {4: pw.Alignment.centerRight},
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _kv(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        pw.SizedBox(height: 3),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }
}

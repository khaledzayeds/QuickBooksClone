import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'transaction_print_model.dart';

class TransactionPrintService {
  const TransactionPrintService();

  Future<void> printDocument(TransactionPrintModel model) async {
    final bytes = await buildPdf(model);
    await Printing.layoutPdf(
      name: '${model.documentTitle}-${model.documentNumber}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<List<int>> buildPdf(TransactionPrintModel model) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');
    final moneyFmt = NumberFormat('#,##0.00');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          _buildHeader(model, dateFmt),
          pw.SizedBox(height: 18),
          _buildPartyBlock(model, dateFmt),
          pw.SizedBox(height: 18),
          _buildLinesTable(model, moneyFmt),
          pw.SizedBox(height: 16),
          _buildTotals(model, moneyFmt),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(TransactionPrintModel model, DateFormat dateFmt) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'LedgerFlow',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Business document preview', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              model.documentTitle,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('# ${model.documentNumber}', style: const pw.TextStyle(fontSize: 11)),
            pw.Text(dateFmt.format(model.documentDate), style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPartyBlock(TransactionPrintModel model, DateFormat dateFmt) {
    final rows = <pw.Widget>[
      _kv(model.partyLabel, model.partyName),
      if (model.dueDate != null) _kv('Due date', dateFmt.format(model.dueDate!)),
      if (model.paymentMethod != null && model.paymentMethod!.trim().isNotEmpty)
        _kv('Payment method', model.paymentMethod!.trim()),
      if (model.reference != null && model.reference!.trim().isNotEmpty)
        _kv('Reference', model.reference!.trim()),
    ];

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: rows),
    );
  }

  pw.Widget _buildLinesTable(TransactionPrintModel model, NumberFormat moneyFmt) {
    final data = model.lines
        .map(
          (line) => [
            line.itemName,
            line.description,
            line.quantity.toStringAsFixed(2),
            moneyFmt.format(line.rate),
            moneyFmt.format(line.amount),
          ],
        )
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: const ['Item', 'Description', 'Qty', 'Rate', 'Amount'],
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      columnWidths: const {
        0: pw.FlexColumnWidth(1.5),
        1: pw.FlexColumnWidth(2.2),
        2: pw.FlexColumnWidth(0.7),
        3: pw.FlexColumnWidth(0.9),
        4: pw.FlexColumnWidth(1.0),
      },
    );
  }

  pw.Widget _buildTotals(TransactionPrintModel model, NumberFormat moneyFmt) {
    final totals = model.totals;
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        child: pw.Column(
          children: [
            _moneyRow('Subtotal', totals.subtotal, totals.currency, moneyFmt),
            _moneyRow('Discount', totals.discountTotal, totals.currency, moneyFmt),
            _moneyRow('Tax', totals.taxTotal, totals.currency, moneyFmt),
            pw.Divider(color: PdfColors.grey500),
            _moneyRow('Total', totals.total, totals.currency, moneyFmt, bold: true),
            _moneyRow('Paid', totals.paid, totals.currency, moneyFmt),
            _moneyRow('Balance due', totals.balanceDue, totals.currency, moneyFmt, bold: true),
          ],
        ),
      ),
    );
  }

  pw.Widget _kv(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  pw.Widget _moneyRow(
    String label,
    double amount,
    String currency,
    NumberFormat moneyFmt, {
    bool bold = false,
  }) {
    final style = pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text('${moneyFmt.format(amount)} $currency', style: style),
        ],
      ),
    );
  }
}

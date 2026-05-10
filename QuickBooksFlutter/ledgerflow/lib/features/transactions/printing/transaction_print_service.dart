import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
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

  Future<Uint8List> buildPdf(TransactionPrintModel model) async {
    final font = await _loadPdfFont();
    final boldFont = await _loadPdfBoldFont();
    final doc = pw.Document(
      theme: font == null
          ? null
          : pw.ThemeData.withFont(
              base: font,
              bold: boldFont ?? font,
              fontFallback: [font],
            ),
    );
    final dateFmt = DateFormat('dd/MM/yyyy');
    final moneyFmt = NumberFormat('#,##0.00');
    final rtl = _modelContainsArabic(model);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (context) => [
          _buildHeader(model, dateFmt, rtl),
          pw.SizedBox(height: 18),
          _buildPartyBlock(model, dateFmt),
          pw.SizedBox(height: 18),
          _buildLinesTable(model, moneyFmt, rtl),
          pw.SizedBox(height: 16),
          _buildTotals(model, moneyFmt),
        ],
      ),
    );

    return doc.save();
  }

  Future<pw.Font?> _loadPdfFont() async {
    final assetFont = await _tryLoadFirstAssetFont(bold: false);
    if (assetFont != null) return assetFont;

    try {
      return await PdfGoogleFonts.notoNaskhArabicRegular();
    } catch (_) {
      return null;
    }
  }

  Future<pw.Font?> _loadPdfBoldFont() async {
    final assetFont = await _tryLoadFirstAssetFont(bold: true);
    if (assetFont != null) return assetFont;

    try {
      return await PdfGoogleFonts.notoNaskhArabicBold();
    } catch (_) {
      return null;
    }
  }

  Future<pw.Font?> _tryLoadFirstAssetFont({required bool bold}) async {
    try {
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
      final fontPaths = manifest.keys
          .where((path) =>
              path.startsWith('assets/fonts/') &&
              (path.toLowerCase().endsWith('.ttf') || path.toLowerCase().endsWith('.otf')))
          .toList();

      if (fontPaths.isEmpty) return null;

      int score(String path) {
        final lower = path.toLowerCase();
        var value = 0;
        if (lower.contains('arabic')) value += 50;
        if (lower.contains('naskh')) value += 45;
        if (lower.contains('cairo')) value += 40;
        if (lower.contains('tajawal')) value += 35;
        if (lower.contains('noto')) value += 30;
        if (lower.contains('amiri')) value += 25;
        if (bold && lower.contains('bold')) value += 20;
        if (!bold && (lower.contains('regular') || lower.contains('medium'))) value += 15;
        return value;
      }

      fontPaths.sort((a, b) => score(b).compareTo(score(a)));
      final data = await rootBundle.load(fontPaths.first);
      return pw.Font.ttf(data);
    } catch (_) {
      return null;
    }
  }

  bool _modelContainsArabic(TransactionPrintModel model) {
    final buffer = StringBuffer()
      ..write(model.documentTitle)
      ..write(model.documentNumber)
      ..write(model.partyLabel)
      ..write(model.partyName)
      ..write(model.reference ?? '')
      ..write(model.paymentMethod ?? '')
      ..write(model.totals.currency);
    for (final line in model.lines) {
      buffer
        ..write(line.itemName)
        ..write(line.description);
    }
    return _containsArabic(buffer.toString());
  }

  bool _containsArabic(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  pw.Widget _buildHeader(TransactionPrintModel model, DateFormat dateFmt, bool rtl) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
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
          crossAxisAlignment: rtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
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

  pw.Widget _buildLinesTable(TransactionPrintModel model, NumberFormat moneyFmt, bool rtl) {
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

    return pw.Directionality(
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.TableHelper.fromTextArray(
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
      ),
    );
  }

  pw.Widget _buildTotals(TransactionPrintModel model, NumberFormat moneyFmt) {
    final totals = model.totals;
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
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
    final direction = _containsArabic('$label $value') ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    return pw.Directionality(
      textDirection: direction,
      child: pw.Padding(
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

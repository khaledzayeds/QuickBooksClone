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
    final safeNumber = model.documentNumber.trim().isEmpty ? 'Draft' : model.documentNumber.trim();
    await Printing.layoutPdf(
      name: '${model.documentTitle}-$safeNumber.pdf',
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
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 28),
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (context) => [
          _buildHeader(model, dateFmt, rtl),
          pw.SizedBox(height: 14),
          _buildPartyBlock(model, dateFmt),
          pw.SizedBox(height: 14),
          _buildLinesTable(model, moneyFmt, rtl),
          pw.SizedBox(height: 14),
          _buildTotals(model, moneyFmt),
          pw.SizedBox(height: 22),
          _buildFooterNote(model),
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
    final number = model.documentNumber.trim().isEmpty ? 'Draft' : model.documentNumber.trim();
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey600, width: 1.2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LedgerFlow',
                style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 4),
              pw.Text('QuickBooks-style business document', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey600)),
            ],
          ),
          pw.Container(
            width: 190,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              border: pw.Border.all(color: PdfColors.blueGrey300),
            ),
            child: pw.Column(
              crossAxisAlignment: rtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  model.documentTitle.toUpperCase(),
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                ),
                pw.SizedBox(height: 6),
                _headerMeta('No.', number),
                _headerMeta('Date', dateFmt.format(model.documentDate)),
                if (model.dueDate != null) _headerMeta('Due', dateFmt.format(model.dueDate!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _headerMeta(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey900)),
        ],
      ),
    );
  }

  pw.Widget _buildPartyBlock(TransactionPrintModel model, DateFormat dateFmt) {
    final rows = <pw.Widget>[
      _kv(model.partyLabel.toUpperCase(), model.partyName),
      if (model.paymentMethod != null && model.paymentMethod!.trim().isNotEmpty)
        _kv('PAYMENT METHOD', model.paymentMethod!.trim()),
      if (model.reference != null && model.reference!.trim().isNotEmpty)
        _kv('MEMO / REFERENCE', model.reference!.trim()),
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: rows),
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Container(
          width: 180,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CUSTOMER MESSAGE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('Thank you for your business.', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildLinesTable(TransactionPrintModel model, NumberFormat moneyFmt, bool rtl) {
    final data = model.lines
        .map(
          (line) => [
            line.itemName.trim().isEmpty ? 'Item' : line.itemName.trim(),
            line.quantity.toStringAsFixed(2),
            line.description.trim().isEmpty ? line.itemName.trim() : line.description.trim(),
            moneyFmt.format(line.rate),
            moneyFmt.format(line.amount),
          ],
        )
        .toList();

    return pw.Directionality(
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.TableHelper.fromTextArray(
        headers: const ['Item', 'Quantity', 'Description', 'Rate', 'Amount'],
        data: data,
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.blueGrey900),
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        cellAlignments: const {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerRight,
          2: pw.Alignment.centerLeft,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
        },
        columnWidths: const {
          0: pw.FlexColumnWidth(1.4),
          1: pw.FlexColumnWidth(0.8),
          2: pw.FlexColumnWidth(2.6),
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
        width: 245,
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Column(
            children: [
              _moneyRow('Subtotal', totals.subtotal, totals.currency, moneyFmt),
              if (totals.discountTotal != 0) _moneyRow('Discount', totals.discountTotal, totals.currency, moneyFmt),
              if (totals.taxTotal != 0) _moneyRow('Tax', totals.taxTotal, totals.currency, moneyFmt),
              if (totals.shipping != 0) _moneyRow('Shipping', totals.shipping, totals.currency, moneyFmt),
              pw.Divider(color: PdfColors.grey500),
              _moneyRow('Total', totals.total, totals.currency, moneyFmt, bold: true),
              _moneyRow('Payments applied', totals.paid, totals.currency, moneyFmt),
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 4),
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                color: PdfColors.blueGrey50,
                child: _moneyRow('Balance due', totals.balanceDue, totals.currency, moneyFmt, bold: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  pw.Widget _buildFooterNote(TransactionPrintModel model) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Text(
        '${model.documentTitle} generated from LedgerFlow. Please review totals and payment status before delivery.',
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _kv(String label, String value) {
    final direction = _containsArabic('$label $value') ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    return pw.Directionality(
      textDirection: direction,
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 105,
              child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.blueGrey800)),
            ),
            pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 9))),
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

import 'dart:convert';

import 'package:flutter/services.dart';
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
    final rtl = _isArabicStatement(model);
    final labels = _StatementLabels.forDirection(rtl);
    final total = model.lines.fold<double>(0, (sum, line) => sum + line.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: rtl
                    ? pw.CrossAxisAlignment.end
                    : pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Zayed',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    labels.title,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: rtl
                    ? pw.CrossAxisAlignment.start
                    : pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    labels.title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    model.vendorName,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    dateFmt.format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
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
                pw.Expanded(child: _kv(labels.vendor, model.vendorName)),
                pw.Expanded(
                  child: _kv(
                    labels.dateRange,
                    model.fromDate == null || model.toDate == null
                        ? labels.allDates
                        : '${dateFmt.format(model.fromDate!)} - ${dateFmt.format(model.toDate!)}',
                  ),
                ),
                pw.Expanded(child: _kv(labels.type, model.type)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${labels.transactions}: ${model.lines.length}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '${labels.netAmount}: ${moneyFmt.format(total)} ${model.currency}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: [
              labels.date,
              labels.type,
              labels.number,
              labels.status,
              labels.amount,
            ],
            data: model.lines
                .map(
                  (line) => [
                    dateFmt.format(line.date),
                    line.type,
                    line.number,
                    line.status,
                    '${moneyFmt.format(line.amount)} ${model.currency}',
                  ],
                )
                .toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
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
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
        ),
        pw.SizedBox(height: 3),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
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
          .where(
            (path) =>
                path.startsWith('assets/fonts/') &&
                (path.toLowerCase().endsWith('.ttf') ||
                    path.toLowerCase().endsWith('.otf')),
          )
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
        if (bold && lower.contains('bold')) value += 20;
        if (!bold && (lower.contains('regular') || lower.contains('medium'))) {
          value += 15;
        }
        return value;
      }

      fontPaths.sort((a, b) => score(b).compareTo(score(a)));
      final data = await rootBundle.load(fontPaths.first);
      return pw.Font.ttf(data);
    } catch (_) {
      return null;
    }
  }

  bool _isArabicStatement(VendorStatementPrintModel model) {
    if (_containsArabic(model.vendorName) || _containsArabic(model.type)) {
      return true;
    }
    return model.lines.any(
      (line) => _containsArabic(line.type) || _containsArabic(line.status),
    );
  }

  bool _containsArabic(String text) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(text);
}

class _StatementLabels {
  const _StatementLabels({
    required this.title,
    required this.vendor,
    required this.dateRange,
    required this.allDates,
    required this.type,
    required this.transactions,
    required this.netAmount,
    required this.date,
    required this.number,
    required this.status,
    required this.amount,
  });

  final String title;
  final String vendor;
  final String dateRange;
  final String allDates;
  final String type;
  final String transactions;
  final String netAmount;
  final String date;
  final String number;
  final String status;
  final String amount;

  static _StatementLabels forDirection(bool rtl) {
    if (rtl) {
      return const _StatementLabels(
        title: 'كشف حساب مورد',
        vendor: 'المورد',
        dateRange: 'الفترة',
        allDates: 'كل التواريخ',
        type: 'النوع',
        transactions: 'الحركات',
        netAmount: 'صافي المبلغ',
        date: 'التاريخ',
        number: 'الرقم',
        status: 'الحالة',
        amount: 'المبلغ',
      );
    }
    return const _StatementLabels(
      title: 'Vendor Statement',
      vendor: 'Vendor',
      dateRange: 'Date range',
      allDates: 'All dates',
      type: 'Type',
      transactions: 'Transactions',
      netAmount: 'Net amount',
      date: 'Date',
      number: 'Number',
      status: 'Status',
      amount: 'Amount',
    );
  }
}

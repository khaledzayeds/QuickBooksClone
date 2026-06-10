import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CustomerStatementPrintLine {
  const CustomerStatementPrintLine({
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

class CustomerStatementPrintModel {
  const CustomerStatementPrintModel({
    required this.customerName,
    required this.lines,
    this.fromDate,
    this.toDate,
    this.type = 'All',
    this.currency = 'EGP',
  });

  final String customerName;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String type;
  final String currency;
  final List<CustomerStatementPrintLine> lines;
}

class CustomerStatementPrintService {
  const CustomerStatementPrintService();

  Future<void> printStatement(CustomerStatementPrintModel model) async {
    final bytes = await buildPdf(model);
    await Printing.layoutPdf(
      name: 'Customer-Statement-${model.customerName}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<Uint8List> buildPdf(CustomerStatementPrintModel model) async {
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
          _header(model, dateFmt, rtl, labels),
          pw.SizedBox(height: 14),
          _filters(model, dateFmt, labels),
          pw.SizedBox(height: 14),
          _summary(model, moneyFmt, total, labels),
          pw.SizedBox(height: 14),
          _table(model, dateFmt, moneyFmt, rtl, labels),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _header(
    CustomerStatementPrintModel model,
    DateFormat dateFmt,
    bool rtl,
    _StatementLabels labels,
  ) {
    return pw.Row(
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
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(labels.title, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: rtl
              ? pw.CrossAxisAlignment.start
              : pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              labels.title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              model.customerName,
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              dateFmt.format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _filters(
    CustomerStatementPrintModel model,
    DateFormat dateFmt,
    _StatementLabels labels,
  ) {
    final range = model.fromDate == null || model.toDate == null
        ? labels.allDates
        : '${dateFmt.format(model.fromDate!)} - ${dateFmt.format(model.toDate!)}';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(child: _kv(labels.customer, model.customerName)),
          pw.Expanded(child: _kv(labels.dateRange, range)),
          pw.Expanded(child: _kv(labels.type, model.type)),
        ],
      ),
    );
  }

  pw.Widget _summary(
    CustomerStatementPrintModel model,
    NumberFormat moneyFmt,
    double total,
    _StatementLabels labels,
  ) {
    return pw.Container(
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
    );
  }

  pw.Widget _table(
    CustomerStatementPrintModel model,
    DateFormat dateFmt,
    NumberFormat moneyFmt,
    bool rtl,
    _StatementLabels labels,
  ) {
    final data = model.lines
        .map(
          (line) => [
            dateFmt.format(line.date),
            line.type,
            line.number,
            line.status,
            '${moneyFmt.format(line.amount)} ${model.currency}',
          ],
        )
        .toList();

    return pw.Directionality(
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      child: pw.TableHelper.fromTextArray(
        headers: [
          labels.date,
          labels.type,
          labels.number,
          labels.status,
          labels.amount,
        ],
        data: data,
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellAlignments: const {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.centerLeft,
          3: pw.Alignment.centerLeft,
          4: pw.Alignment.centerRight,
        },
        columnWidths: const {
          0: pw.FlexColumnWidth(1.0),
          1: pw.FlexColumnWidth(1.1),
          2: pw.FlexColumnWidth(1.2),
          3: pw.FlexColumnWidth(1.0),
          4: pw.FlexColumnWidth(1.2),
        },
      ),
    );
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

  bool _isArabicStatement(CustomerStatementPrintModel model) {
    if (_containsArabic(model.customerName) || _containsArabic(model.type)) {
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
    required this.customer,
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
  final String customer;
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
        title: 'كشف حساب عميل',
        customer: 'العميل',
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
      title: 'Customer Statement',
      customer: 'Customer',
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

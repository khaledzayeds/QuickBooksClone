// thermal_document_pdf_service.dart

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../settings/data/models/printing_settings_model.dart';
import '../data/models/print_data_contracts.dart';
import 'printing_asset_loader.dart';

class ThermalDocumentPdfService {
  const ThermalDocumentPdfService({
    this.assetLoader = const PrintingAssetLoader(),
  });

  final PrintingAssetLoader assetLoader;

  Future<Uint8List> build(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) async {
    final logo = await assetLoader.loadLogo(settings);
    final arabicFont = await assetLoader.loadArabicFont(settings);
    final theme = arabicFont == null
        ? null
        : pw.ThemeData.withFont(base: arabicFont, bold: arabicFont);
    final doc = pw.Document(theme: theme);
    final pageWidth = settings.thermalWidth.widthMillimeters * PdfPageFormat.mm;
    final margin = settings.thermalWidth == ThermalWidth.mm58
        ? 3 * PdfPageFormat.mm
        : 4 * PdfPageFormat.mm;
    final pageHeight = _estimatedReceiptHeightMm(data, settings) * PdfPageFormat.mm;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          pageWidth,
          pageHeight,
          marginAll: margin,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _buildHeader(data, settings, logo),
            _dashedLine(settings),
            _itemsTable(data),
            _dashedLine(settings),
            ..._receiptRows(data, settings).map(
              (row) => _amountRow(
                row.$1,
                row.$2,
                bold: row.$3,
              ),
            ),
            _dashedLine(settings),
            if ((data.payment?.paymentMethod ?? '').isNotEmpty) ...[
              _kvRtl('طريقة الدفع', data.payment!.paymentMethod!),
              _dashedLine(settings),
            ],
            if ((data.company.phone ?? '').isNotEmpty)
              _center('تليفون رقم ${data.company.phone}', fontSize: 8),
            if ((data.company.country).isNotEmpty)
              _center(data.company.country, fontSize: 8),
            if ((settings.receiptFooterMessage ?? '').isNotEmpty)
              _center(settings.receiptFooterMessage!, fontSize: 9, bold: true),
            // Feed space is part of a finite page height. This is more stable
            // than double.infinity with Windows thermal printer drivers.
            pw.SizedBox(height: _safeBottomFeedMm(settings) * PdfPageFormat.mm),
          ],
        ),
      ),
    );

    return doc.save();
  }

  double _estimatedReceiptHeightMm(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    final lineCount = math.max(data.lines.length, 1);
    final summaryCount = _receiptRows(data, settings).length;
    final footerLines = [
      data.company.phone,
      data.company.country,
      settings.receiptFooterMessage,
    ].where((value) => (value ?? '').trim().isNotEmpty).length;
    final paymentLines = (data.payment?.paymentMethod ?? '').isNotEmpty ? 1 : 0;

    final header = 38.0;
    final table = 14.0 + (lineCount * 11.5);
    final summary = 10.0 + (summaryCount * 7.0);
    final payment = paymentLines * 9.0;
    final footer = footerLines * 6.5;
    final separators = 18.0;
    final feed = _safeBottomFeedMm(settings);

    return math.max(
      120.0,
      header + table + summary + payment + footer + separators + feed,
    );
  }

  double _safeBottomFeedMm(PrintingSettingsModel settings) {
    return settings.thermalWidth == ThermalWidth.mm58 ? 28.0 : 32.0;
  }

  // ─────────────────────────────────────────────
  // Header: Logo (left) + Invoice info (right)
  // ─────────────────────────────────────────────
  pw.Widget _buildHeader(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
    pw.ImageProvider? logo,
  ) {
    final pw.Widget logoWidget;
    if (settings.showLogo && logo != null) {
      logoWidget = pw.Image(logo, width: 28, height: 28, fit: pw.BoxFit.contain);
    } else if (settings.showLogo) {
      logoWidget = pw.Container(
        width: 28,
        height: 28,
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        child: pw.Center(
          child: pw.Text('LOGO', style: const pw.TextStyle(fontSize: 5)),
        ),
      );
    } else {
      logoWidget = pw.SizedBox(width: 0, height: 0);
    }

    final infoLines = <pw.Widget>[
      pw.Text(
        _arabicDocumentTitle(data.documentType),
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(
        '${_getNumberLabel(data.documentType)}: ${data.documentNumber}',
        textDirection: pw.TextDirection.rtl,
        style: const pw.TextStyle(fontSize: 8),
      ),
      pw.Text(
        'التاريخ: ${_formatDateTime(data.documentDate)}',
        textDirection: pw.TextDirection.rtl,
        style: const pw.TextStyle(fontSize: 8),
      ),
      if ((data.createdByName ?? '').isNotEmpty)
        pw.Text(
          'المستخدم: ${data.createdByName}',
          textDirection: pw.TextDirection.rtl,
          style: const pw.TextStyle(fontSize: 8),
        ),
      pw.Text(
        '${data.arabicPartyLabel}: ${data.customer.displayName}',
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Directionality(
          textDirection: pw.TextDirection.ltr,
          child: logoWidget,
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: infoLines,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Items table: 4 columns (إجمالي | سعر | كمية | اسم الصنف)
  // ─────────────────────────────────────────────
  pw.Widget _itemsTable(DocumentPrintDataModel data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: .45),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2), // الإجمالي
        1: pw.FlexColumnWidth(1.0), // السعر
        2: pw.FlexColumnWidth(0.7), // الكمية
        3: pw.FlexColumnWidth(2.5), // اسم الصنف
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _tableCell('الإجمالي', bold: true),
            _tableCell('السعر', bold: true),
            _tableCell('الكمية', bold: true),
            _tableCell('اسم الصنف', bold: true, align: pw.TextAlign.right),
          ],
        ),
        ...data.lines.map(
          (line) => pw.TableRow(
            children: [
              _tableCell(line.lineTotal.toStringAsFixed(2)),
              _tableCell(line.unitPrice.toStringAsFixed(2)),
              _tableCell(_qty(line.quantity)),
              _tableCell(
                line.description.isNotEmpty ? line.description : line.itemName,
                bold: true,
                align: pw.TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _tableCell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: pw.Directionality(
        textDirection: _hasArabic(text)
            ? pw.TextDirection.rtl
            : pw.TextDirection.ltr,
        child: pw.Text(
          text,
          textAlign: align,
          maxLines: 2,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Amount row: value (LTR) ←→ label (RTL)
  // ─────────────────────────────────────────────
  pw.Widget _amountRow(
    String label,
    double amount, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              amount.toStringAsFixed(2),
              style: pw.TextStyle(
                fontSize: bold ? 13 : 9.5,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: bold ? 13 : 9.5,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Key-value row (e.g. payment method)
  // ─────────────────────────────────────────────
  pw.Widget _kvRtl(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Centred text
  // ─────────────────────────────────────────────
  pw.Widget _center(String text, {double fontSize = 8, bool bold = false}) {
    return pw.Directionality(
      textDirection: _hasArabic(text)
          ? pw.TextDirection.rtl
          : pw.TextDirection.ltr,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Dashed separator line
  // ─────────────────────────────────────────────
  pw.Widget _dashedLine(PrintingSettingsModel settings) {
    final marks = settings.thermalWidth == ThermalWidth.mm58
        ? '- - - - - - - - - - - - - - - -'
        : '- - - - - - - - - - - - - - - - - - - - -';
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        marks,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 7),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────
  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime date) =>
      '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _qty(double value) => value.truncateToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  List<(String, double, bool)> _receiptRows(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    final rows = <(String, double, bool)>[];
    rows.add((_getSubtotalLabel(data.documentType), data.subtotal, false));
    if (data.discountAmount != 0) {
      rows.add(('الخصم', data.discountAmount, false));
    }
    if (settings.showTaxSummary && data.taxAmount != 0) {
      rows.add(('الضريبة', data.taxAmount, false));
    }
    rows.add(('الإجمالي', data.totalAmount, true));
    if (data.paidAmount != 0) rows.add(('المدفوع', data.paidAmount, false));
    if (data.balanceDue != 0) rows.add(('المتبقي', data.balanceDue, true));
    return rows;
  }

  bool _hasArabic(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  String _arabicDocumentTitle(String type) {
    final normalized = type.toLowerCase().trim().replaceAll(' ', '-').replaceAll('_', '-');
    switch (normalized) {
      case 'invoice':
        return 'فاتورة بيع';
      case 'sales-receipt' || 'salesreceipt':
        return 'إيصال بيع';
      case 'estimate':
        return 'عرض سعر';
      case 'sales-return' || 'salesreturn':
        return 'مرتجع بيع';
      case 'purchase-order' || 'purchaseorder':
        return 'أمر شراء';
      case 'receive-inventory' || 'receiveinventory' || 'inventory-receipt' || 'inventoryreceipt':
        return 'إذن استلام مخزون';
      case 'inventory-adjustment' || 'inventoryadjustment':
        return 'تسوية مخزون';
      default:
        if (normalized.contains('receipt')) return 'إيصال بيع';
        if (normalized.contains('invoice')) return 'فاتورة بيع';
        if (normalized.contains('return')) return 'مرتجع بيع';
        if (normalized.contains('estimate')) return 'عرض سعر';
        if (normalized.contains('purchase')) return 'أمر شراء';
        if (normalized.contains('receive') || normalized.contains('receipt')) return 'إذن استلام مخزون';
        if (normalized.contains('adjustment')) return 'تسوية مخزون';
        return type;
    }
  }

  String _getNumberLabel(String type) {
    final normalized = type.toLowerCase().trim().replaceAll(' ', '-').replaceAll('_', '-');
    switch (normalized) {
      case 'invoice':
        return 'رقم الفاتورة';
      case 'sales-receipt' || 'salesreceipt':
        return 'رقم الإيصال';
      case 'estimate':
        return 'رقم عرض السعر';
      case 'sales-return' || 'salesreturn':
        return 'رقم إذن المرتجع';
      case 'purchase-order' || 'purchaseorder':
        return 'رقم أمر الشراء';
      case 'receive-inventory' || 'receiveinventory' || 'inventory-receipt' || 'inventoryreceipt':
        return 'رقم إذن الاستلام';
      case 'inventory-adjustment' || 'inventoryadjustment':
        return 'رقم التسوية';
      default:
        return 'رقم المستند';
    }
  }

  String _getSubtotalLabel(String type) {
    final normalized = type.toLowerCase().trim().replaceAll(' ', '-').replaceAll('_', '-');
    switch (normalized) {
      case 'invoice':
        return 'قيمة الفاتورة';
      case 'sales-receipt' || 'salesreceipt':
        return 'قيمة الإيصال';
      default:
        return 'قيمة المستند';
    }
  }
}

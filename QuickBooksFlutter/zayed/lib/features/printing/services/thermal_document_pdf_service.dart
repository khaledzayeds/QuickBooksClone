// thermal_document_pdf_service.dart

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
    final logo = await assetLoader.loadLogo(settings, thermalOptimized: true);
    final arabicFont = await assetLoader.loadArabicFont(settings);
    final theme = arabicFont == null
        ? null
        : pw.ThemeData.withFont(base: arabicFont, bold: arabicFont);
    final doc = pw.Document(theme: theme);
    final pageWidth = settings.thermalWidth.widthMillimeters * PdfPageFormat.mm;
    final margin = settings.thermalWidth == ThermalWidth.mm58
        ? 3 * PdfPageFormat.mm
        : 5 * PdfPageFormat.mm;
    final pageHeight = _estimatedReceiptHeight(data, settings);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight, marginAll: margin),
        textDirection: pw.TextDirection.rtl,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _buildHeader(data, settings, logo),
            _dashedLine(settings),
            _itemsTable(data, settings),
            _dashedLine(settings),
            _totalsBox(data, settings),
            _dashedLine(settings),
            if ((data.payment?.paymentMethod ?? '').isNotEmpty) ...[
              _kvRtl(
                _label(settings, 'طريقة الدفع', 'Payment method'),
                data.payment!.paymentMethod!,
                settings,
              ),
              _dashedLine(settings),
            ],
            if ((data.company.phone ?? '').isNotEmpty)
              _center(
                _isArabic(settings)
                    ? 'تليفون رقم ${data.company.phone}'
                    : 'Phone: ${data.company.phone}',
                fontSize: 8,
              ),
            if ((data.company.country).isNotEmpty)
              _center(data.company.country, fontSize: 8),
            if ((data.notes ?? '').isNotEmpty)
              _center(data.notes!, fontSize: 8),
            if ((settings.receiptFooterMessage ?? '').isNotEmpty)
              _center(settings.receiptFooterMessage!, fontSize: 9, bold: true),
            pw.SizedBox(height: 50 * PdfPageFormat.mm),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ─────────────────────────────────────────────
  //  HEADER  –  logo left | meta right (RTL)
  // ─────────────────────────────────────────────
  pw.Widget _buildHeader(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
    pw.ImageProvider? logo,
  ) {
    final compact = settings.thermalWidth == ThermalWidth.mm58;
    final logoSize = compact ? 30.0 : 40.0;
    final metaSize = compact ? 7.5 : 8.5;
    final customerSize = compact ? 10.0 : 12.0;
    final arabic = _isArabic(settings);
    final infoAlign = arabic ? pw.TextAlign.right : pw.TextAlign.left;
    final infoCrossAxis = arabic
        ? pw.CrossAxisAlignment.end
        : pw.CrossAxisAlignment.start;

    final infoColumn = pw.Column(
      crossAxisAlignment: infoCrossAxis,
      children: [
        if (data.company.companyName.isNotEmpty)
          _smartText(
            data.company.companyName,
            fontSize: compact ? 10.5 : 12.0,
            bold: true,
            align: infoAlign,
          ),
        if ((data.company.legalName ?? '').isNotEmpty)
          _smartText(
            data.company.legalName!,
            fontSize: metaSize,
            align: infoAlign,
          ),
        if (data.company.companyName.isNotEmpty ||
            (data.company.legalName ?? '').isNotEmpty)
          pw.SizedBox(height: 3),
        _metaLine(
          _getNumberLabel(data.documentType, settings),
          data.documentNumber,
          metaSize,
          settings,
        ),
        _metaLine(
          _label(settings, 'التاريخ', 'Date'),
          _formatDateTime(data.documentDate),
          metaSize,
          settings,
        ),
        if ((data.createdByName ?? '').isNotEmpty)
          _metaLine(
            _label(settings, 'المستخدم', 'User'),
            data.createdByName!,
            metaSize,
            settings,
          ),
        pw.SizedBox(height: 3),
        _customerLine(
          _partyLabel(data, settings),
          data.customer.displayName,
          customerSize,
          settings,
        ),
      ],
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: arabic
                  ? [
                      if (settings.showLogo) ...[
                        _logoBox(logo, logoSize),
                        pw.SizedBox(width: 6),
                      ],
                      pw.Expanded(child: infoColumn),
                    ]
                  : [
                      pw.Expanded(child: infoColumn),
                      if (settings.showLogo) ...[
                        pw.SizedBox(width: 6),
                        _logoBox(logo, logoSize),
                      ],
                    ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              _documentTitle(data.documentType, settings),
              textDirection: arabic
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
              style: pw.TextStyle(
                fontSize: compact ? 13.0 : 15.0,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _logoBox(pw.ImageProvider? logo, double size) {
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: logo == null
          ? pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500, width: .5),
              borderRadius: pw.BorderRadius.circular(3),
            )
          : null,
      child: logo == null
          ? pw.Text(
              'LOGO',
              style: pw.TextStyle(
                fontSize: size <= 30 ? 6 : 7,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            )
          : pw.Image(logo, fit: pw.BoxFit.contain),
    );
  }

  pw.Widget _metaLine(
    String label,
    String value,
    double fontSize,
    PrintingSettingsModel settings,
  ) {
    final arabic = _isArabic(settings);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: .5),
      child: pw.Container(
        width: double.infinity,
        alignment: arabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Directionality(
          textDirection: arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          child: pw.RichText(
            textAlign: arabic ? pw.TextAlign.right : pw.TextAlign.left,
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '$label: ',
                  style: pw.TextStyle(
                    fontSize: fontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.TextSpan(
                  text: value,
                  style: pw.TextStyle(fontSize: fontSize),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  pw.Widget _customerLine(
    String label,
    String value,
    double fontSize,
    PrintingSettingsModel settings,
  ) {
    final arabic = _isArabic(settings);
    return pw.Container(
      width: double.infinity,
      alignment: arabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Directionality(
        textDirection: arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        child: pw.RichText(
          textAlign: arabic ? pw.TextAlign.right : pw.TextAlign.left,
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label: ',
                style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.TextSpan(
                text: value,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ITEMS TABLE
  // ─────────────────────────────────────────────
  pw.Widget _itemsTable(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    final compact = settings.thermalWidth == ThermalWidth.mm58;
    final headerSize = compact ? 7.4 : 8.0;
    final cellSize = compact ? 7.2 : 8.0;
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: .7),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.6),
        1: const pw.FlexColumnWidth(1.3),
        2: const pw.FlexColumnWidth(1.3),
        3: const pw.FlexColumnWidth(3.8),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _tableCell(
              _label(settings, 'الإجمالي', 'Total'),
              bold: true,
              fontSize: headerSize,
            ),
            _tableCell(
              _label(settings, 'السعر', 'Price'),
              bold: true,
              fontSize: headerSize,
            ),
            _tableCell(
              _label(settings, 'الكمية', 'Qty'),
              bold: true,
              fontSize: headerSize,
            ),
            _tableCell(
              _label(settings, 'اسم الصنف', 'Item'),
              bold: true,
              fontSize: headerSize,
              align: _isArabic(settings)
                  ? pw.TextAlign.right
                  : pw.TextAlign.left,
            ),
          ],
        ),
        ...data.lines.map(
          (line) => pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _tableCell(_money(line.lineTotal), fontSize: cellSize),
              _tableCell(_money(line.unitPrice), fontSize: cellSize),
              _tableCell(_qty(line.quantity), fontSize: cellSize),
              _itemNameCell(line, fontSize: cellSize),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _tableCell(
    String text, {
    bool bold = false,
    double fontSize = 8,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: _smartText(text, fontSize: fontSize, bold: bold, align: align),
    );
  }

  pw.Widget _itemNameCell(PrintLineModel line, {required double fontSize}) {
    final name = line.itemName.trim();
    final description = line.description.trim();
    final primary = description.isNotEmpty ? description : name;
    final secondary =
        description.isNotEmpty && name.isNotEmpty && name != description
        ? name
        : null;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _smartText(
            primary.isEmpty ? '-' : primary,
            fontSize: fontSize,
            bold: true,
            align: _hasArabic(primary) ? pw.TextAlign.right : pw.TextAlign.left,
          ),
          if (secondary != null) ...[
            pw.SizedBox(height: 1),
            _smartText(
              secondary,
              fontSize: fontSize - .6,
              align: _hasArabic(secondary)
                  ? pw.TextAlign.right
                  : pw.TextAlign.left,
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TOTALS
  // ─────────────────────────────────────────────
  pw.Widget _totalsBox(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Column(
        children: _receiptRows(
          data,
          settings,
        ).map((row) => _amountRow(row.$1, row.$2, bold: row.$3)).toList(),
      ),
    );
  }

  pw.Widget _amountRow(String label, double amount, {bool bold = false}) {
    final fontSize = bold ? 14.0 : 10.0;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              amount.toStringAsFixed(2),
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _kvRtl(String label, String value, PrintingSettingsModel settings) {
    final arabic = _isArabic(settings);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: arabic
            ? [
                pw.Directionality(
                  textDirection: pw.TextDirection.ltr,
                  child: pw.Text(
                    value,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Text(
                  '$label:',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ]
            : [
                pw.Text(
                  '$label:',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────
  pw.Widget _center(String text, {double fontSize = 8, bool bold = false}) {
    return _smartText(
      text,
      fontSize: fontSize,
      bold: bold,
      align: pw.TextAlign.center,
    );
  }

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

  pw.Widget _smartText(
    String text, {
    required double fontSize,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.right,
  }) {
    final direction = _textDirectionFor(text);
    return pw.Directionality(
      textDirection: direction,
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FORMATTING / LABELS / HEIGHT ESTIMATION
  // ─────────────────────────────────────────────
  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime date) =>
      '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _qty(double value) => value.truncateToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  String _money(double value) => value.toStringAsFixed(2);

  List<(String, double, bool)> _receiptRows(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    final rows = <(String, double, bool)>[];
    rows.add((
      _getSubtotalLabel(data.documentType, settings),
      data.subtotal,
      false,
    ));
    if (data.discountAmount != 0) {
      rows.add((
        _label(settings, 'الخصم', 'Discount'),
        data.discountAmount,
        false,
      ));
    }
    if (settings.showTaxSummary && data.taxAmount != 0) {
      rows.add((_label(settings, 'الضريبة', 'Tax'), data.taxAmount, false));
    }
    rows.add((_label(settings, 'الإجمالي', 'Total'), data.totalAmount, true));
    if (data.paidAmount != 0) {
      rows.add((_label(settings, 'المدفوع', 'Paid'), data.paidAmount, false));
    }
    if (data.balanceDue != 0) {
      rows.add((
        _label(settings, 'المتبقي', 'Balance due'),
        data.balanceDue,
        true,
      ));
    }
    return rows;
  }

  bool _hasArabic(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  pw.TextDirection _textDirectionFor(String text) =>
      _hasArabic(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  bool _isArabic(PrintingSettingsModel settings) =>
      settings.languageCode.toLowerCase().startsWith('ar');

  String _label(PrintingSettingsModel settings, String ar, String en) =>
      _isArabic(settings) ? ar : en;

  String _partyLabel(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    if (_isArabic(settings)) {
      return data.arabicPartyLabel;
    }
    return switch (data.partyType.toLowerCase()) {
      'vendor' => 'Vendor',
      'account' => 'Account',
      _ => 'Customer',
    };
  }

  double _estimatedReceiptHeight(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    final lineHeight = settings.thermalWidth == ThermalWidth.mm58 ? 14.0 : 12.0;
    final longLineExtra =
        data.lines
            .where(
              (line) =>
                  (line.description.isNotEmpty
                          ? line.description
                          : line.itemName)
                      .length >
                  (settings.thermalWidth == ThermalWidth.mm58 ? 22 : 32),
            )
            .length *
        5;
    final notesExtra =
        ((data.notes ?? '').isNotEmpty ? 12 : 0) +
        ((settings.receiptFooterMessage ?? '').isNotEmpty ? 10 : 0);
    final heightMm =
        150 +
        (data.lines.length * lineHeight) +
        longLineExtra +
        notesExtra +
        50;
    final safeHeightMm = heightMm < 240 ? 240.0 : heightMm;
    return safeHeightMm * PdfPageFormat.mm;
  }

  String _documentTitle(String type, PrintingSettingsModel settings) {
    final normalized = normalizePrintDocumentType(type);
    if (!_isArabic(settings)) {
      return switch (normalized) {
        'invoice' => 'Invoice',
        'sales-receipt' => 'Sales Receipt',
        'estimate' => 'Estimate',
        'sales-return' => 'Sales Return',
        'purchase-order' => 'Purchase Order',
        'receive-inventory' => 'Receive Inventory',
        'inventory-adjustment' => 'Inventory Adjustment',
        _ => type,
      };
    }
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
      case 'receive-inventory' ||
          'receiveinventory' ||
          'inventory-receipt' ||
          'inventoryreceipt':
        return 'إذن استلام مخزون';
      case 'inventory-adjustment' || 'inventoryadjustment':
        return 'تسوية مخزون';
      default:
        if (normalized.contains('invoice')) return 'فاتورة بيع';
        if (normalized.contains('receipt')) return 'إيصال بيع';
        if (normalized.contains('return')) return 'مرتجع بيع';
        if (normalized.contains('estimate')) return 'عرض سعر';
        if (normalized.contains('purchase')) return 'أمر شراء';
        if (normalized.contains('receive')) return 'إذن استلام مخزون';
        if (normalized.contains('adjustment')) return 'تسوية مخزون';
        return type;
    }
  }

  String _getNumberLabel(String type, PrintingSettingsModel settings) {
    final normalized = normalizePrintDocumentType(type);
    if (!_isArabic(settings)) {
      return switch (normalized) {
        'invoice' => 'Invoice no.',
        'sales-receipt' => 'Receipt no.',
        'estimate' => 'Estimate no.',
        'sales-return' => 'Return no.',
        'purchase-order' => 'PO no.',
        'receive-inventory' => 'Receive no.',
        'inventory-adjustment' => 'Adjustment no.',
        _ => 'Document no.',
      };
    }
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
      case 'receive-inventory' ||
          'receiveinventory' ||
          'inventory-receipt' ||
          'inventoryreceipt':
        return 'رقم إذن الاستلام';
      case 'inventory-adjustment' || 'inventoryadjustment':
        return 'رقم التسوية';
      default:
        return 'رقم المستند';
    }
  }

  String _getSubtotalLabel(String type, PrintingSettingsModel settings) {
    final normalized = normalizePrintDocumentType(type);
    if (!_isArabic(settings)) {
      return switch (normalized) {
        'invoice' => 'Invoice value',
        'sales-receipt' => 'Receipt value',
        _ => 'Document value',
      };
    }
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

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
    final logo = await assetLoader.loadLogo(settings);
    final arabicFont = await assetLoader.loadArabicFont(settings);
    final theme = arabicFont == null
        ? null
        : pw.ThemeData.withFont(base: arabicFont, bold: arabicFont);
    final doc = pw.Document(theme: theme);
    final pageWidth = settings.thermalWidth.widthMillimeters * PdfPageFormat.mm;
    final margin = settings.thermalWidth == ThermalWidth.mm58
        ? 3 * PdfPageFormat.mm
        : 5 * PdfPageFormat.mm;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          pageWidth,
          double.infinity,
          marginAll: margin,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (settings.showLogo && logo != null)
              pw.Center(
                child: pw.Image(
                  logo,
                  width: 42,
                  height: 42,
                  fit: pw.BoxFit.contain,
                ),
              )
            else if (settings.showLogo)
              _center('الشعار', fontSize: 8),
            _center(data.company.companyName, fontSize: 15, bold: true),
            if (settings.showCompanyAddress)
              _center(data.company.country, fontSize: 8),
            if ((data.company.phone ?? '').isNotEmpty)
              _center('تليفون: ${data.company.phone}', fontSize: 8),
            if ((data.company.email ?? '').isNotEmpty)
              _center(data.company.email!, fontSize: 8),
            _divider(settings),
            _center(
              _arabicDocumentTitle(data.documentType),
              fontSize: 13,
              bold: true,
            ),
            pw.SizedBox(height: 4),
            _kv('رقم الفاتورة', data.documentNumber),
            _kv('التاريخ', _formatDateTime(data.documentDate)),
            _kv(data.arabicPartyLabel, data.customer.displayName),
            if ((data.payment?.paymentMethod ?? '').isNotEmpty)
              _kv('طريقة الدفع', data.payment!.paymentMethod!),
            _divider(settings),
            _itemsTable(data),
            _divider(settings),
            ..._receiptRows(data, settings).map(
              (row) => _amountRow(
                row.$1,
                row.$2,
                data.company.currency,
                bold: row.$3,
              ),
            ),
            _divider(settings),
            if ((settings.receiptFooterMessage ?? '').isNotEmpty)
              _center(settings.receiptFooterMessage!, fontSize: 9, bold: true),
            _center('نتمنى لكم يوماً سعيداً', fontSize: 8),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _itemsTable(DocumentPrintDataModel data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: .45),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(2.7),
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
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  pw.Widget _amountRow(
    String label,
    double amount,
    String currency, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Row(
          children: [
            pw.Text(
              '${amount.toStringAsFixed(2)} $currency',
              style: pw.TextStyle(
                fontSize: bold ? 15 : 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
            pw.Expanded(
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  label,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: bold ? 15 : 10,
                    fontWeight: bold
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _kv(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.left,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(
              width: 78,
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  '$label:',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  pw.Widget _divider(PrintingSettingsModel settings) {
    final marks = settings.thermalWidth == ThermalWidth.mm58
        ? '------------------------'
        : '--------------------------------';
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Text(
        marks,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 8),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatDateTime(DateTime date) =>
      '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _qty(double value) => value.truncateToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  String _arabicDocumentTitle(String type) {
    final normalized = type.toLowerCase().replaceAll(' ', '-');
    if (normalized.contains('receipt')) return 'فاتورة بيع';
    if (normalized.contains('invoice')) return 'فاتورة بيع';
    if (normalized.contains('return')) return 'مرتجع بيع';
    if (normalized.contains('estimate')) return 'عرض سعر';
    if (normalized.contains('purchase')) return 'أمر شراء';
    if (normalized.contains('adjustment')) return 'تسوية مخزون';
    if (normalized.contains('deposit')) return 'إيداع بنكي';
    return type;
  }

  List<(String, double, bool)> _receiptRows(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    final rows = <(String, double, bool)>[];
    rows.add(('قيمة الفاتورة', data.subtotal, false));
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
}

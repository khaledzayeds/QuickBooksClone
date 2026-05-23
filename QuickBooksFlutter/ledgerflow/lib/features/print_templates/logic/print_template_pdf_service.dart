import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models/print_element_model.dart';
import '../data/models/print_template_model.dart';
import '../../printing/data/models/print_data_contracts.dart';
import '../../printing/services/printing_asset_loader.dart';
import '../../settings/data/models/printing_settings_model.dart';
import 'template_field_registry.dart';

class PrintTemplatePdfService {
  const PrintTemplatePdfService();

  Future<void> preview(PrintTemplateModel template) async {
    await Printing.layoutPdf(
      name: template.name,
      onLayout: (_) async => build(template),
    );
  }

  Future<Uint8List> build(
    PrintTemplateModel template, {
    DocumentPrintDataModel? data,
    PrintingSettingsModel? settings,
  }) async {
    pw.Font? font;
    if (settings != null && settings.useArabicFonts == true) {
      font = await const PrintingAssetLoader().loadArabicFont(settings);
    }
    font ??= await _loadFallbackFont();

    final doc = pw.Document(
      theme: font == null
          ? null
          : pw.ThemeData.withFont(
              base: font,
              bold: font,
              italic: font,
              fontFallback: [font],
            ),
    );
    final pageFormat = PdfPageFormat(
      template.page.effectiveWidthMm * PdfPageFormat.mm,
      template.page.effectiveHeightMm * PdfPageFormat.mm,
      marginAll: 0,
    );

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => pw.Stack(
          children: template.elements
              .map((element) => _element(element, data: data))
              .toList(),
        ),
      ),
    );

    return doc.save();
  }

  Future<pw.Font?> _loadFallbackFont() async {
    final assetFont = await _tryLoadFirstAssetFont(bold: false);
    if (assetFont != null) return assetFont;

    try {
      return await PdfGoogleFonts.notoNaskhArabicRegular();
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
        if (lower.contains('amiri')) value += 25;
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

  pw.Widget _element(
    PrintElementModel element, {
    DocumentPrintDataModel? data,
  }) {
    return pw.Positioned(
      left: element.x * PdfPageFormat.mm,
      top: element.y * PdfPageFormat.mm,
      child: pw.Container(
        width: element.width * PdfPageFormat.mm,
        height: element.height * PdfPageFormat.mm,
        decoration: pw.BoxDecoration(
          color: _bg(element),
          border: element.type == 'line'
              ? null
              : pw.Border.all(
                  color: PdfColors.grey600,
                  width: element.style.borderWidth <= 0
                      ? 0.2
                      : element.style.borderWidth,
                ),
        ),
        padding: pw.EdgeInsets.all(element.style.padding),
        child: _body(element, data: data),
      ),
    );
  }

  pw.Widget _body(PrintElementModel element, {DocumentPrintDataModel? data}) {
    switch (element.type) {
      case 'line':
        return pw.Center(
          child: pw.Container(height: 0.7, color: PdfColors.black),
        );
      case 'rectangle':
        return pw.SizedBox();
      case 'table':
        return _table(element, data: data);
      case 'qr':
        return pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: _textValue(element, data: data),
          drawText: false,
        );
      case 'barcode':
        return pw.BarcodeWidget(
          barcode: pw.Barcode.code128(),
          data: _textValue(element, data: data),
          drawText: false,
        );
      case 'field':
      case 'text':
      default:
        return pw.Text(
          _textValue(element, data: data),
          maxLines: 3,
          textDirection: _containsArabic(_textValue(element, data: data))
              ? pw.TextDirection.rtl
              : null,
          textAlign: _align(element.style.align),
          style: pw.TextStyle(
            fontSize: element.style.fontSize,
            fontWeight: element.style.bold
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
            fontStyle: element.style.italic
                ? pw.FontStyle.italic
                : pw.FontStyle.normal,
          ),
        );
    }
  }

  pw.Widget _table(PrintElementModel element, {DocumentPrintDataModel? data}) {
    final lines = data?.lines ?? const <PrintLineModel>[];
    final rowCount = lines.isEmpty ? 5 : lines.length;
    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.3),
        columnWidths: {
          for (var i = 0; i < element.columns.length; i++)
            i: pw.FlexColumnWidth(element.columns[i].width),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: element.columns
                .map(
                  (column) => _tableTextCell(
                    column.title,
                    fontSize: element.style.fontSize,
                    bold: true,
                  ),
                )
                .toList(),
          ),
          for (var row = 0; row < rowCount; row++)
            pw.TableRow(
              children: element.columns
                  .map(
                    (column) => _tableTextCell(
                      lines.isEmpty
                          ? (row == 0 ? _sampleCell(column.field) : '')
                          : _lineCell(lines[row], column.field, data),
                      fontSize: element.style.fontSize,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  pw.Widget _tableTextCell(
    String text, {
    required double fontSize,
    bool bold = false,
  }) {
    final rtl = _containsArabic(text);
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Directionality(
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        child: pw.Text(
          text,
          textAlign: rtl ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _textValue(PrintElementModel element, {DocumentPrintDataModel? data}) {
    if (data != null) {
      final source = element.binding?.isNotEmpty == true
          ? element.binding
          : element.value;
      final value = _boundValue(source, data);
      if (value != null) return value;
      return _interpolate(source ?? '', data);
    }
    if (element.type == 'field') {
      return TemplateFieldRegistry.previewValue(
        element.binding,
        fallback: element.value,
      );
    }
    return TemplateFieldRegistry.interpolatePreview(
      element.value.isEmpty ? (element.binding ?? '') : element.value,
    );
  }

  String _interpolate(String source, DocumentPrintDataModel data) {
    return source.replaceAllMapped(RegExp(r'\{\{([^}]+)\}\}'), (match) {
      final value = _boundValue(match.group(0), data);
      return value ?? match.group(0) ?? '';
    });
  }

  String? _boundValue(String? binding, DocumentPrintDataModel data) {
    // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
    var key = _normalizeBinding(binding);
    if (key.isEmpty) return null;

    // Normalize prefix (e.g. estimate.number -> document.number)
    for (final docType in ['invoice', 'salesreceipt', 'estimate', 'salesreturn', 'purchaseorder', 'receiveinventory', 'inventoryadjustment']) {
      if (key.startsWith('$docType.')) {
        key = 'document.${key.substring(docType.length + 1)}';
        break;
      }
    }
    // END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
    switch (key) {
      case 'company.name':
      case 'companyname':
        return data.company.companyName;
      case 'company.legalname':
        return data.company.legalName;
      case 'company.phone':
        return data.company.phone;
      case 'company.email':
        return data.company.email;
      case 'company.address':
        return data.company.country;
      case 'company.currency':
        return data.company.currency;
      case 'company.country':
        return data.company.country;
      case 'customer.name':
      case 'customer.displayname':
      case 'customername':
      case 'party.name':
      case 'party.displayname':
        return data.customer.displayName;
      case 'party.label':
        return data.partyLabel;
      case 'party.type':
        return data.partyType;
      case 'customer.phone':
      case 'party.phone':
        return data.customer.phone;
      case 'customer.email':
      case 'party.email':
        return data.customer.email;
      case 'customer.balance':
        return _money(data.customer.openBalance, data.customer.currency);
      case 'customer.credits':
        return _money(data.customer.creditBalance, data.customer.currency);
      case 'invoice.number':
      case 'document.number':
      case 'number':
        return data.documentNumber;
      case 'invoice.type':
      case 'document.type':
        return data.documentType;
      case 'invoice.status':
      case 'document.status':
        return data.status;
      case 'invoice.date':
      case 'document.date':
      case 'date':
        return _date(data.documentDate);
      case 'invoice.duedate':
      case 'document.duedate':
        return _date(data.dueDate);
      case 'invoice.subtotal':
      case 'document.subtotal':
      case 'subtotal':
        return _money(data.subtotal, data.company.currency);
      case 'invoice.discount':
      case 'document.discount':
        return _money(data.discountAmount, data.company.currency);
      case 'invoice.tax':
      case 'document.tax':
        return _money(data.taxAmount, data.company.currency);
      case 'invoice.total':
      case 'document.total':
      case 'total':
        return _money(data.totalAmount, data.company.currency);
      case 'invoice.paid':
      case 'document.paid':
        return _money(data.paidAmount, data.company.currency);
      case 'invoice.balance':
      case 'document.balance':
        return _money(data.balanceDue, data.company.currency);
      case 'invoice.creditapplied':
      case 'document.creditapplied':
        return _money(data.creditAppliedAmount, data.company.currency);
      case 'invoice.returned':
      case 'document.returned':
        return _money(data.returnedAmount, data.company.currency);
      case 'invoice.terms':
      case 'document.terms':
        return data.terms;
      case 'invoice.notes':
      case 'document.notes':
      case 'notes':
        return data.notes;
      case 'invoice.qrpayload':
      case 'document.qrpayload':
      case 'qr':
        return '${data.company.companyName}|${data.documentType}|${data.documentNumber}|${data.totalAmount.toStringAsFixed(2)}';
      case 'payment.method':
      case 'invoice.paymentmethod':
      case 'document.paymentmethod':
        return data.payment?.paymentMethod;
      case 'payment.depositaccount':
      case 'invoice.depositaccount':
      case 'document.depositaccount':
        return data.payment?.depositAccountName;
      // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
      case 'user.name':
      case 'document.createdby':
      case 'createdby':
        return data.createdByName;
      // END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
    }
    return null;
  }

  String _lineCell(
    PrintLineModel line,
    String field,
    DocumentPrintDataModel? data,
  ) {
    switch (_normalizeBinding(field)) {
      case 'item':
      case 'itemname':
      case 'item.name':
        return line.itemName;
      case 'description':
      case 'item.description':
        return line.description;
      case 'quantity':
      case 'qty':
        return _number(line.quantity);
      case 'unitprice':
      case 'price':
        return _money(line.unitPrice, data?.company.currency ?? '');
      case 'discount':
      case 'discountpercent':
        return '${_number(line.discountPercent)}%';
      case 'tax':
      case 'taxrate':
        return '${_number(line.taxRatePercent)}%';
      case 'taxamount':
        return _money(line.taxAmount, data?.company.currency ?? '');
      case 'linetotal':
      case 'amount':
      case 'total':
        return _money(line.lineTotal, data?.company.currency ?? '');
      default:
        return '';
    }
  }

  String _sampleCell(String field) {
    switch (field) {
      case 'itemName':
        return 'تيشيرت';
      case 'quantity':
        return '1';
      case 'unitPrice':
        return '100';
      case 'description':
        return 'صنف تجريبي';
      case 'lineTotal':
        return '100';
      default:
        return '';
    }
  }

  String _normalizeBinding(String? value) {
    return (value ?? '')
        .replaceAll('{{', '')
        .replaceAll('}}', '')
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .toLowerCase();
  }

  bool _containsArabic(String value) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  }

  String _date(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _number(num value) {
    final asDouble = value.toDouble();
    return asDouble.truncateToDouble() == asDouble
        ? asDouble.toStringAsFixed(0)
        : asDouble.toStringAsFixed(2);
  }

  String _money(num value, String currency) {
    final suffix = currency.isEmpty ? '' : ' $currency';
    return '${value.toStringAsFixed(2)}$suffix';
  }

  PdfColor? _bg(PrintElementModel element) {
    if (element.type == 'rectangle') return PdfColors.grey200;
    return null;
  }

  pw.TextAlign _align(String align) {
    if (align == 'center') return pw.TextAlign.center;
    if (align == 'right') return pw.TextAlign.right;
    return pw.TextAlign.left;
  }
}

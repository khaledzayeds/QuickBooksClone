// a4_document_pdf_service.dart

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../settings/data/models/printing_settings_model.dart';
import '../data/models/print_data_contracts.dart';
import 'printing_asset_loader.dart';

class A4DocumentPdfService {
  const A4DocumentPdfService({this.assetLoader = const PrintingAssetLoader()});

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
    final margin = switch (settings.a4TemplateStyle) {
      A4TemplateStyle.compact => 20.0,
      A4TemplateStyle.classic => 32.0,
      A4TemplateStyle.modern => 28.0,
    };

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(margin),
        textDirection: _isArabic(settings)
            ? pw.TextDirection.rtl
            : pw.TextDirection.ltr,
        build: (context) => [
          _header(data, settings, logo),
          pw.SizedBox(
            height: settings.a4TemplateStyle == A4TemplateStyle.compact
                ? 12
                : 18,
          ),
          _partyAndMeta(data, settings),
          pw.SizedBox(
            height: settings.a4TemplateStyle == A4TemplateStyle.compact
                ? 12
                : 18,
          ),
          _linesTable(data, settings),
          pw.SizedBox(height: 14),
          _summary(data, settings),
          if ((data.terms ?? '').isNotEmpty ||
              (data.notes ?? '').isNotEmpty ||
              (settings.invoiceFooterMessage ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _notes(data, settings),
          ],
        ],
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${_label(settings, 'تم الإنشاء', 'Generated')}: ${_formatDateTime(data.generatedAt)}',
              textDirection: _direction(settings),
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              _isArabic(settings)
                  ? 'صفحة ${context.pageNumber} من ${context.pagesCount}'
                  : 'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _header(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
    pw.ImageProvider? logo,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (settings.showLogo)
                pw.Container(
                  width: 46,
                  height: 46,
                  alignment: pw.Alignment.center,
                  margin: const pw.EdgeInsets.only(right: 10),
                  decoration: logo == null
                      ? pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey500,
                            width: .5,
                          ),
                          borderRadius: pw.BorderRadius.circular(4),
                        )
                      : null,
                  child: logo == null
                      ? pw.Text(
                          _label(settings, 'شعار', 'LOGO'),
                          style: const pw.TextStyle(fontSize: 8),
                        )
                      : pw.Image(logo, fit: pw.BoxFit.contain),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      data.company.companyName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if ((data.company.legalName ?? '').isNotEmpty)
                      pw.Text(data.company.legalName!),
                    if (settings.showCompanyAddress)
                      pw.Text(
                        '${data.company.country} - ${data.company.currency}',
                      ),
                    if ((data.company.phone ?? '').isNotEmpty)
                      pw.Text(
                        '${_label(settings, 'تليفون', 'Phone')}: ${data.company.phone}',
                        textDirection: _direction(settings),
                      ),
                    if ((data.company.email ?? '').isNotEmpty)
                      pw.Text(
                        '${_label(settings, 'البريد الإلكتروني', 'Email')}: ${data.company.email}',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              _documentTitle(data.documentType, settings),
              textDirection: _direction(settings),
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              '${_documentNumberLabel(data.documentType, settings)}: ${data.documentNumber}',
              textDirection: _direction(settings),
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                data.status,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _partyAndMeta(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _box(_partyLabel(data, settings), settings, [
            pw.Text(
              data.customer.displayName,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            if ((data.customer.phone ?? '').isNotEmpty)
              pw.Text(
                '${_label(settings, 'تليفون', 'Phone')}: ${data.customer.phone}',
                textDirection: _direction(settings),
              ),
            if ((data.customer.email ?? '').isNotEmpty)
              pw.Text(
                '${_label(settings, 'البريد الإلكتروني', 'Email')}: ${data.customer.email}',
              ),
            if (settings.showCustomerBalance && data.isCustomerParty) ...[
              pw.Text(
                '${_label(settings, 'الرصيد', 'Balance')}: ${_money(data.customer.openBalance, data.customer.currency)}',
                textDirection: _direction(settings),
              ),
              pw.Text(
                '${_label(settings, 'الائتمان', 'Credit')}: ${_money(data.customer.creditBalance, data.customer.currency)}',
                textDirection: _direction(settings),
              ),
            ],
          ]),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _box(
            _label(settings, 'بيانات المستند', 'Document details'),
            settings,
            [
              _kv(
                _documentNumberLabel(data.documentType, settings),
                data.documentNumber,
                settings,
              ),
              _kv(
                _label(settings, 'التاريخ', 'Date'),
                _formatDate(data.documentDate),
                settings,
              ),
              _kv(
                _label(settings, 'تاريخ الاستحقاق', 'Due date'),
                _formatDate(data.dueDate),
                settings,
              ),
              _kv(_label(settings, 'الحالة', 'Status'), data.status, settings),
              if ((data.createdByName ?? '').isNotEmpty)
                _kv(
                  _label(settings, 'المستخدم', 'User'),
                  data.createdByName!,
                  settings,
                ),
              if ((data.payment?.paymentMethod ?? '').isNotEmpty)
                _kv(
                  _label(settings, 'الدفع', 'Payment'),
                  data.payment!.paymentMethod!,
                  settings,
                ),
              if ((data.payment?.depositAccountName ?? '').isNotEmpty)
                _kv(
                  _label(settings, 'الإيداع', 'Deposit'),
                  data.payment!.depositAccountName!,
                  settings,
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _linesTable(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    final headers = [
      _label(settings, 'الإجمالي', 'Total'),
      if (settings.showTaxSummary) _label(settings, 'الضريبة', 'Tax'),
      _label(settings, 'السعر', 'Price'),
      _label(settings, 'الكمية', 'Qty'),
      settings.showItemSku
          ? _label(settings, 'الصنف / الكود', 'Item / SKU')
          : _label(settings, 'الصنف', 'Item'),
      '#',
    ];
    final rows = data.lines
        .map(
          (line) => [
            _money(line.lineTotal, data.company.currency),
            if (settings.showTaxSummary)
              _money(line.taxAmount, data.company.currency),
            _money(line.unitPrice, data.company.currency),
            _qty(line.quantity),
            line.description.isNotEmpty ? line.description : line.itemName,
            line.lineNumber.toString(),
          ],
        )
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignment: pw.Alignment.center,
      cellPadding: pw.EdgeInsets.all(
        settings.a4TemplateStyle == A4TemplateStyle.compact ? 3 : 5,
      ),
    );
  }

  pw.Widget _summary(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    final rows = settings.showTaxSummary
        ? data.summaryRows
        : data.summaryRows
              .where((row) => row.label.toLowerCase() != 'tax')
              .toList();
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 210,
        child: pw.Column(
          children: rows
              .map(
                (row) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          _summaryLabel(row.label, settings),
                          textDirection: _direction(settings),
                          style: pw.TextStyle(
                            fontWeight: row.isStrong
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                          ),
                        ),
                      ),
                      pw.Text(
                        _money(row.amount, data.company.currency),
                        style: pw.TextStyle(
                          fontWeight: row.isStrong
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  pw.Widget _notes(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    return _box(_label(settings, 'ملاحظات', 'Notes'), settings, [
      if ((data.terms ?? '').isNotEmpty)
        pw.Text(
          '${_label(settings, 'الشروط', 'Terms')}: ${data.terms}',
          textDirection: _direction(settings),
        ),
      if ((data.notes ?? '').isNotEmpty)
        pw.Text(data.notes!, textDirection: _direction(settings)),
      if ((settings.invoiceFooterMessage ?? '').isNotEmpty)
        pw.Text(
          settings.invoiceFooterMessage!,
          textDirection: _direction(settings),
        ),
    ]);
  }

  pw.Widget _box(
    String title,
    PrintingSettingsModel settings,
    List<pw.Widget> children,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: .5),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            textDirection: _direction(settings),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _kv(String label, String value, PrintingSettingsModel settings) {
    return pw.Row(
      children: [
        pw.Expanded(child: pw.Text(label, textDirection: _direction(settings))),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  String _money(double value, String currency) =>
      '${value.toStringAsFixed(2)} $currency';
  String _qty(double value) => value.truncateToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  String _formatDateTime(DateTime date) =>
      '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  bool _isArabic(PrintingSettingsModel settings) =>
      settings.languageCode.toLowerCase().startsWith('ar');

  pw.TextDirection _direction(PrintingSettingsModel settings) =>
      _isArabic(settings) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  String _label(PrintingSettingsModel settings, String ar, String en) =>
      _isArabic(settings) ? ar : en;

  String _partyLabel(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) {
    if (_isArabic(settings)) return data.arabicPartyLabel;
    return switch (data.partyType.toLowerCase()) {
      'vendor' => 'Vendor',
      'account' => 'Account',
      _ => 'Customer',
    };
  }

  String _documentTitle(String type, PrintingSettingsModel settings) {
    final normalized = normalizePrintDocumentType(type);
    if (!_isArabic(settings)) {
      return switch (normalized) {
        'invoice' => 'Invoice',
        'sales-receipt' || 'salesreceipt' => 'Sales Receipt',
        'estimate' => 'Estimate',
        'sales-return' || 'salesreturn' => 'Sales Return',
        'purchase-order' || 'purchaseorder' => 'Purchase Order',
        'receive-inventory' ||
        'receiveinventory' ||
        'inventory-receipt' ||
        'inventoryreceipt' => 'Receive Inventory',
        'inventory-adjustment' ||
        'inventoryadjustment' => 'Inventory Adjustment',
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

  String _documentNumberLabel(String type, PrintingSettingsModel settings) {
    final normalized = normalizePrintDocumentType(type);
    if (!_isArabic(settings)) {
      return switch (normalized) {
        'invoice' => 'Invoice no.',
        'sales-receipt' || 'salesreceipt' => 'Receipt no.',
        'estimate' => 'Estimate no.',
        'sales-return' || 'salesreturn' => 'Return no.',
        'purchase-order' || 'purchaseorder' => 'PO no.',
        'receive-inventory' ||
        'receiveinventory' ||
        'inventory-receipt' ||
        'inventoryreceipt' => 'Receive no.',
        'inventory-adjustment' || 'inventoryadjustment' => 'Adjustment no.',
        _ => 'Document no.',
      };
    }
    switch (normalized) {
      case 'invoice':
        return 'رقم الفاتورة';
      case 'sales-receipt':
        return 'رقم الإيصال';
      case 'estimate':
        return 'رقم عرض السعر';
      case 'sales-return':
        return 'رقم المرتجع';
      case 'purchase-order':
        return 'رقم أمر الشراء';
      case 'receive-inventory':
        return 'رقم إذن الاستلام';
      case 'inventory-adjustment':
        return 'رقم التسوية';
      default:
        return 'رقم المستند';
    }
  }

  String _summaryLabel(String label, PrintingSettingsModel settings) {
    if (!_isArabic(settings)) return label;
    return switch (label.toLowerCase()) {
      'subtotal' => 'الإجمالي قبل الضريبة',
      'discount' => 'الخصم',
      'tax' => 'الضريبة',
      'total' => 'الإجمالي',
      'paid' => 'المدفوع',
      'credits' => 'ائتمان',
      'returns' => 'مرتجعات',
      'balance due' => 'المتبقي',
      _ => label,
    };
  }
}

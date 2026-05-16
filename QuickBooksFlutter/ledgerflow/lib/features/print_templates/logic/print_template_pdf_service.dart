import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models/print_element_model.dart';
import '../data/models/print_template_model.dart';
import 'template_field_registry.dart';

class PrintTemplatePdfService {
  const PrintTemplatePdfService();

  Future<void> preview(PrintTemplateModel template) async {
    await Printing.layoutPdf(
      name: template.name,
      onLayout: (_) async => build(template),
    );
  }

  Future<Uint8List> build(PrintTemplateModel template) async {
    final doc = pw.Document();
    final pageFormat = PdfPageFormat(
      template.page.effectiveWidthMm * PdfPageFormat.mm,
      template.page.effectiveHeightMm * PdfPageFormat.mm,
      marginAll: 0,
    );

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => pw.Stack(
          children: template.elements.map(_element).toList(),
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _element(PrintElementModel element) {
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
              : pw.Border.all(color: PdfColors.grey600, width: element.style.borderWidth <= 0 ? 0.2 : element.style.borderWidth),
        ),
        padding: pw.EdgeInsets.all(element.style.padding),
        child: _body(element),
      ),
    );
  }

  pw.Widget _body(PrintElementModel element) {
    switch (element.type) {
      case 'line':
        return pw.Center(child: pw.Container(height: 0.7, color: PdfColors.black));
      case 'rectangle':
        return pw.SizedBox();
      case 'table':
        return _table(element);
      case 'qr':
        return pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: _textValue(element),
          drawText: false,
        );
      case 'barcode':
        return pw.BarcodeWidget(
          barcode: pw.Barcode.code128(),
          data: _textValue(element),
          drawText: false,
        );
      case 'field':
      case 'text':
      default:
        return pw.Text(
          _textValue(element),
          maxLines: 3,
          textAlign: _align(element.style.align),
          style: pw.TextStyle(
            fontSize: element.style.fontSize,
            fontWeight: element.style.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontStyle: element.style.italic ? pw.FontStyle.italic : pw.FontStyle.normal,
          ),
        );
    }
  }

  pw.Widget _table(PrintElementModel element) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.3),
      columnWidths: {
        for (var i = 0; i < element.columns.length; i++) i: const pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: element.columns
              .map((column) => pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text(column.title, style: pw.TextStyle(fontSize: element.style.fontSize, fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        for (var row = 0; row < 5; row++)
          pw.TableRow(
            children: element.columns
                .map((column) => pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text(row == 0 ? _sampleCell(column.field) : '', style: pw.TextStyle(fontSize: element.style.fontSize)),
                    ))
                .toList(),
          ),
      ],
    );
  }

  String _textValue(PrintElementModel element) {
    if (element.type == 'field') {
      return TemplateFieldRegistry.previewValue(element.binding, fallback: element.value);
    }
    return element.value.isEmpty ? (element.binding ?? '') : element.value;
  }

  String _sampleCell(String field) {
    switch (field) {
      case 'itemName':
        return 'Sample item';
      case 'quantity':
        return '1';
      case 'unitPrice':
        return '100';
      case 'lineTotal':
        return '100';
      default:
        return '';
    }
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

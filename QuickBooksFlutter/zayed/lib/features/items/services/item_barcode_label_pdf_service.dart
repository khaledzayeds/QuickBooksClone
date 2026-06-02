import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../printing/services/printing_asset_loader.dart';
import '../../settings/data/models/printing_settings_model.dart';
import '../data/models/item_model.dart';

enum ItemBarcodePaper { thermal80, label50x40, a4 }

enum ItemBarcodeLayout { single, triple }

class ItemBarcodePrintLine {
  const ItemBarcodePrintLine({required this.item, required this.quantity});

  final ItemModel item;
  final int quantity;
}

class ItemBarcodeLabelPdfService {
  const ItemBarcodeLabelPdfService({
    this.assetLoader = const PrintingAssetLoader(),
  });

  static const double _thermalLabelWidthMm = 45.0;
  static const double _thermalLabelHeightMm = 23.0;
  static const double _thermalNameFontSize = 6.5;
  static const double _thermalPriceFontSize = 6.5;
  static const double _thermalCodeFontSize = 5.5;
  static const double _thermalFeedGapMm = 16.0;

  final PrintingAssetLoader assetLoader;

  Future<Uint8List> build({
    required List<ItemBarcodePrintLine> lines,
    required PrintingSettingsModel settings,
    ItemBarcodePaper paper = ItemBarcodePaper.thermal80,
    ItemBarcodeLayout layout = ItemBarcodeLayout.single,
    bool showPrice = true,
    bool showCompanyName = false,
    String companyName = 'Zayed',
  }) async {
    final labels = _expand(lines);
    if (labels.isEmpty) {
      throw StateError('No barcode labels selected.');
    }

    final font = await assetLoader.loadArabicFont(settings);
    final theme = font == null
        ? null
        : pw.ThemeData.withFont(base: font, bold: font);

    final pdf = pw.Document(theme: theme);
    if (paper == ItemBarcodePaper.a4) {
      _addA4Page(
        pdf,
        labels,
        showPrice: showPrice,
        showCompanyName: showCompanyName,
        companyName: companyName,
      );
    } else if (paper == ItemBarcodePaper.label50x40) {
      _add50x40LabelPages(
        pdf,
        labels,
        showPrice: showPrice,
        showCompanyName: showCompanyName,
        companyName: companyName,
      );
    } else if (layout == ItemBarcodeLayout.triple) {
      _addThermalTriplePage(
        pdf,
        labels,
        showPrice: showPrice,
        showCompanyName: showCompanyName,
        companyName: companyName,
      );
    } else {
      _addThermalSinglePage(
        pdf,
        labels,
        showPrice: showPrice,
        showCompanyName: showCompanyName,
        companyName: companyName,
      );
    }

    return pdf.save();
  }

  List<ItemModel> _expand(List<ItemBarcodePrintLine> lines) {
    final expanded = <ItemModel>[];
    for (final line in lines) {
      final barcode = line.item.barcode?.trim() ?? '';
      if (barcode.isEmpty || line.quantity <= 0) continue;
      for (var i = 0; i < line.quantity; i++) {
        expanded.add(line.item);
      }
    }
    return expanded;
  }

  void _addA4Page(
    pw.Document pdf,
    List<ItemModel> labels, {
    required bool showPrice,
    required bool showCompanyName,
    required String companyName,
  }) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(
          horizontal: 6 * PdfPageFormat.mm,
          vertical: 10 * PdfPageFormat.mm,
        ),
        build: (_) => [
          pw.Wrap(
            spacing: 3 * PdfPageFormat.mm,
            runSpacing: 4 * PdfPageFormat.mm,
            children: labels
                .map(
                  (item) => _horizontalLabel(
                    item,
                    width: 44 * PdfPageFormat.mm,
                    height: 25 * PdfPageFormat.mm,
                    showPrice: showPrice,
                    showCompanyName: showCompanyName,
                    companyName: companyName,
                    bordered: true,
                    compact: true,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _addThermalSinglePage(
    pw.Document pdf,
    List<ItemModel> labels, {
    required bool showPrice,
    required bool showCompanyName,
    required String companyName,
  }) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.only(
          top: _thermalFeedGapMm * PdfPageFormat.mm,
        ),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: labels
              .map(
                (item) => _horizontalLabel(
                  item,
                  width: PdfPageFormat.roll80.availableWidth,
                  showPrice: showPrice,
                  showCompanyName: showCompanyName,
                  companyName: companyName,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _addThermalTriplePage(
    pw.Document pdf,
    List<ItemModel> labels, {
    required bool showPrice,
    required bool showCompanyName,
    required String companyName,
  }) {
    final rows = <pw.Widget>[];
    for (var i = 0; i < labels.length; i += 3) {
      final rowItems = labels.skip(i).take(3).toList();
      final children = <pw.Widget>[
        for (final item in rowItems)
          pw.Transform.rotateBox(
            angle: 1.5708,
            child: _tripleLabel(
              item,
              showPrice: showPrice,
              showCompanyName: showCompanyName,
              companyName: companyName,
            ),
          ),
      ];
      while (children.length < 3) {
        children.add(
          pw.SizedBox(width: _thermalLabelHeightMm * PdfPageFormat.mm),
        );
      }
      rows.add(
        pw.Container(
          width: PdfPageFormat.roll80.availableWidth,
          margin: const pw.EdgeInsets.only(bottom: 2 * PdfPageFormat.mm),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              children[0],
              pw.SizedBox(width: 1 * PdfPageFormat.mm),
              children[1],
              pw.SizedBox(width: 1 * PdfPageFormat.mm),
              children[2],
            ],
          ),
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.only(
          top: _thermalFeedGapMm * PdfPageFormat.mm,
        ),
        build: (_) => pw.Column(children: rows),
      ),
    );
  }

  void _add50x40LabelPages(
    pw.Document pdf,
    List<ItemModel> labels, {
    required bool showPrice,
    required bool showCompanyName,
    required String companyName,
  }) {
    final pageFormat = PdfPageFormat(
      50 * PdfPageFormat.mm,
      40 * PdfPageFormat.mm,
      marginAll: 0,
    );

    for (final item in labels) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          textDirection: pw.TextDirection.rtl,
          margin: pw.EdgeInsets.zero,
          build: (_) => _label50x40(
            item,
            showPrice: showPrice,
            showCompanyName: showCompanyName,
            companyName: companyName,
          ),
        ),
      );
    }
  }

  pw.Widget _horizontalLabel(
    ItemModel item, {
    required double width,
    double? height,
    required bool showPrice,
    required bool showCompanyName,
    required String companyName,
    bool bordered = false,
    bool compact = false,
  }) {
    final barcode = item.barcode?.trim() ?? '';
    final fixedHeight = height != null;
    final nameFont = compact ? 7.2 : 12.0;
    final priceFont = compact ? 8.0 : 13.0;
    final codeFont = compact ? 7.0 : 10.0;
    final isA4 = compact || bordered;

    return pw.Container(
      width: width,
      height: height,
      padding: isA4
          ? const pw.EdgeInsets.fromLTRB(4, 4, 4, 4)
          : const pw.EdgeInsets.only(left: 4, right: 4),
      decoration: bordered
          ? pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            )
          : null,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisSize: fixedHeight ? pw.MainAxisSize.max : pw.MainAxisSize.min,
        children: [
          if (showCompanyName) ...[
            pw.Text(
              companyName,
              maxLines: 1,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: compact ? 6 : 8),
            ),
            pw.SizedBox(height: compact ? 1 : 3),
          ],
          pw.SizedBox(height: compact ? 4 : 8),
          pw.Padding(
            padding: isA4
                ? const pw.EdgeInsets.all(0)
                : const pw.EdgeInsets.only(left: 12, right: 12),
            child: _itemInfoRow(
              item,
              showPrice: showPrice,
              priceFont: priceFont,
              nameFont: nameFont,
              compact: compact,
            ),
          ),
          pw.SizedBox(height: compact ? 3 : 6),
          pw.Container(
            height: compact ? 8 * PdfPageFormat.mm : 12 * PdfPageFormat.mm,
            alignment: pw.Alignment.center,
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: barcode,
              drawText: false,
              width: compact ? double.infinity : 56 * PdfPageFormat.mm,
              height: compact ? 8 * PdfPageFormat.mm : 12 * PdfPageFormat.mm,
            ),
          ),
          pw.SizedBox(height: compact ? 2 : 3),
          pw.Text(
            barcode,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: codeFont,
              letterSpacing: compact ? 0.8 : 1.5,
            ),
          ),
          if (!compact && !fixedHeight) ...[
            pw.SizedBox(height: 6),
            pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.8),
            pw.SizedBox(height: 14 * PdfPageFormat.mm),
          ],
        ],
      ),
    );
  }

  pw.Widget _itemInfoRow(
    ItemModel item, {
    required bool showPrice,
    required double priceFont,
    required double nameFont,
    required bool compact,
  }) {
    return pw.Row(
      children: [
        if (showPrice)
          pw.Text(
            '${item.salesPrice.toStringAsFixed(2)} ج',
            style: pw.TextStyle(
              fontSize: priceFont,
              fontWeight: pw.FontWeight.bold,
            ),
          )
        else
          pw.SizedBox(width: compact ? 24 : 30),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            item.name,
            maxLines: 2,
            textAlign: _hasArabic(item.name)
                ? pw.TextAlign.right
                : pw.TextAlign.left,
            textDirection: _hasArabic(item.name)
                ? pw.TextDirection.rtl
                : pw.TextDirection.ltr,
            style: pw.TextStyle(
              fontSize: nameFont,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _label50x40(
    ItemModel item, {
    required bool showPrice,
    required bool showCompanyName,
    required String companyName,
  }) {
    final barcode = item.barcode?.trim() ?? '';
    final hasArabicName = _hasArabic(item.name);
    return pw.Container(
      width: 50 * PdfPageFormat.mm,
      height: 40 * PdfPageFormat.mm,
      padding: const pw.EdgeInsets.fromLTRB(
        2.4 * PdfPageFormat.mm,
        2.0 * PdfPageFormat.mm,
        2.4 * PdfPageFormat.mm,
        2.0 * PdfPageFormat.mm,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          if (showCompanyName) ...[
            pw.Text(
              companyName,
              maxLines: 1,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 5.5),
            ),
            pw.SizedBox(height: 1 * PdfPageFormat.mm),
          ],
          pw.Expanded(
            child: pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: barcode,
                drawText: false,
                width: 42 * PdfPageFormat.mm,
                height: 17 * PdfPageFormat.mm,
              ),
            ),
          ),
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
          pw.Text(
            barcode,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 6.4, letterSpacing: 1),
          ),
          pw.SizedBox(height: 1.6 * PdfPageFormat.mm),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (showPrice)
                pw.Container(
                  constraints: const pw.BoxConstraints(
                    maxWidth: 17 * PdfPageFormat.mm,
                  ),
                  child: pw.Text(
                    '${item.salesPrice.toStringAsFixed(2)} EGP',
                    maxLines: 1,
                    style: pw.TextStyle(
                      fontSize: 6.2,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              if (showPrice) pw.SizedBox(width: 2 * PdfPageFormat.mm),
              pw.Expanded(
                child: pw.Text(
                  item.name,
                  maxLines: 2,
                  textAlign: hasArabicName
                      ? pw.TextAlign.right
                      : pw.TextAlign.left,
                  textDirection: hasArabicName
                      ? pw.TextDirection.rtl
                      : pw.TextDirection.ltr,
                  style: pw.TextStyle(
                    fontSize: 7.2,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _tripleLabel(
    ItemModel item, {
    required bool showPrice,
    required bool showCompanyName,
    required String companyName,
  }) {
    final barcode = item.barcode?.trim() ?? '';
    return pw.Container(
      width: _thermalLabelWidthMm * PdfPageFormat.mm,
      height: _thermalLabelHeightMm * PdfPageFormat.mm,
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 2.0 * PdfPageFormat.mm,
        vertical: 2.5 * PdfPageFormat.mm,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey300,
          width: 0.4,
          style: pw.BorderStyle.dashed,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          if (showCompanyName)
            pw.Text(
              companyName,
              maxLines: 1,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 5),
            ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (showPrice)
                pw.Text(
                  '${item.salesPrice.toStringAsFixed(2)} ج',
                  style: pw.TextStyle(
                    fontSize: _thermalPriceFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection: pw.TextDirection.rtl,
                )
              else
                pw.SizedBox(),
              pw.SizedBox(width: 4),
              pw.Expanded(
                child: pw.Text(
                  item.name,
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                  textAlign: pw.TextAlign.left,
                  style: pw.TextStyle(
                    fontSize: _thermalNameFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 1.5 * PdfPageFormat.mm),
          pw.Expanded(
            child: pw.Container(
              alignment: pw.Alignment.center,
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: barcode,
                drawText: false,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
          pw.Text(
            barcode,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
              fontSize: _thermalCodeFontSize,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasArabic(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);
}

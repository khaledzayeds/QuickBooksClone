import 'dart:typed_data';

import '../../print_templates/data/models/print_template_model.dart';
import '../../print_templates/data/print_template_repository.dart';
import '../../print_templates/data/sample_templates.dart';
import '../../print_templates/logic/print_template_pdf_service.dart';
import '../../settings/data/models/printing_settings_model.dart';
import '../data/models/print_data_contracts.dart';
import 'a4_document_pdf_service.dart';
import 'thermal_document_pdf_service.dart';

class DocumentPdfService {
  const DocumentPdfService({
    this.a4Service = const A4DocumentPdfService(),
    this.thermalService = const ThermalDocumentPdfService(),
    this.templateService = const PrintTemplatePdfService(),
    this.templateRepository = const PrintTemplateRepository(),
  });

  final A4DocumentPdfService a4Service;
  final ThermalDocumentPdfService thermalService;
  final PrintTemplatePdfService templateService;
  final PrintTemplateRepository templateRepository;

  Future<Uint8List> buildA4(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) async {
    final normalizedData = data.normalizedForPrinting();
    final template = await _resolveTemplate(normalizedData, settings, 'a4');
    if (template != null && !_isThermalTemplate(template)) {
      try {
        return await templateService.build(
          template,
          data: normalizedData,
          settings: settings,
        );
      } catch (_) {
        return a4Service.build(normalizedData, settings);
      }
    }
    return a4Service.build(normalizedData, settings);
  }

  Future<Uint8List> buildThermal(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
  ) async {
    final normalizedData = data.normalizedForPrinting();
    final template = await _resolveTemplate(
      normalizedData,
      settings,
      'thermal',
    );
    if (template != null && _isThermalTemplate(template)) {
      try {
        return await templateService.build(
          template,
          data: normalizedData,
          settings: settings,
        );
      } catch (_) {
        return thermalService.build(normalizedData, settings);
      }
    }
    return thermalService.build(normalizedData, settings);
  }

  Future<PrintTemplateModel?> _resolveTemplate(
    DocumentPrintDataModel data,
    PrintingSettingsModel settings,
    String paperKind,
  ) async {
    if (!settings.enableTemplateDesigner) {
      return null;
    }

    final documentType = normalizePrintDocumentType(data.documentType);
    final profile = settings.profileFor(documentType);
    final configuredId = profile.templateIdForPaper(paperKind)?.trim();
    if (configuredId == null || configuredId.isEmpty) {
      return null;
    }

    final builtInId = configuredId.startsWith('builtin:')
        ? configuredId.substring('builtin:'.length)
        : null;
    if (builtInId != null) {
      for (final template in SamplePrintTemplates.defaults()) {
        if (template.id == builtInId &&
            normalizePrintDocumentType(template.documentType) == documentType &&
            _templateMatchesPaper(template, paperKind)) {
          return template;
        }
      }
      return null;
    }

    try {
      final templates = await templateRepository.list(
        documentType: documentType,
      );
      for (final template in templates) {
        if (_templateMatchesPaper(template, paperKind) &&
            (template.backendId == configuredId ||
                template.id == configuredId)) {
          return template;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  bool _templateMatchesPaper(PrintTemplateModel template, String paperKind) {
    final thermal = _isThermalTemplate(template);
    return paperKind.toLowerCase() == 'thermal' ? thermal : !thermal;
  }

  bool _isThermalTemplate(PrintTemplateModel template) {
    final size = template.pageSize.toLowerCase();
    return size.contains('receipt') ||
        size.contains('thermal') ||
        template.page.widthMm <= 90;
  }
}

extension _NormalizedDocumentPrintData on DocumentPrintDataModel {
  DocumentPrintDataModel normalizedForPrinting() {
    final normalized = normalizePrintDocumentType(documentType);
    if (normalized == documentType) {
      return this;
    }
    return DocumentPrintDataModel(
      documentId: documentId,
      documentType: normalized,
      documentNumber: documentNumber,
      status: status,
      company: company,
      customer: customer,
      partyLabel: partyLabel,
      partyType: partyType,
      documentDate: documentDate,
      dueDate: dueDate,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      creditAppliedAmount: creditAppliedAmount,
      returnedAmount: returnedAmount,
      balanceDue: balanceDue,
      lines: lines,
      summaryRows: summaryRows,
      generatedAt: generatedAt,
      payment: payment,
      notes: notes,
      terms: terms,
      createdByName: createdByName,
    );
  }
}

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../settings/data/models/printing_settings_model.dart';
import '../../settings/data/printing_settings_repository.dart';
import '../../printing/services/windows_print_spooler_cleanup_service.dart';

class StatementPrintDispatcher {
  const StatementPrintDispatcher({
    this.settingsRepository = const PrintingSettingsRepository(),
    this.spoolerCleanup = const WindowsPrintSpoolerCleanupService(),
  });

  final PrintingSettingsRepository settingsRepository;
  final WindowsPrintSpoolerCleanupService spoolerCleanup;

  Future<void> print({
    required String documentType,
    required String baseName,
    required PdfPageFormat Function(PrintingSettingsModel settings)
    thermalFormat,
    required Future<Uint8List> Function(PrintingSettingsModel settings) buildA4,
    required Future<Uint8List> Function(PrintingSettingsModel settings)
    buildThermal,
  }) async {
    final settings = (await settingsRepository.load()).effectiveFor(
      documentType,
    );

    switch (settings.printMode) {
      case PrintMode.a4:
        await _printPdf(
          name: '$baseName-A4.pdf',
          format: PdfPageFormat.a4,
          printerName: settings.a4PrinterName,
          bytesBuilder: () => buildA4(settings),
        );
      case PrintMode.thermal:
        await _printPdf(
          name: '$baseName-thermal.pdf',
          format: thermalFormat(settings),
          printerName: settings.thermalPrinterName,
          bytesBuilder: () => buildThermal(settings),
        );
      case PrintMode.both:
        if (_shouldPrintA4WhenBoth(settings)) {
          await _printPdf(
            name: '$baseName-A4.pdf',
            format: PdfPageFormat.a4,
            printerName: settings.a4PrinterName,
            bytesBuilder: () => buildA4(settings),
          );
        }
        await _printPdf(
          name: '$baseName-thermal.pdf',
          format: thermalFormat(settings),
          printerName: settings.thermalPrinterName,
          bytesBuilder: () => buildThermal(settings),
        );
    }
  }

  bool _shouldPrintA4WhenBoth(PrintingSettingsModel settings) {
    final a4Printer = settings.a4PrinterName?.trim();
    final thermalPrinter = settings.thermalPrinterName?.trim();
    if (a4Printer == null || a4Printer.isEmpty) {
      return thermalPrinter == null || thermalPrinter.isEmpty;
    }
    if (thermalPrinter == null || thermalPrinter.isEmpty) {
      return true;
    }
    return a4Printer.toLowerCase() != thermalPrinter.toLowerCase();
  }

  Future<void> _printPdf({
    required String name,
    required PdfPageFormat format,
    required String? printerName,
    required Future<Uint8List> Function() bytesBuilder,
  }) async {
    final printer = printerName?.trim();
    if (printer != null && printer.isNotEmpty) {
      await spoolerCleanup.clearProblemJobs(printer);
      await Printing.directPrintPdf(
        printer: Printer(url: printer),
        name: name,
        format: format,
        dynamicLayout: false,
        usePrinterSettings: false,
        forceCustomPrintPaper: true,
        onLayout: (_) => bytesBuilder(),
      );
      await spoolerCleanup.scheduleDelayedCleanup(
        printerName: printer,
        documentName: name,
      );
      return;
    }

    await Printing.layoutPdf(
      name: name,
      format: format,
      dynamicLayout: false,
      usePrinterSettings: false,
      forceCustomPrintPaper: true,
      onLayout: (_) => bytesBuilder(),
    );
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import 'models/printing_settings_model.dart';

class PrintingSettingsRepository {
  static const _prefix = 'printing.';

  Future<PrintingSettingsModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PrintingSettingsModel.fromStorage({
      'printMode': prefs.getString('${_prefix}printMode'),
      'a4TemplateStyle': prefs.getString('${_prefix}a4TemplateStyle'),
      'thermalWidth': prefs.getString('${_prefix}thermalWidth'),
      'showLogo': prefs.getString('${_prefix}showLogo'),
      'showQrCode': prefs.getString('${_prefix}showQrCode'),
      'showTaxSummary': prefs.getString('${_prefix}showTaxSummary'),
      'showCustomerBalance': prefs.getString('${_prefix}showCustomerBalance'),
      'showItemSku': prefs.getString('${_prefix}showItemSku'),
      'showCompanyAddress': prefs.getString('${_prefix}showCompanyAddress'),
      'useArabicFonts': prefs.getString('${_prefix}useArabicFonts'),
      'autoPrintAfterSave': prefs.getString('${_prefix}autoPrintAfterSave'),
      'printPreviewBeforePrint': prefs.getString('${_prefix}printPreviewBeforePrint'),
      'logoPath': prefs.getString('${_prefix}logoPath'),
      'a4PrinterName': prefs.getString('${_prefix}a4PrinterName'),
      'thermalPrinterName': prefs.getString('${_prefix}thermalPrinterName'),
      'invoiceFooterMessage': prefs.getString('${_prefix}invoiceFooterMessage'),
      'receiptFooterMessage': prefs.getString('${_prefix}receiptFooterMessage'),
    });
  }

  Future<PrintingSettingsModel> save(PrintingSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final values = settings.toStorage();
    for (final entry in values.entries) {
      await prefs.setString('$_prefix${entry.key}', entry.value);
    }
    return settings;
  }

  Future<PrintingSettingsModel> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    return PrintingSettingsModel.defaults();
  }
}

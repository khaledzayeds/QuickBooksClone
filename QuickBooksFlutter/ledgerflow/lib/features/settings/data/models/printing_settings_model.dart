enum PrintMode {
  a4,
  thermal,
  both;

  String get label => switch (this) {
        PrintMode.a4 => 'A4 Documents',
        PrintMode.thermal => 'Thermal Receipts',
        PrintMode.both => 'A4 + Thermal',
      };

  static PrintMode fromName(String? value) {
    return PrintMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => PrintMode.both,
    );
  }
}

enum A4TemplateStyle {
  modern,
  compact,
  classic;

  String get label => switch (this) {
        A4TemplateStyle.modern => 'Modern',
        A4TemplateStyle.compact => 'Compact',
        A4TemplateStyle.classic => 'Classic',
      };

  static A4TemplateStyle fromName(String? value) {
    return A4TemplateStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => A4TemplateStyle.modern,
    );
  }
}

enum ThermalWidth {
  mm58,
  mm80;

  String get label => switch (this) {
        ThermalWidth.mm58 => '58 mm',
        ThermalWidth.mm80 => '80 mm',
      };

  int get widthMillimeters => switch (this) {
        ThermalWidth.mm58 => 58,
        ThermalWidth.mm80 => 80,
      };

  static ThermalWidth fromName(String? value) {
    return ThermalWidth.values.firstWhere(
      (width) => width.name == value,
      orElse: () => ThermalWidth.mm80,
    );
  }
}

class PrintingSettingsModel {
  const PrintingSettingsModel({
    required this.printMode,
    required this.a4TemplateStyle,
    required this.thermalWidth,
    required this.showLogo,
    required this.showQrCode,
    required this.showTaxSummary,
    required this.showCustomerBalance,
    required this.showItemSku,
    required this.showCompanyAddress,
    required this.useArabicFonts,
    required this.autoPrintAfterSave,
    required this.printPreviewBeforePrint,
    this.logoPath,
    this.a4PrinterName,
    this.thermalPrinterName,
    this.invoiceFooterMessage,
    this.receiptFooterMessage,
  });

  final PrintMode printMode;
  final A4TemplateStyle a4TemplateStyle;
  final ThermalWidth thermalWidth;
  final bool showLogo;
  final bool showQrCode;
  final bool showTaxSummary;
  final bool showCustomerBalance;
  final bool showItemSku;
  final bool showCompanyAddress;
  final bool useArabicFonts;
  final bool autoPrintAfterSave;
  final bool printPreviewBeforePrint;
  final String? logoPath;
  final String? a4PrinterName;
  final String? thermalPrinterName;
  final String? invoiceFooterMessage;
  final String? receiptFooterMessage;

  factory PrintingSettingsModel.defaults() {
    return const PrintingSettingsModel(
      printMode: PrintMode.both,
      a4TemplateStyle: A4TemplateStyle.modern,
      thermalWidth: ThermalWidth.mm80,
      showLogo: true,
      showQrCode: true,
      showTaxSummary: true,
      showCustomerBalance: true,
      showItemSku: false,
      showCompanyAddress: true,
      useArabicFonts: true,
      autoPrintAfterSave: false,
      printPreviewBeforePrint: true,
      invoiceFooterMessage: 'Thank you for your business.',
      receiptFooterMessage: 'شكراً لتعاملكم معنا',
    );
  }

  PrintingSettingsModel copyWith({
    PrintMode? printMode,
    A4TemplateStyle? a4TemplateStyle,
    ThermalWidth? thermalWidth,
    bool? showLogo,
    bool? showQrCode,
    bool? showTaxSummary,
    bool? showCustomerBalance,
    bool? showItemSku,
    bool? showCompanyAddress,
    bool? useArabicFonts,
    bool? autoPrintAfterSave,
    bool? printPreviewBeforePrint,
    String? logoPath,
    String? a4PrinterName,
    String? thermalPrinterName,
    String? invoiceFooterMessage,
    String? receiptFooterMessage,
  }) {
    return PrintingSettingsModel(
      printMode: printMode ?? this.printMode,
      a4TemplateStyle: a4TemplateStyle ?? this.a4TemplateStyle,
      thermalWidth: thermalWidth ?? this.thermalWidth,
      showLogo: showLogo ?? this.showLogo,
      showQrCode: showQrCode ?? this.showQrCode,
      showTaxSummary: showTaxSummary ?? this.showTaxSummary,
      showCustomerBalance: showCustomerBalance ?? this.showCustomerBalance,
      showItemSku: showItemSku ?? this.showItemSku,
      showCompanyAddress: showCompanyAddress ?? this.showCompanyAddress,
      useArabicFonts: useArabicFonts ?? this.useArabicFonts,
      autoPrintAfterSave: autoPrintAfterSave ?? this.autoPrintAfterSave,
      printPreviewBeforePrint: printPreviewBeforePrint ?? this.printPreviewBeforePrint,
      logoPath: logoPath ?? this.logoPath,
      a4PrinterName: a4PrinterName ?? this.a4PrinterName,
      thermalPrinterName: thermalPrinterName ?? this.thermalPrinterName,
      invoiceFooterMessage: invoiceFooterMessage ?? this.invoiceFooterMessage,
      receiptFooterMessage: receiptFooterMessage ?? this.receiptFooterMessage,
    );
  }

  Map<String, String> toStorage() => {
        'printMode': printMode.name,
        'a4TemplateStyle': a4TemplateStyle.name,
        'thermalWidth': thermalWidth.name,
        'showLogo': showLogo.toString(),
        'showQrCode': showQrCode.toString(),
        'showTaxSummary': showTaxSummary.toString(),
        'showCustomerBalance': showCustomerBalance.toString(),
        'showItemSku': showItemSku.toString(),
        'showCompanyAddress': showCompanyAddress.toString(),
        'useArabicFonts': useArabicFonts.toString(),
        'autoPrintAfterSave': autoPrintAfterSave.toString(),
        'printPreviewBeforePrint': printPreviewBeforePrint.toString(),
        'logoPath': logoPath ?? '',
        'a4PrinterName': a4PrinterName ?? '',
        'thermalPrinterName': thermalPrinterName ?? '',
        'invoiceFooterMessage': invoiceFooterMessage ?? '',
        'receiptFooterMessage': receiptFooterMessage ?? '',
      };

  factory PrintingSettingsModel.fromStorage(Map<String, String?> values) {
    final defaults = PrintingSettingsModel.defaults();
    bool boolValue(String key, bool fallback) => values[key] == null ? fallback : values[key] == 'true';
    String? stringValue(String key) => values[key]?.isNotEmpty == true ? values[key] : null;

    return PrintingSettingsModel(
      printMode: PrintMode.fromName(values['printMode']),
      a4TemplateStyle: A4TemplateStyle.fromName(values['a4TemplateStyle']),
      thermalWidth: ThermalWidth.fromName(values['thermalWidth']),
      showLogo: boolValue('showLogo', defaults.showLogo),
      showQrCode: boolValue('showQrCode', defaults.showQrCode),
      showTaxSummary: boolValue('showTaxSummary', defaults.showTaxSummary),
      showCustomerBalance: boolValue('showCustomerBalance', defaults.showCustomerBalance),
      showItemSku: boolValue('showItemSku', defaults.showItemSku),
      showCompanyAddress: boolValue('showCompanyAddress', defaults.showCompanyAddress),
      useArabicFonts: boolValue('useArabicFonts', defaults.useArabicFonts),
      autoPrintAfterSave: boolValue('autoPrintAfterSave', defaults.autoPrintAfterSave),
      printPreviewBeforePrint: boolValue('printPreviewBeforePrint', defaults.printPreviewBeforePrint),
      logoPath: stringValue('logoPath'),
      a4PrinterName: stringValue('a4PrinterName'),
      thermalPrinterName: stringValue('thermalPrinterName'),
      invoiceFooterMessage: stringValue('invoiceFooterMessage') ?? defaults.invoiceFooterMessage,
      receiptFooterMessage: stringValue('receiptFooterMessage') ?? defaults.receiptFooterMessage,
    );
  }
}

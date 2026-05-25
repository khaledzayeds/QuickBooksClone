import 'dart:convert';

String normalizePrintDocumentType(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\s]+'), '-')
      .replaceAll(RegExp(r'[^a-z0-9-]'), '');
  return switch (normalized) {
    'invoice' || 'invoices' || 'sales-invoice' || 'sales-invoices' => 'invoice',
    'salesreceipt' ||
    'sales-receipt' ||
    'sales-receipts' ||
    'receipt' ||
    'receipts' => 'sales-receipt',
    'estimate' || 'estimates' || 'quote' || 'quotation' => 'estimate',
    'salesreturn' ||
    'sales-return' ||
    'sales-returns' ||
    'credit-memo' ||
    'creditmemo' => 'sales-return',
    'purchaseorder' ||
    'purchase-order' ||
    'purchase-orders' => 'purchase-order',
    'receiveinventory' ||
    'receive-inventory' ||
    'inventory-receipt' ||
    'inventoryreceipt' ||
    'item-receipt' ||
    'itemreceipt' => 'receive-inventory',
    'inventoryadjustment' ||
    'inventory-adjustment' ||
    'inventory-adjustments' ||
    'stock-adjustment' => 'inventory-adjustment',
    _ => normalized.isEmpty ? 'invoice' : normalized,
  };
}

enum PrintMode {
  a4,
  thermal,
  both;

  String get label => switch (this) {
    PrintMode.a4 => 'A4 Documents',
    PrintMode.thermal => 'Thermal Receipts',
    PrintMode.both => 'A4 + Thermal',
  };

  String get shortLabel => switch (this) {
    PrintMode.a4 => 'A4',
    PrintMode.thermal => 'Thermal',
    PrintMode.both => 'Both',
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

class PrintDocumentTypeOption {
  const PrintDocumentTypeOption({
    required this.key,
    required this.label,
    required this.group,
  });

  final String key;
  final String label;
  final String group;
}

const printDocumentTypeOptions = <PrintDocumentTypeOption>[
  PrintDocumentTypeOption(key: 'invoice', label: 'Invoice', group: 'Sales'),
  PrintDocumentTypeOption(
    key: 'sales-receipt',
    label: 'Sales Receipt',
    group: 'Sales',
  ),
  PrintDocumentTypeOption(key: 'estimate', label: 'Estimate', group: 'Sales'),
  PrintDocumentTypeOption(
    key: 'sales-return',
    label: 'Sales Return',
    group: 'Sales',
  ),
  PrintDocumentTypeOption(
    key: 'purchase-order',
    label: 'Purchase Order',
    group: 'Purchasing',
  ),
  PrintDocumentTypeOption(
    key: 'receive-inventory',
    label: 'Receive Inventory',
    group: 'Inventory',
  ),
  PrintDocumentTypeOption(
    key: 'inventory-adjustment',
    label: 'Inventory Adjustment',
    group: 'Inventory',
  ),
  // TODO(printing): enable these once /api/printing supports their print data contracts.
  // Bank deposits and checks currently use draft/local print data, while statements
  // still need backend endpoints before they can safely appear in per-screen settings.
];

const unsupportedPrintDocumentTypeOptions = <PrintDocumentTypeOption>[
  PrintDocumentTypeOption(
    key: 'deposit',
    label: 'Bank Deposit',
    group: 'Banking',
  ),
  PrintDocumentTypeOption(key: 'check', label: 'Write Check', group: 'Banking'),
  PrintDocumentTypeOption(
    key: 'journal-entry',
    label: 'Journal Entry',
    group: 'Company',
  ),
  PrintDocumentTypeOption(
    key: 'customer-statement',
    label: 'Customer Statement',
    group: 'Reports',
  ),
  PrintDocumentTypeOption(
    key: 'vendor-statement',
    label: 'Vendor Statement',
    group: 'Reports',
  ),
];

class DocumentPrintProfile {
  const DocumentPrintProfile({
    required this.documentType,
    this.printMode,
    this.a4TemplateStyle,
    this.thermalWidth,
    this.a4TemplateBackendId,
    this.a4TemplateName,
    this.thermalTemplateBackendId,
    this.thermalTemplateName,
    this.templateBackendId,
    this.templateName,
  });

  final String documentType;
  final PrintMode? printMode;
  final A4TemplateStyle? a4TemplateStyle;
  final ThermalWidth? thermalWidth;
  final String? a4TemplateBackendId;
  final String? a4TemplateName;
  final String? thermalTemplateBackendId;
  final String? thermalTemplateName;
  final String? templateBackendId;
  final String? templateName;

  DocumentPrintProfile copyWith({
    String? documentType,
    PrintMode? printMode,
    A4TemplateStyle? a4TemplateStyle,
    ThermalWidth? thermalWidth,
    String? a4TemplateBackendId,
    String? a4TemplateName,
    String? thermalTemplateBackendId,
    String? thermalTemplateName,
    String? templateBackendId,
    String? templateName,
    bool clearTemplate = false,
    bool clearA4Template = false,
    bool clearThermalTemplate = false,
  }) {
    return DocumentPrintProfile(
      documentType: documentType ?? this.documentType,
      printMode: printMode ?? this.printMode,
      a4TemplateStyle: a4TemplateStyle ?? this.a4TemplateStyle,
      thermalWidth: thermalWidth ?? this.thermalWidth,
      a4TemplateBackendId: clearA4Template
          ? null
          : a4TemplateBackendId ?? this.a4TemplateBackendId,
      a4TemplateName: clearA4Template
          ? null
          : a4TemplateName ?? this.a4TemplateName,
      thermalTemplateBackendId: clearThermalTemplate
          ? null
          : thermalTemplateBackendId ?? this.thermalTemplateBackendId,
      thermalTemplateName: clearThermalTemplate
          ? null
          : thermalTemplateName ?? this.thermalTemplateName,
      templateBackendId: clearTemplate
          ? null
          : templateBackendId ?? this.templateBackendId,
      templateName: clearTemplate ? null : templateName ?? this.templateName,
    );
  }

  Map<String, dynamic> toJson() => {
    'documentType': documentType,
    if (printMode != null) 'printMode': printMode!.name,
    if (a4TemplateStyle != null) 'a4TemplateStyle': a4TemplateStyle!.name,
    if (thermalWidth != null) 'thermalWidth': thermalWidth!.name,
    if (a4TemplateBackendId != null) 'a4TemplateBackendId': a4TemplateBackendId,
    if ((a4TemplateName ?? '').isNotEmpty) 'a4TemplateName': a4TemplateName,
    if (thermalTemplateBackendId != null)
      'thermalTemplateBackendId': thermalTemplateBackendId,
    if ((thermalTemplateName ?? '').isNotEmpty)
      'thermalTemplateName': thermalTemplateName,
    if (templateBackendId != null) 'templateBackendId': templateBackendId,
    if ((templateName ?? '').isNotEmpty) 'templateName': templateName,
  };

  factory DocumentPrintProfile.fromJson(Map<String, dynamic> json) {
    return DocumentPrintProfile(
      documentType: normalizePrintDocumentType(
        json['documentType']?.toString() ?? 'invoice',
      ),
      printMode: json['printMode'] == null
          ? null
          : PrintMode.fromName(json['printMode']?.toString()),
      a4TemplateStyle: json['a4TemplateStyle'] == null
          ? null
          : A4TemplateStyle.fromName(json['a4TemplateStyle']?.toString()),
      thermalWidth: json['thermalWidth'] == null
          ? null
          : ThermalWidth.fromName(json['thermalWidth']?.toString()),
      a4TemplateBackendId: _stringOrNull(
        json['a4TemplateBackendId']?.toString(),
      ),
      a4TemplateName: _stringOrNull(json['a4TemplateName']?.toString()),
      thermalTemplateBackendId: _stringOrNull(
        json['thermalTemplateBackendId']?.toString(),
      ),
      thermalTemplateName: _stringOrNull(
        json['thermalTemplateName']?.toString(),
      ),
      templateBackendId: _stringOrNull(json['templateBackendId']?.toString()),
      templateName: _stringOrNull(json['templateName']?.toString()),
    );
  }

  String? templateIdForPaper(String paperKind) {
    final normalized = paperKind.toLowerCase();
    if (normalized == 'a4') {
      return a4TemplateBackendId ?? templateBackendId;
    }
    if (normalized == 'thermal') {
      return thermalTemplateBackendId ?? templateBackendId;
    }
    return templateBackendId;
  }

  String? templateNameForPaper(String paperKind) {
    final normalized = paperKind.toLowerCase();
    if (normalized == 'a4') {
      return a4TemplateName ?? templateName;
    }
    if (normalized == 'thermal') {
      return thermalTemplateName ?? templateName;
    }
    return templateName;
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
    required this.enableTemplateDesigner,
    required this.autoPrintAfterSave,
    required this.printPreviewBeforePrint,
    required this.documentProfiles,
    required this.selectedDocumentType,
    this.languageCode = 'ar',
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
  final bool enableTemplateDesigner;
  final bool autoPrintAfterSave;
  final bool printPreviewBeforePrint;
  final Map<String, DocumentPrintProfile> documentProfiles;
  final String selectedDocumentType;
  final String languageCode;
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
      enableTemplateDesigner: false,
      autoPrintAfterSave: false,
      printPreviewBeforePrint: true,
      documentProfiles: {},
      selectedDocumentType: 'invoice',
      invoiceFooterMessage: 'Thank you for your business.',
      receiptFooterMessage: 'شكراً لتعاملكم معنا',
    );
  }

  DocumentPrintProfile profileFor(String documentType) {
    final normalized = normalizePrintDocumentType(documentType);
    final profile = documentProfiles[normalized];
    return profile == null
        ? DocumentPrintProfile(documentType: normalized)
        : profile.copyWith(documentType: normalized);
  }

  PrintingSettingsModel effectiveFor(String documentType) {
    final profile = profileFor(normalizePrintDocumentType(documentType));
    return copyWith(
      printMode: profile.printMode,
      a4TemplateStyle: profile.a4TemplateStyle,
      thermalWidth: profile.thermalWidth,
    );
  }

  PrintingSettingsModel updateProfile(DocumentPrintProfile profile) {
    final normalized = normalizePrintDocumentType(profile.documentType);
    final next = Map<String, DocumentPrintProfile>.from(documentProfiles);
    next[normalized] = profile.copyWith(documentType: normalized);
    return copyWith(documentProfiles: next, selectedDocumentType: normalized);
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
    bool? enableTemplateDesigner,
    bool? autoPrintAfterSave,
    bool? printPreviewBeforePrint,
    Map<String, DocumentPrintProfile>? documentProfiles,
    String? selectedDocumentType,
    String? languageCode,
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
      enableTemplateDesigner:
          enableTemplateDesigner ?? this.enableTemplateDesigner,
      autoPrintAfterSave: autoPrintAfterSave ?? this.autoPrintAfterSave,
      printPreviewBeforePrint:
          printPreviewBeforePrint ?? this.printPreviewBeforePrint,
      documentProfiles: documentProfiles ?? this.documentProfiles,
      selectedDocumentType: selectedDocumentType ?? this.selectedDocumentType,
      languageCode: languageCode ?? this.languageCode,
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
    'enableTemplateDesigner': enableTemplateDesigner.toString(),
    'autoPrintAfterSave': autoPrintAfterSave.toString(),
    'printPreviewBeforePrint': printPreviewBeforePrint.toString(),
    'documentProfiles': jsonEncode(
      documentProfiles.map(
        (key, value) => MapEntry(
          normalizePrintDocumentType(key),
          value
              .copyWith(
                documentType: normalizePrintDocumentType(value.documentType),
              )
              .toJson(),
        ),
      ),
    ),
    'selectedDocumentType': normalizePrintDocumentType(selectedDocumentType),
    'logoPath': logoPath ?? '',
    'a4PrinterName': a4PrinterName ?? '',
    'thermalPrinterName': thermalPrinterName ?? '',
    'invoiceFooterMessage': invoiceFooterMessage ?? '',
    'receiptFooterMessage': receiptFooterMessage ?? '',
  };

  factory PrintingSettingsModel.fromStorage(Map<String, String?> values) {
    final defaults = PrintingSettingsModel.defaults();
    bool boolValue(String key, bool fallback) =>
        values[key] == null ? fallback : values[key] == 'true';
    String? stringValue(String key) =>
        values[key]?.isNotEmpty == true ? values[key] : null;

    return PrintingSettingsModel(
      printMode: PrintMode.fromName(values['printMode']),
      a4TemplateStyle: A4TemplateStyle.fromName(values['a4TemplateStyle']),
      thermalWidth: ThermalWidth.fromName(values['thermalWidth']),
      showLogo: boolValue('showLogo', defaults.showLogo),
      showQrCode: boolValue('showQrCode', defaults.showQrCode),
      showTaxSummary: boolValue('showTaxSummary', defaults.showTaxSummary),
      showCustomerBalance: boolValue(
        'showCustomerBalance',
        defaults.showCustomerBalance,
      ),
      showItemSku: boolValue('showItemSku', defaults.showItemSku),
      showCompanyAddress: boolValue(
        'showCompanyAddress',
        defaults.showCompanyAddress,
      ),
      useArabicFonts: boolValue('useArabicFonts', defaults.useArabicFonts),
      enableTemplateDesigner: boolValue(
        'enableTemplateDesigner',
        defaults.enableTemplateDesigner,
      ),
      autoPrintAfterSave: boolValue(
        'autoPrintAfterSave',
        defaults.autoPrintAfterSave,
      ),
      printPreviewBeforePrint: boolValue(
        'printPreviewBeforePrint',
        defaults.printPreviewBeforePrint,
      ),
      documentProfiles: _profilesFromStorage(values['documentProfiles']),
      selectedDocumentType: normalizePrintDocumentType(
        stringValue('selectedDocumentType') ?? defaults.selectedDocumentType,
      ),
      logoPath: stringValue('logoPath'),
      a4PrinterName: stringValue('a4PrinterName'),
      thermalPrinterName: stringValue('thermalPrinterName'),
      invoiceFooterMessage:
          stringValue('invoiceFooterMessage') ?? defaults.invoiceFooterMessage,
      receiptFooterMessage:
          stringValue('receiptFooterMessage') ?? defaults.receiptFooterMessage,
    );
  }
}

Map<String, DocumentPrintProfile> _profilesFromStorage(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const {};
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const {};
    }
    return decoded.map((key, value) {
      final profile = value is Map<String, dynamic>
          ? DocumentPrintProfile.fromJson(value)
          : DocumentPrintProfile(documentType: key);
      final normalized = normalizePrintDocumentType(profile.documentType);
      return MapEntry(normalized, profile.copyWith(documentType: normalized));
    });
  } catch (_) {
    return const {};
  }
}

String? _stringOrNull(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value;
}

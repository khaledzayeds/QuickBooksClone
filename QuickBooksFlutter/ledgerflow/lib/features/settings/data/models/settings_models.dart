class RuntimeSettingsModel {
  const RuntimeSettingsModel({
    required this.environmentName,
    required this.databaseProvider,
    required this.supportsBackupRestore,
    this.liveDatabasePath,
    this.backupDirectory,
  });

  final String environmentName;
  final String databaseProvider;
  final bool supportsBackupRestore;
  final String? liveDatabasePath;
  final String? backupDirectory;

  factory RuntimeSettingsModel.fromJson(Map<String, dynamic> json) {
    return RuntimeSettingsModel(
      environmentName: json['environmentName']?.toString() ?? '-',
      databaseProvider: json['databaseProvider']?.toString() ?? json['provider']?.toString() ?? '-',
      supportsBackupRestore: json['supportsBackupRestore'] == true,
      liveDatabasePath: json['liveDatabasePath']?.toString(),
      backupDirectory: json['backupDirectory']?.toString(),
    );
  }
}

class CompanySettingsModel {
  const CompanySettingsModel({
    required this.id,
    required this.companyName,
    required this.currency,
    required this.country,
    required this.timeZoneId,
    required this.defaultLanguage,
    this.companyId,
    this.legalName,
    this.email,
    this.phone,
    this.taxRegistrationNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.region,
    this.postalCode,
    this.fiscalYearStartMonth = 1,
    this.fiscalYearStartDay = 1,
    this.defaultSalesTaxRate = 0,
    this.defaultPurchaseTaxRate = 0,
    this.taxesEnabled = false,
    this.pricesIncludeTax = false,
    this.defaultSalesTaxCodeId,
    this.defaultPurchaseTaxCodeId,
    this.taxRoundingMode = 1,
    this.defaultSalesTaxPayableAccountId,
    this.defaultPurchaseTaxReceivableAccountId,
  });

  final String id;
  final String? companyId;
  final String companyName;
  final String? legalName;
  final String? email;
  final String? phone;
  final String currency;
  final String country;
  final String timeZoneId;
  final String defaultLanguage;
  final String? taxRegistrationNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? region;
  final String? postalCode;
  final int fiscalYearStartMonth;
  final int fiscalYearStartDay;
  final double defaultSalesTaxRate;
  final double defaultPurchaseTaxRate;
  final bool taxesEnabled;
  final bool pricesIncludeTax;
  final String? defaultSalesTaxCodeId;
  final String? defaultPurchaseTaxCodeId;
  final int taxRoundingMode;
  final String? defaultSalesTaxPayableAccountId;
  final String? defaultPurchaseTaxReceivableAccountId;

  factory CompanySettingsModel.empty() {
    return const CompanySettingsModel(
      id: '',
      companyName: '',
      currency: 'EGP',
      country: 'EG',
      timeZoneId: 'Africa/Cairo',
      defaultLanguage: 'ar',
    );
  }

  factory CompanySettingsModel.fromJson(Map<String, dynamic> json) {
    return CompanySettingsModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      companyName: json['companyName']?.toString() ?? '',
      legalName: json['legalName']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      currency: json['currency']?.toString() ?? 'EGP',
      country: json['country']?.toString() ?? 'EG',
      timeZoneId: json['timeZoneId']?.toString() ?? 'Africa/Cairo',
      defaultLanguage: json['defaultLanguage']?.toString() ?? 'ar',
      taxRegistrationNumber: json['taxRegistrationNumber']?.toString(),
      addressLine1: json['addressLine1']?.toString(),
      addressLine2: json['addressLine2']?.toString(),
      city: json['city']?.toString(),
      region: json['region']?.toString(),
      postalCode: json['postalCode']?.toString(),
      fiscalYearStartMonth: _toInt(json['fiscalYearStartMonth']) ?? 1,
      fiscalYearStartDay: _toInt(json['fiscalYearStartDay']) ?? 1,
      defaultSalesTaxRate: _toDouble(json['defaultSalesTaxRate']) ?? 0,
      defaultPurchaseTaxRate: _toDouble(json['defaultPurchaseTaxRate']) ?? 0,
      taxesEnabled: json['taxesEnabled'] == true,
      pricesIncludeTax: json['pricesIncludeTax'] == true,
      defaultSalesTaxCodeId: json['defaultSalesTaxCodeId']?.toString(),
      defaultPurchaseTaxCodeId: json['defaultPurchaseTaxCodeId']?.toString(),
      taxRoundingMode: _toInt(json['taxRoundingMode']) ?? 1,
      defaultSalesTaxPayableAccountId: json['defaultSalesTaxPayableAccountId']?.toString(),
      defaultPurchaseTaxReceivableAccountId: json['defaultPurchaseTaxReceivableAccountId']?.toString(),
    );
  }

  CompanySettingsModel copyWith({
    String? id,
    String? companyId,
    String? companyName,
    String? legalName,
    String? email,
    String? phone,
    String? currency,
    String? country,
    String? timeZoneId,
    String? defaultLanguage,
    String? taxRegistrationNumber,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? region,
    String? postalCode,
    int? fiscalYearStartMonth,
    int? fiscalYearStartDay,
    double? defaultSalesTaxRate,
    double? defaultPurchaseTaxRate,
    bool? taxesEnabled,
    bool? pricesIncludeTax,
    String? defaultSalesTaxCodeId,
    String? defaultPurchaseTaxCodeId,
    int? taxRoundingMode,
    String? defaultSalesTaxPayableAccountId,
    String? defaultPurchaseTaxReceivableAccountId,
  }) {
    return CompanySettingsModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      legalName: legalName ?? this.legalName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      currency: currency ?? this.currency,
      country: country ?? this.country,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      taxRegistrationNumber: taxRegistrationNumber ?? this.taxRegistrationNumber,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      region: region ?? this.region,
      postalCode: postalCode ?? this.postalCode,
      fiscalYearStartMonth: fiscalYearStartMonth ?? this.fiscalYearStartMonth,
      fiscalYearStartDay: fiscalYearStartDay ?? this.fiscalYearStartDay,
      defaultSalesTaxRate: defaultSalesTaxRate ?? this.defaultSalesTaxRate,
      defaultPurchaseTaxRate: defaultPurchaseTaxRate ?? this.defaultPurchaseTaxRate,
      taxesEnabled: taxesEnabled ?? this.taxesEnabled,
      pricesIncludeTax: pricesIncludeTax ?? this.pricesIncludeTax,
      defaultSalesTaxCodeId: defaultSalesTaxCodeId ?? this.defaultSalesTaxCodeId,
      defaultPurchaseTaxCodeId: defaultPurchaseTaxCodeId ?? this.defaultPurchaseTaxCodeId,
      taxRoundingMode: taxRoundingMode ?? this.taxRoundingMode,
      defaultSalesTaxPayableAccountId: defaultSalesTaxPayableAccountId ?? this.defaultSalesTaxPayableAccountId,
      defaultPurchaseTaxReceivableAccountId: defaultPurchaseTaxReceivableAccountId ?? this.defaultPurchaseTaxReceivableAccountId,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'companyName': companyName.trim(),
      'legalName': _emptyToNull(legalName),
      'email': _emptyToNull(email),
      'phone': _emptyToNull(phone),
      'currency': currency.trim().isEmpty ? 'EGP' : currency.trim().toUpperCase(),
      'country': country.trim().isEmpty ? 'EG' : country.trim().toUpperCase(),
      'timeZoneId': timeZoneId.trim().isEmpty ? 'Africa/Cairo' : timeZoneId.trim(),
      'defaultLanguage': defaultLanguage.trim().isEmpty ? 'ar' : defaultLanguage.trim(),
      'taxRegistrationNumber': _emptyToNull(taxRegistrationNumber),
      'addressLine1': _emptyToNull(addressLine1),
      'addressLine2': _emptyToNull(addressLine2),
      'city': _emptyToNull(city),
      'region': _emptyToNull(region),
      'postalCode': _emptyToNull(postalCode),
      'fiscalYearStartMonth': fiscalYearStartMonth.clamp(1, 12),
      'fiscalYearStartDay': fiscalYearStartDay.clamp(1, 31),
      'defaultSalesTaxRate': defaultSalesTaxRate.clamp(0, 100),
      'defaultPurchaseTaxRate': defaultPurchaseTaxRate.clamp(0, 100),
      'taxesEnabled': taxesEnabled,
      'defaultSalesTaxCodeId': _emptyToNull(defaultSalesTaxCodeId),
      'defaultPurchaseTaxCodeId': _emptyToNull(defaultPurchaseTaxCodeId),
      'pricesIncludeTax': pricesIncludeTax,
      'taxRoundingMode': taxRoundingMode <= 0 ? 1 : taxRoundingMode,
      'defaultSalesTaxPayableAccountId': _emptyToNull(defaultSalesTaxPayableAccountId),
      'defaultPurchaseTaxReceivableAccountId': _emptyToNull(defaultPurchaseTaxReceivableAccountId),
    };
  }

  String get displayAddress {
    final parts = [addressLine1, addressLine2, city, region, postalCode]
        .where((part) => part != null && part.trim().isNotEmpty)
        .cast<String>()
        .toList();
    return parts.isEmpty ? '-' : parts.join('، ');
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

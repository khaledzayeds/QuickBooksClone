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
    this.legalName,
    this.email,
    this.phone,
    this.taxRegistrationNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.region,
    this.postalCode,
    this.fiscalYearStartMonth,
    this.fiscalYearStartDay,
    this.defaultSalesTaxRate,
    this.defaultPurchaseTaxRate,
    this.taxesEnabled = false,
    this.pricesIncludeTax = false,
  });

  final String id;
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
  final int? fiscalYearStartMonth;
  final int? fiscalYearStartDay;
  final double? defaultSalesTaxRate;
  final double? defaultPurchaseTaxRate;
  final bool taxesEnabled;
  final bool pricesIncludeTax;

  factory CompanySettingsModel.fromJson(Map<String, dynamic> json) {
    return CompanySettingsModel(
      id: json['id']?.toString() ?? '',
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
      fiscalYearStartMonth: _toInt(json['fiscalYearStartMonth']),
      fiscalYearStartDay: _toInt(json['fiscalYearStartDay']),
      defaultSalesTaxRate: _toDouble(json['defaultSalesTaxRate']),
      defaultPurchaseTaxRate: _toDouble(json['defaultPurchaseTaxRate']),
      taxesEnabled: json['taxesEnabled'] == true,
      pricesIncludeTax: json['pricesIncludeTax'] == true,
    );
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
}

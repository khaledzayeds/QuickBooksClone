class SetupStatus {
  const SetupStatus({
    required this.hasCompanySettings,
    required this.hasAdminUser,
    required this.isInitialized,
    this.companyName,
    this.adminUserName,
  });

  final bool hasCompanySettings;
  final bool hasAdminUser;
  final bool isInitialized;
  final String? companyName;
  final String? adminUserName;

  factory SetupStatus.fromJson(Map<String, dynamic> json) {
    return SetupStatus(
      hasCompanySettings: json['hasCompanySettings'] == true,
      hasAdminUser: json['hasAdminUser'] == true,
      isInitialized: json['isInitialized'] == true,
      companyName: json['companyName']?.toString(),
      adminUserName: json['adminUserName']?.toString(),
    );
  }
}

class InitializeCompanyRequest {
  const InitializeCompanyRequest({
    required this.companyName,
    required this.currency,
    required this.country,
    required this.timeZoneId,
    required this.defaultLanguage,
    required this.adminUserName,
    required this.adminDisplayName,
    required this.initialAdminSecret,
    this.fiscalYearStartMonth = 1,
    this.fiscalYearStartDay = 1,
    this.taxesEnabled = false,
    this.pricesIncludeTax = false,
    this.defaultSalesTaxRate = 0,
    this.defaultPurchaseTaxRate = 0,
    this.inventoryEnabled = true,
    this.defaultWarehouseName,
    this.servicesEnabled = true,
    this.legalName,
    this.email,
    this.phone,
    this.adminEmail,
  });

  final String companyName;
  final String currency;
  final String country;
  final String timeZoneId;
  final String defaultLanguage;
  final String? legalName;
  final String? email;
  final String? phone;
  final String adminUserName;
  final String adminDisplayName;
  final String? adminEmail;
  final String initialAdminSecret;
  final int fiscalYearStartMonth;
  final int fiscalYearStartDay;
  final bool taxesEnabled;
  final bool pricesIncludeTax;
  final double defaultSalesTaxRate;
  final double defaultPurchaseTaxRate;
  final bool inventoryEnabled;
  final String? defaultWarehouseName;
  final bool servicesEnabled;

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'currency': currency,
    'country': country,
    'timeZoneId': timeZoneId,
    'defaultLanguage': defaultLanguage,
    'legalName': legalName,
    'email': email,
    'phone': phone,
    'adminUserName': adminUserName,
    'adminDisplayName': adminDisplayName,
    'adminEmail': adminEmail,
    'initialAdminSecret': initialAdminSecret,
    'fiscalYearStartMonth': fiscalYearStartMonth,
    'fiscalYearStartDay': fiscalYearStartDay,
    'taxesEnabled': taxesEnabled,
    'pricesIncludeTax': pricesIncludeTax,
    'defaultSalesTaxRate': defaultSalesTaxRate,
    'defaultPurchaseTaxRate': defaultPurchaseTaxRate,
    'inventoryEnabled': inventoryEnabled,
    'defaultWarehouseName': defaultWarehouseName,
    'servicesEnabled': servicesEnabled,
  };
}

class InitializeCompanyResponse {
  const InitializeCompanyResponse({
    required this.initialized,
    required this.companyName,
    required this.adminUserName,
    required this.adminRoleKey,
  });

  final bool initialized;
  final String companyName;
  final String adminUserName;
  final String adminRoleKey;

  factory InitializeCompanyResponse.fromJson(Map<String, dynamic> json) {
    return InitializeCompanyResponse(
      initialized: json['initialized'] == true,
      companyName: json['companyName']?.toString() ?? '',
      adminUserName: json['adminUserName']?.toString() ?? '',
      adminRoleKey: json['adminRoleKey']?.toString() ?? '',
    );
  }
}

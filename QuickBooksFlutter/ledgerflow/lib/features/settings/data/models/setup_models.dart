class SetupStatusModel {
  const SetupStatusModel({
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

  factory SetupStatusModel.fromJson(Map<String, dynamic> json) => SetupStatusModel(
        hasCompanySettings: json['hasCompanySettings'] == true,
        hasAdminUser: json['hasAdminUser'] == true,
        isInitialized: json['isInitialized'] == true,
        companyName: json['companyName']?.toString(),
        adminUserName: json['adminUserName']?.toString(),
      );
}

class InitializeCompanyPayload {
  const InitializeCompanyPayload({
    required this.companyName,
    required this.currency,
    required this.country,
    required this.timeZoneId,
    required this.defaultLanguage,
    required this.adminUserName,
    required this.adminDisplayName,
    required this.initialAdminSecret,
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
      };
}

class InitializeCompanyResultModel {
  const InitializeCompanyResultModel({
    required this.initialized,
    required this.companyName,
    required this.adminUserName,
    required this.adminRoleKey,
  });

  final bool initialized;
  final String companyName;
  final String adminUserName;
  final String adminRoleKey;

  factory InitializeCompanyResultModel.fromJson(Map<String, dynamic> json) => InitializeCompanyResultModel(
        initialized: json['initialized'] == true,
        companyName: json['companyName']?.toString() ?? '',
        adminUserName: json['adminUserName']?.toString() ?? '',
        adminRoleKey: json['adminRoleKey']?.toString() ?? '',
      );
}

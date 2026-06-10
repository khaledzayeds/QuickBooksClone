class ActiveCompanyRuntimeModel {
  const ActiveCompanyRuntimeModel({
    required this.databasePath,
    required this.businessType,
    required this.isActive,
    required this.isSetupInitialized,
    this.companyId,
    this.companyName,
    this.openedAtUtc,
  });

  final String? companyId;
  final String? companyName;
  final String databasePath;
  final String businessType;
  final bool isActive;
  final bool isSetupInitialized;
  final DateTime? openedAtUtc;

  factory ActiveCompanyRuntimeModel.fromJson(Map<String, dynamic> json) {
    return ActiveCompanyRuntimeModel(
      companyId: json['companyId']?.toString(),
      companyName: json['companyName']?.toString(),
      databasePath: json['databasePath']?.toString() ?? '',
      businessType: json['businessType']?.toString() ?? 'retail',
      isActive: json['isActive'] == true,
      isSetupInitialized: json['isSetupInitialized'] == true,
      openedAtUtc: DateTime.tryParse(json['openedAtUtc']?.toString() ?? ''),
    );
  }
}

class OpenCompanyRuntimeRequest {
  const OpenCompanyRuntimeRequest({
    required this.companyId,
    required this.companyName,
    required this.databasePath,
    required this.businessType,
  });

  final String companyId;
  final String companyName;
  final String databasePath;
  final String businessType;

  Map<String, dynamic> toJson() => {
    'companyId': companyId,
    'companyName': companyName,
    'databasePath': databasePath,
    'businessType': businessType,
  };
}

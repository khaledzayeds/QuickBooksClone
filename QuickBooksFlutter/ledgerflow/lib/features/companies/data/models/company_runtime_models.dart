class ActiveCompanyRuntimeModel {
  const ActiveCompanyRuntimeModel({
    required this.databasePath,
    required this.isActive,
    this.companyId,
    this.companyName,
    this.openedAtUtc,
  });

  final String? companyId;
  final String? companyName;
  final String databasePath;
  final bool isActive;
  final DateTime? openedAtUtc;

  factory ActiveCompanyRuntimeModel.fromJson(Map<String, dynamic> json) {
    return ActiveCompanyRuntimeModel(
      companyId: json['companyId']?.toString(),
      companyName: json['companyName']?.toString(),
      databasePath: json['databasePath']?.toString() ?? '',
      isActive: json['isActive'] == true,
      openedAtUtc: DateTime.tryParse(json['openedAtUtc']?.toString() ?? ''),
    );
  }
}

class OpenCompanyRuntimeRequest {
  const OpenCompanyRuntimeRequest({
    required this.companyId,
    required this.companyName,
    required this.databasePath,
  });

  final String companyId;
  final String companyName;
  final String databasePath;

  Map<String, dynamic> toJson() => {
    'companyId': companyId,
    'companyName': companyName,
    'databasePath': databasePath,
  };
}

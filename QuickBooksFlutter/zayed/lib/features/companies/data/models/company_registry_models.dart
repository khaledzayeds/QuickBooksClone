import 'dart:convert';

class LocalCompanyInfo {
  const LocalCompanyInfo({
    required this.id,
    required this.name,
    required this.databasePath,
    required this.createdAt,
    required this.lastOpenedAt,
    this.displayPath,
  });

  final String id;
  final String name;
  final String databasePath;
  final String? displayPath;
  final DateTime createdAt;
  final DateTime lastOpenedAt;

  LocalCompanyInfo copyWith({
    String? id,
    String? name,
    String? databasePath,
    String? displayPath,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
  }) {
    return LocalCompanyInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      databasePath: databasePath ?? this.databasePath,
      displayPath: displayPath ?? this.displayPath,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'databasePath': databasePath,
    'displayPath': displayPath,
    'createdAt': createdAt.toIso8601String(),
    'lastOpenedAt': lastOpenedAt.toIso8601String(),
  };

  factory LocalCompanyInfo.fromJson(Map<String, dynamic> json) {
    return LocalCompanyInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      databasePath: json['databasePath']?.toString() ?? '',
      displayPath: json['displayPath']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      lastOpenedAt: DateTime.tryParse(json['lastOpenedAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class CompanyRegistry {
  const CompanyRegistry({
    required this.companies,
    this.activeCompanyId,
  });

  final List<LocalCompanyInfo> companies;
  final String? activeCompanyId;

  bool get hasCompanies => companies.isNotEmpty;

  LocalCompanyInfo? get activeCompany {
    final activeId = activeCompanyId;
    if (activeId == null || activeId.isEmpty) return null;
    for (final company in companies) {
      if (company.id == activeId) return company;
    }
    return null;
  }

  CompanyRegistry copyWith({
    List<LocalCompanyInfo>? companies,
    String? activeCompanyId,
    bool clearActiveCompany = false,
  }) {
    return CompanyRegistry(
      companies: companies ?? this.companies,
      activeCompanyId: clearActiveCompany ? null : activeCompanyId ?? this.activeCompanyId,
    );
  }

  Map<String, dynamic> toJson() => {
    'activeCompanyId': activeCompanyId,
    'companies': companies.map((company) => company.toJson()).toList(),
  };

  String encode() => jsonEncode(toJson());

  factory CompanyRegistry.empty() => const CompanyRegistry(companies: []);

  factory CompanyRegistry.decode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return CompanyRegistry.empty();
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return CompanyRegistry.empty();
      final rawCompanies = decoded['companies'];
      final companies = rawCompanies is List
          ? rawCompanies
              .whereType<Map<String, dynamic>>()
              .map(LocalCompanyInfo.fromJson)
              .where((company) => company.id.isNotEmpty && company.name.isNotEmpty)
              .toList()
          : <LocalCompanyInfo>[];

      companies.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));

      return CompanyRegistry(
        companies: companies,
        activeCompanyId: decoded['activeCompanyId']?.toString(),
      );
    } catch (_) {
      return CompanyRegistry.empty();
    }
  }
}

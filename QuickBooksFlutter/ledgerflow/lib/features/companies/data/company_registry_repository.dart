import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import 'models/company_registry_models.dart';

class CompanyRegistryRepository {
  static const _registryKey = 'ledgerflow.companyRegistry.v1';
  static const _uuid = Uuid();

  Future<CompanyRegistry> load() async {
    final prefs = await SharedPreferences.getInstance();
    return CompanyRegistry.decode(prefs.getString(_registryKey));
  }

  Future<CompanyRegistry> save(CompanyRegistry registry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registryKey, registry.encode());
    return registry;
  }

  Future<CompanyRegistry> registerCompany({
    required String name,
    required String databasePath,
    String? displayPath,
    bool makeActive = true,
  }) async {
    final registry = await load();
    final now = DateTime.now();
    final normalizedName = name.trim();
    final normalizedPath = databasePath.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError('Company name is required.');
    }
    if (normalizedPath.isEmpty) {
      throw ArgumentError('Company database path is required.');
    }

    final existingIndex = registry.companies.indexWhere(
      (company) => company.databasePath.toLowerCase() == normalizedPath.toLowerCase(),
    );

    final companies = [...registry.companies];
    late final LocalCompanyInfo company;

    if (existingIndex >= 0) {
      company = companies[existingIndex].copyWith(
        name: normalizedName,
        displayPath: displayPath,
        lastOpenedAt: now,
      );
      companies[existingIndex] = company;
    } else {
      company = LocalCompanyInfo(
        id: _uuid.v4(),
        name: normalizedName,
        databasePath: normalizedPath,
        displayPath: displayPath,
        createdAt: now,
        lastOpenedAt: now,
      );
      companies.add(company);
    }

    companies.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));

    return save(
      CompanyRegistry(
        companies: companies,
        activeCompanyId: makeActive ? company.id : registry.activeCompanyId,
      ),
    );
  }

  Future<CompanyRegistry> openCompany(String companyId) async {
    final registry = await load();
    final now = DateTime.now();
    final companies = registry.companies.map((company) {
      if (company.id != companyId) return company;
      return company.copyWith(lastOpenedAt: now);
    }).toList()
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));

    final exists = companies.any((company) => company.id == companyId);
    if (!exists) {
      throw ArgumentError('Company was not found in the local registry.');
    }

    return save(CompanyRegistry(companies: companies, activeCompanyId: companyId));
  }

  Future<CompanyRegistry> removeCompany(String companyId) async {
    final registry = await load();
    final companies = registry.companies.where((company) => company.id != companyId).toList();
    final clearActive = registry.activeCompanyId == companyId;
    return save(
      CompanyRegistry(
        companies: companies,
        activeCompanyId: clearActive ? null : registry.activeCompanyId,
      ),
    );
  }

  String buildDefaultDatabaseFileName(String companyName) {
    final slug = companyName
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u0600-\u06FF]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final safeSlug = slug.isEmpty ? 'company' : slug;
    return '$safeSlug${AppConstants.companyFileExtension}';
  }
}

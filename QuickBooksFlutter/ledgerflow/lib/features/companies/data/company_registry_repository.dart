import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_result.dart';
import '../../../core/constants/app_constants.dart';
import 'datasources/company_runtime_datasource.dart';
import 'models/company_registry_models.dart';
import 'models/company_runtime_models.dart';

class CompanyRegistryRepository {
  CompanyRegistryRepository({CompanyRuntimeDatasource? runtimeDatasource})
      : _runtimeDatasource = runtimeDatasource ?? CompanyRuntimeDatasource();

  static const _registryKey = 'ledgerflow.companyRegistry.v1';
  static const _uuid = Uuid();

  final CompanyRuntimeDatasource _runtimeDatasource;

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

    final updated = CompanyRegistry(
      companies: companies,
      activeCompanyId: makeActive ? company.id : registry.activeCompanyId,
    );

    if (makeActive) {
      await _openRuntime(company);
    }

    return save(updated);
  }

  Future<CompanyRegistry> openCompany(String companyId) async {
    final registry = await load();
    LocalCompanyInfo? target;
    for (final company in registry.companies) {
      if (company.id == companyId) {
        target = company;
        break;
      }
    }

    if (target == null) {
      throw ArgumentError('Company was not found in the local registry.');
    }

    await _openRuntime(target);

    final now = DateTime.now();
    final companies = registry.companies.map((company) {
      if (company.id != companyId) return company;
      return company.copyWith(lastOpenedAt: now);
    }).toList()
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));

    return save(CompanyRegistry(companies: companies, activeCompanyId: companyId));
  }

  Future<CompanyRegistry> closeActiveCompany() async {
    final result = await _runtimeDatasource.close();
    switch (result) {
      case Success<ActiveCompanyRuntimeModel>():
        final registry = await load();
        return save(registry.copyWith(clearActiveCompany: true));
      case Failure<ActiveCompanyRuntimeModel>(error: final error):
        throw error;
    }
  }

  Future<CompanyRegistry> removeCompany(String companyId) async {
    final registry = await load();
    final companies = registry.companies.where((company) => company.id != companyId).toList();
    final clearActive = registry.activeCompanyId == companyId;
    if (clearActive) {
      await _runtimeDatasource.close();
    }
    return save(
      CompanyRegistry(
        companies: companies,
        activeCompanyId: clearActive ? null : registry.activeCompanyId,
      ),
    );
  }

  Future<ActiveCompanyRuntimeModel> getActiveRuntime() async {
    final result = await _runtimeDatasource.getActive();
    return switch (result) {
      Success<ActiveCompanyRuntimeModel>(data: final runtime) => runtime,
      Failure<ActiveCompanyRuntimeModel>(error: final error) => throw error,
    };
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

  Future<void> _openRuntime(LocalCompanyInfo company) async {
    final result = await _runtimeDatasource.open(
      OpenCompanyRuntimeRequest(
        companyId: company.id,
        companyName: company.name,
        databasePath: company.databasePath,
      ),
    );

    switch (result) {
      case Success<ActiveCompanyRuntimeModel>():
        return;
      case Failure<ActiveCompanyRuntimeModel>(error: final error):
        throw error;
    }
  }
}

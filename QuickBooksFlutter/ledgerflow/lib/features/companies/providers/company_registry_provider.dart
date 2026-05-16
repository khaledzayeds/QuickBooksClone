import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/company_registry_repository.dart';
import '../data/models/company_registry_models.dart';

final companyRegistryRepositoryProvider = Provider<CompanyRegistryRepository>(
  (_) => CompanyRegistryRepository(),
);

final companyRegistryProvider = AsyncNotifierProvider<CompanyRegistryNotifier, CompanyRegistry>(
  CompanyRegistryNotifier.new,
);

class CompanyRegistryNotifier extends AsyncNotifier<CompanyRegistry> {
  @override
  Future<CompanyRegistry> build() async {
    return ref.read(companyRegistryRepositoryProvider).load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(companyRegistryRepositoryProvider).load());
  }

  Future<void> registerCompany({
    required String name,
    required String databasePath,
    String? displayPath,
    bool makeActive = true,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(companyRegistryRepositoryProvider).registerCompany(
            name: name,
            databasePath: databasePath,
            displayPath: displayPath,
            makeActive: makeActive,
          ),
    );
  }

  Future<void> openCompany(String companyId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(companyRegistryRepositoryProvider).openCompany(companyId),
    );
  }

  Future<void> removeCompany(String companyId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(companyRegistryRepositoryProvider).removeCompany(companyId),
    );
  }
}

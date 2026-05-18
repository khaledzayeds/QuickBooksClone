import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/company_registry_repository.dart';
import '../data/models/company_registry_models.dart';

final companyRegistryRepositoryProvider = Provider<CompanyRegistryRepository>(
  (_) => CompanyRegistryRepository(),
);

final companyRegistryProvider =
    AsyncNotifierProvider<CompanyRegistryNotifier, CompanyRegistry>(
      CompanyRegistryNotifier.new,
    );

class CompanyRegistryNotifier extends AsyncNotifier<CompanyRegistry> {
  @override
  Future<CompanyRegistry> build() async {
    final registry = await ref.read(companyRegistryRepositoryProvider).load();

    final active = registry.activeCompany;
    if (active != null) {
      try {
        await ref.read(companyRegistryRepositoryProvider).reopenCompany(active);
      } catch (_) {
        final cleared = CompanyRegistry(
          companies: registry.companies,
          activeCompanyId: null,
        );
        await ref.read(companyRegistryRepositoryProvider).save(cleared);
        return cleared;
      }
    }

    return registry;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(companyRegistryRepositoryProvider).load(),
    );
  }

  Future<void> ensureOpen() async {
    final active = state.value?.activeCompany;
    if (active == null) throw StateError('No active company selected.');
    await ref.read(companyRegistryRepositoryProvider).reopenCompany(active);
  }

  Future<void> registerCompany({
    required String name,
    required String databasePath,
    String? displayPath,
    bool makeActive = true,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(companyRegistryRepositoryProvider)
          .registerCompany(
            name: name,
            databasePath: databasePath,
            displayPath: displayPath,
            makeActive: makeActive,
          ),
    );
    _throwIfFailed();
  }

  Future<void> openCompany(String companyId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(companyRegistryRepositoryProvider).openCompany(companyId),
    );
    _throwIfFailed();
  }

  Future<void> closeActiveCompany() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(companyRegistryRepositoryProvider).closeActiveCompany(),
    );
    _throwIfFailed();
  }

  Future<void> removeCompany(String companyId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () =>
          ref.read(companyRegistryRepositoryProvider).removeCompany(companyId),
    );
    _throwIfFailed();
  }

  void _throwIfFailed() {
    if (!state.hasError) return;
    throw state.error!;
  }
}

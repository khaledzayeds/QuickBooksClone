import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/settings_models.dart';
import '../data/settings_repository.dart';
import '../../companies/providers/company_registry_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);

final runtimeSettingsProvider = FutureProvider<RuntimeSettingsModel>((
  ref,
) async {
  final activeCompanyScope = ref.watch(activeCompanyScopeProvider);
  if (activeCompanyScope == null) {
    throw StateError('No active company selected.');
  }
  return ref.watch(settingsRepositoryProvider).getRuntime();
});

final companySettingsProvider = FutureProvider<CompanySettingsModel?>((
  ref,
) async {
  final activeCompanyScope = ref.watch(activeCompanyScopeProvider);
  if (activeCompanyScope == null) return null;
  return ref.watch(settingsRepositoryProvider).getCompany();
});

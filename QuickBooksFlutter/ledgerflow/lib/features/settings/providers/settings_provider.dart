import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/settings_models.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepository());

final runtimeSettingsProvider = FutureProvider<RuntimeSettingsModel>((ref) async {
  return ref.watch(settingsRepositoryProvider).getRuntime();
});

final companySettingsProvider = FutureProvider<CompanySettingsModel?>((ref) async {
  return ref.watch(settingsRepositoryProvider).getCompany();
});

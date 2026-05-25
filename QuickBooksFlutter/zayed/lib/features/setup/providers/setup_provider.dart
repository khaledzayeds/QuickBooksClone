import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_result.dart';
import '../../../core/utils/error_handler.dart';
import '../../companies/providers/company_registry_provider.dart';
import '../data/datasources/setup_remote_datasource.dart';
import '../data/models/setup_models.dart';

final _setupDatasourceProvider = Provider<SetupRemoteDatasource>(
  (_) => SetupRemoteDatasource(),
);

final setupProvider = AsyncNotifierProvider<SetupNotifier, SetupStatus>(
  () => SetupNotifier(),
);

class SetupNotifier extends AsyncNotifier<SetupStatus> {
  @override
  Future<SetupStatus> build() async {
    final registry = await ref.watch(companyRegistryProvider.future);
    if (registry.activeCompany == null) {
      return const SetupStatus(
        hasCompanySettings: false,
        hasAdminUser: false,
        isInitialized: false,
      );
    }

    await ref.read(companyRegistryProvider.notifier).ensureOpen();
    final result = await ref.read(_setupDatasourceProvider).getStatus();
    return result.when(
      success: (status) => status,
      failure: (error) => throw error,
    );
  }

  Future<AppError?> refreshStatus() async {
    state = const AsyncLoading();
    final registry = ref.read(companyRegistryProvider).value;
    if (registry?.activeCompany == null) {
      state = const AsyncData(
        SetupStatus(
          hasCompanySettings: false,
          hasAdminUser: false,
          isInitialized: false,
        ),
      );
      return null;
    }

    try {
      await ref.read(companyRegistryProvider.notifier).ensureOpen();
    } catch (error) {
      final appError = AppError(
        message: 'Company file could not be opened: $error',
      );
      state = AsyncError(appError, StackTrace.current);
      return appError;
    }

    final result = await ref.read(_setupDatasourceProvider).getStatus();
    return result.when(
      success: (status) {
        state = AsyncData(status);
        return null;
      },
      failure: (error) {
        state = AsyncError(error, StackTrace.current);
        return error;
      },
    );
  }

  Future<AppError?> initializeCompany(InitializeCompanyRequest request) async {
    final result = await ref
        .read(_setupDatasourceProvider)
        .initializeCompany(request);
    switch (result) {
      case Success<InitializeCompanyResponse>(data: final response):
        state = AsyncData(
          SetupStatus(
            hasCompanySettings: response.initialized,
            hasAdminUser: response.initialized,
            isInitialized: response.initialized,
            companyName: response.companyName,
            adminUserName: response.adminUserName,
          ),
        );
        return null;
      case Failure<InitializeCompanyResponse>(error: final error):
        return error;
    }
  }
}

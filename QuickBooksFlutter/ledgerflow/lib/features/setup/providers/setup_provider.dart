import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_result.dart';
import '../../../core/utils/error_handler.dart';
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
    final result = await ref.read(_setupDatasourceProvider).getStatus();
    return result.when(
      success: (status) => status,
      failure: (error) => throw error,
    );
  }

  Future<AppError?> refreshStatus() async {
    state = const AsyncLoading();
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
      case Success<InitializeCompanyResponse>():
        return refreshStatus();
      case Failure<InitializeCompanyResponse>(error: final error):
        return error;
    }
  }
}

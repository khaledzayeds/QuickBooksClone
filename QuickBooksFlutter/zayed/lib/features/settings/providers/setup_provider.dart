import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/setup_models.dart';
import '../data/setup_repository.dart';

final setupRepositoryProvider = Provider<SetupRepository>((ref) => SetupRepository());

class SetupState {
  const SetupState({
    this.loading = false,
    this.submitting = false,
    this.status,
    this.lastResult,
    this.defaultAccountsSeed,
    this.errorMessage,
    this.successMessage,
  });

  final bool loading;
  final bool submitting;
  final SetupStatusModel? status;
  final InitializeCompanyResultModel? lastResult;
  final DefaultAccountsSeedResultModel? defaultAccountsSeed;
  final String? errorMessage;
  final String? successMessage;

  SetupState copyWith({
    bool? loading,
    bool? submitting,
    SetupStatusModel? status,
    InitializeCompanyResultModel? lastResult,
    DefaultAccountsSeedResultModel? defaultAccountsSeed,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SetupState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      status: status ?? this.status,
      lastResult: lastResult ?? this.lastResult,
      defaultAccountsSeed: defaultAccountsSeed ?? this.defaultAccountsSeed,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

class SetupNotifier extends Notifier<SetupState> {
  late final SetupRepository _repository;

  @override
  SetupState build() {
    _repository = ref.watch(setupRepositoryProvider);
    Future.microtask(loadStatus);
    return const SetupState(loading: true);
  }

  Future<void> loadStatus() async {
    state = state.copyWith(loading: true, clearError: true, clearSuccess: true);
    try {
      final status = await _repository.getStatus();
      state = state.copyWith(loading: false, status: status, clearError: true);
    } catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.toString());
    }
  }

  Future<bool> initializeCompany(InitializeCompanyPayload payload) async {
    state = state.copyWith(submitting: true, clearError: true, clearSuccess: true);
    try {
      final result = await _repository.initializeCompany(payload);
      final status = await _repository.getStatus();
      state = state.copyWith(
        submitting: false,
        lastResult: result,
        status: status,
        successMessage: 'Company initialized: ${result.companyName}',
        clearError: true,
      );
      return status.isInitialized;
    } catch (error) {
      state = state.copyWith(submitting: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<void> seedDefaultAccounts() async {
    state = state.copyWith(submitting: true, clearError: true, clearSuccess: true);
    try {
      final result = await _repository.seedDefaultAccounts();
      state = state.copyWith(
        submitting: false,
        defaultAccountsSeed: result,
        successMessage: 'Default accounts ready. Created: ${result.createdCount}, skipped: ${result.skippedCount}',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(submitting: false, errorMessage: error.toString());
    }
  }
}

final setupProvider = NotifierProvider<SetupNotifier, SetupState>(SetupNotifier.new);

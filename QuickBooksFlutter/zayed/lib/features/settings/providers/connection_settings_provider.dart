import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/connection_settings_repository.dart';
import '../data/models/connection_settings_model.dart';

final connectionSettingsRepositoryProvider = Provider<ConnectionSettingsRepository>(
  (ref) => ConnectionSettingsRepository(),
);

class ConnectionSettingsState {
  const ConnectionSettingsState({
    required this.settings,
    this.loading = false,
    this.saving = false,
    this.testing = false,
    this.testResult,
    this.errorMessage,
  });

  final ConnectionSettingsModel settings;
  final bool loading;
  final bool saving;
  final bool testing;
  final ConnectionTestResult? testResult;
  final String? errorMessage;

  ConnectionSettingsState copyWith({
    ConnectionSettingsModel? settings,
    bool? loading,
    bool? saving,
    bool? testing,
    ConnectionTestResult? testResult,
    String? errorMessage,
    bool clearTestResult = false,
    bool clearError = false,
  }) {
    return ConnectionSettingsState(
      settings: settings ?? this.settings,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      testing: testing ?? this.testing,
      testResult: clearTestResult ? null : testResult ?? this.testResult,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ConnectionSettingsNotifier extends Notifier<ConnectionSettingsState> {
  late final ConnectionSettingsRepository _repository;

  @override
  ConnectionSettingsState build() {
    _repository = ref.watch(connectionSettingsRepositoryProvider);
    Future.microtask(load);
    return ConnectionSettingsState(settings: ConnectionSettingsModel.defaults(), loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final settings = await _repository.load();
      state = state.copyWith(settings: settings, loading: false, clearError: true);
    } catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.toString());
    }
  }

  void setProfileType(ConnectionProfileType profileType) {
    state = state.copyWith(
      settings: state.settings.copyWith(profileType: profileType).resolveBaseUrl(),
      clearTestResult: true,
      clearError: true,
    );
  }

  void setLanHost(String value) {
    state = state.copyWith(
      settings: state.settings.copyWith(lanHost: value).resolveBaseUrl(),
      clearTestResult: true,
      clearError: true,
    );
  }

  void setHostedUrl(String value) {
    state = state.copyWith(
      settings: state.settings.copyWith(hostedUrl: value).resolveBaseUrl(),
      clearTestResult: true,
      clearError: true,
    );
  }

  void setCustomUrl(String value) {
    state = state.copyWith(
      settings: state.settings.copyWith(customUrl: value).resolveBaseUrl(),
      clearTestResult: true,
      clearError: true,
    );
  }

  Future<void> save() async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      final settings = await _repository.save(state.settings);
      state = state.copyWith(settings: settings, saving: false, clearError: true);
    } catch (error) {
      state = state.copyWith(saving: false, errorMessage: error.toString());
    }
  }

  Future<void> test() async {
    state = state.copyWith(testing: true, clearTestResult: true, clearError: true);
    try {
      final result = await _repository.test(state.settings);
      state = state.copyWith(testing: false, testResult: result);
    } catch (error) {
      state = state.copyWith(testing: false, errorMessage: error.toString());
    }
  }
}

final connectionSettingsProvider = NotifierProvider<ConnectionSettingsNotifier, ConnectionSettingsState>(
  ConnectionSettingsNotifier.new,
);

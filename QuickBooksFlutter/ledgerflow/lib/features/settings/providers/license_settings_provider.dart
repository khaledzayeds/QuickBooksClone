import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/license_settings_repository.dart';
import '../data/models/license_settings_model.dart';

final licenseSettingsRepositoryProvider = Provider<LicenseSettingsRepository>((ref) => LicenseSettingsRepository());

class LicenseSettingsState {
  const LicenseSettingsState({
    required this.license,
    this.loading = false,
    this.saving = false,
    this.saved = false,
    this.errorMessage,
    this.activationMessage,
  });

  final LicenseSettingsModel license;
  final bool loading;
  final bool saving;
  final bool saved;
  final String? errorMessage;
  final String? activationMessage;

  LicenseSettingsState copyWith({
    LicenseSettingsModel? license,
    bool? loading,
    bool? saving,
    bool? saved,
    String? errorMessage,
    String? activationMessage,
    bool clearError = false,
    bool clearActivation = false,
  }) {
    return LicenseSettingsState(
      license: license ?? this.license,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      activationMessage: clearActivation ? null : activationMessage ?? this.activationMessage,
    );
  }
}

class LicenseSettingsNotifier extends Notifier<LicenseSettingsState> {
  late final LicenseSettingsRepository _repository;

  @override
  LicenseSettingsState build() {
    _repository = ref.watch(licenseSettingsRepositoryProvider);
    Future.microtask(load);
    return LicenseSettingsState(license: LicenseSettingsModel.defaults(), loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, saved: false, clearError: true, clearActivation: true);
    try {
      final license = await _repository.load();
      state = state.copyWith(license: license, loading: false, clearError: true);
    } catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.toString());
    }
  }

  void update(LicenseSettingsModel Function(LicenseSettingsModel current) change) {
    state = state.copyWith(license: change(state.license), saved: false, clearError: true, clearActivation: true);
  }

  Future<void> save() async {
    state = state.copyWith(saving: true, saved: false, clearError: true, clearActivation: true);
    try {
      final saved = await _repository.save(state.license.copyWith(lastValidatedAtIso: DateTime.now().toIso8601String()));
      state = state.copyWith(license: saved, saving: false, saved: true, clearError: true);
    } catch (error) {
      state = state.copyWith(saving: false, saved: false, errorMessage: error.toString());
    }
  }

  Future<void> applyEdition(LicenseEdition edition) async {
    state = state.copyWith(saving: true, saved: false, clearError: true, clearActivation: true);
    try {
      final saved = await _repository.applyEdition(edition);
      state = state.copyWith(license: saved, saving: false, saved: true, clearError: true);
    } catch (error) {
      state = state.copyWith(saving: false, saved: false, errorMessage: error.toString());
    }
  }

  Future<void> activateOnline({
    required String serial,
    required String deviceFingerprint,
    required String? companyName,
    String appVersion = '1.0.0',
  }) async {
    state = state.copyWith(saving: true, saved: false, clearError: true, clearActivation: true);
    try {
      final result = await _repository.activateOnline(
        serial: serial,
        deviceFingerprint: deviceFingerprint,
        companyName: companyName,
        appVersion: appVersion,
      );
      if (!result.success || result.license == null) {
        state = state.copyWith(saving: false, saved: false, errorMessage: result.message);
        return;
      }

      state = state.copyWith(
        license: result.license,
        saving: false,
        saved: true,
        activationMessage: 'Online activation completed. ${result.message}',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(saving: false, saved: false, errorMessage: error.toString());
    }
  }

  Future<void> applyPackage({required String package, required String deviceFingerprint}) async {
    state = state.copyWith(saving: true, saved: false, clearError: true, clearActivation: true);
    try {
      final result = await _repository.applyPackage(package: package, deviceFingerprint: deviceFingerprint);
      if (!result.success || result.license == null) {
        state = state.copyWith(saving: false, saved: false, errorMessage: result.message);
        return;
      }

      state = state.copyWith(
        license: result.license,
        saving: false,
        saved: true,
        activationMessage: result.message,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(saving: false, saved: false, errorMessage: error.toString());
    }
  }

  Future<void> reset() async {
    state = state.copyWith(saving: true, saved: false, clearError: true, clearActivation: true);
    try {
      final reset = await _repository.reset();
      state = state.copyWith(license: reset, saving: false, saved: true, clearError: true);
    } catch (error) {
      state = state.copyWith(saving: false, saved: false, errorMessage: error.toString());
    }
  }
}

final licenseSettingsProvider = NotifierProvider<LicenseSettingsNotifier, LicenseSettingsState>(
  LicenseSettingsNotifier.new,
);

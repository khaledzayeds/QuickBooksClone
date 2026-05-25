import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup_repository.dart';
import '../data/models/backup_models.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) => BackupRepository());

class BackupState {
  const BackupState({
    this.loading = false,
    this.working = false,
    this.backups = const [],
    this.audits = const [],
    this.settings,
    this.errorMessage,
    this.successMessage,
  });

  final bool loading;
  final bool working;
  final List<BackupFileModel> backups;
  final List<RestoreAuditModel> audits;
  final DatabaseMaintenanceSettingsModel? settings;
  final String? errorMessage;
  final String? successMessage;

  BackupState copyWith({
    bool? loading,
    bool? working,
    List<BackupFileModel>? backups,
    List<RestoreAuditModel>? audits,
    DatabaseMaintenanceSettingsModel? settings,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BackupState(
      loading: loading ?? this.loading,
      working: working ?? this.working,
      backups: backups ?? this.backups,
      audits: audits ?? this.audits,
      settings: settings ?? this.settings,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

class BackupNotifier extends Notifier<BackupState> {
  late final BackupRepository _repository;

  @override
  BackupState build() {
    _repository = ref.watch(backupRepositoryProvider);
    Future.microtask(load);
    return const BackupState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true, clearSuccess: true);
    try {
      final results = await Future.wait([
        _repository.listBackups(),
        _repository.listRestoreAudits(),
        _repository.getSettings(),
      ]);

      state = state.copyWith(
        loading: false,
        backups: results[0] as List<BackupFileModel>,
        audits: results[1] as List<RestoreAuditModel>,
        settings: results[2] as DatabaseMaintenanceSettingsModel,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.toString());
    }
  }

  Future<void> createBackup({String? label, String? reason}) async {
    state = state.copyWith(working: true, clearError: true, clearSuccess: true);
    try {
      final backup = await _repository.createBackup(label: label, reason: reason);
      final backups = [backup, ...state.backups];
      state = state.copyWith(
        working: false,
        backups: backups,
        successMessage: 'Backup created: ${backup.fileName}',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(working: false, errorMessage: error.toString());
    }
  }

  Future<void> restoreBackup({required String fileName, required bool createSafetyBackup, String? reason}) async {
    state = state.copyWith(working: true, clearError: true, clearSuccess: true);
    try {
      await _repository.restoreBackup(fileName: fileName, createSafetyBackup: createSafetyBackup, reason: reason);
      state = state.copyWith(
        working: false,
        successMessage: 'Backup restored: $fileName',
        clearError: true,
      );
      await load();
    } catch (error) {
      state = state.copyWith(working: false, errorMessage: error.toString());
    }
  }
}

final backupProvider = NotifierProvider<BackupNotifier, BackupState>(BackupNotifier.new);

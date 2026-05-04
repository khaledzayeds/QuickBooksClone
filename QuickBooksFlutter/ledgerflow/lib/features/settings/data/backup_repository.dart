import '../../../core/api/api_client.dart';
import 'models/backup_models.dart';

class BackupRepository {
  Future<List<BackupFileModel>> listBackups() async {
    final response = await ApiClient.instance.get<List<dynamic>>('/api/backups');
    final data = response.data ?? const [];
    return data.whereType<Map<String, dynamic>>().map(BackupFileModel.fromJson).toList();
  }

  Future<DatabaseMaintenanceSettingsModel> getSettings() async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/backups/settings');
    return DatabaseMaintenanceSettingsModel.fromJson(response.data ?? const {});
  }

  Future<BackupFileModel> createBackup({String? label, String? reason}) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/backups',
      data: {
        'label': label,
        'reason': reason,
      },
    );
    return BackupFileModel.fromJson(response.data ?? const {});
  }

  Future<void> restoreBackup({required String fileName, required bool createSafetyBackup, String? reason}) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/backups/restore',
      data: {
        'fileName': fileName,
        'createSafetyBackup': createSafetyBackup,
        'reason': reason,
      },
    );
  }

  Future<List<RestoreAuditModel>> listRestoreAudits() async {
    final response = await ApiClient.instance.get<List<dynamic>>('/api/backups/restore-audits');
    final data = response.data ?? const [];
    return data.whereType<Map<String, dynamic>>().map(RestoreAuditModel.fromJson).toList();
  }
}

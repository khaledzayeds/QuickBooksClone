class BackupFileModel {
  const BackupFileModel({
    required this.fileName,
    required this.sizeBytes,
    required this.createdAtIso,
    required this.backupKind,
    this.label,
    this.requestedBy,
    this.reason,
  });

  final String fileName;
  final int sizeBytes;
  final String createdAtIso;
  final String backupKind;
  final String? label;
  final String? requestedBy;
  final String? reason;

  factory BackupFileModel.fromJson(Map<String, dynamic> json) => BackupFileModel(
        fileName: json['fileName']?.toString() ?? '',
        sizeBytes: json['sizeBytes'] is num ? (json['sizeBytes'] as num).toInt() : int.tryParse(json['sizeBytes']?.toString() ?? '') ?? 0,
        createdAtIso: json['createdAt']?.toString() ?? '',
        backupKind: json['backupKind']?.toString() ?? '',
        label: json['label']?.toString(),
        requestedBy: json['requestedBy']?.toString(),
        reason: json['reason']?.toString(),
      );
}

class DatabaseMaintenanceSettingsModel {
  const DatabaseMaintenanceSettingsModel({
    required this.autoBackupEnabled,
    required this.scheduleMode,
    required this.runAtHourLocal,
    required this.retentionCount,
    required this.createSafetyBackupBeforeRestore,
    this.preferredLabelPrefix,
    this.updatedAtIso,
    this.updatedBy,
  });

  final bool autoBackupEnabled;
  final String scheduleMode;
  final int runAtHourLocal;
  final int retentionCount;
  final bool createSafetyBackupBeforeRestore;
  final String? preferredLabelPrefix;
  final String? updatedAtIso;
  final String? updatedBy;

  factory DatabaseMaintenanceSettingsModel.fromJson(Map<String, dynamic> json) => DatabaseMaintenanceSettingsModel(
        autoBackupEnabled: json['autoBackupEnabled'] == true,
        scheduleMode: json['scheduleMode']?.toString() ?? 'Daily',
        runAtHourLocal: json['runAtHourLocal'] is num ? (json['runAtHourLocal'] as num).toInt() : int.tryParse(json['runAtHourLocal']?.toString() ?? '') ?? 2,
        retentionCount: json['retentionCount'] is num ? (json['retentionCount'] as num).toInt() : int.tryParse(json['retentionCount']?.toString() ?? '') ?? 14,
        createSafetyBackupBeforeRestore: json['createSafetyBackupBeforeRestore'] != false,
        preferredLabelPrefix: json['preferredLabelPrefix']?.toString(),
        updatedAtIso: json['updatedAt']?.toString(),
        updatedBy: json['updatedBy']?.toString(),
      );
}

class RestoreAuditModel {
  const RestoreAuditModel({
    required this.backupFileName,
    required this.restoredAtIso,
    required this.createdSafetyBackup,
    required this.provider,
    this.safetyBackupFileName,
    this.requestedBy,
    this.reason,
  });

  final String backupFileName;
  final String restoredAtIso;
  final bool createdSafetyBackup;
  final String provider;
  final String? safetyBackupFileName;
  final String? requestedBy;
  final String? reason;

  factory RestoreAuditModel.fromJson(Map<String, dynamic> json) => RestoreAuditModel(
        backupFileName: json['backupFileName']?.toString() ?? '',
        restoredAtIso: json['restoredAt']?.toString() ?? '',
        createdSafetyBackup: json['createdSafetyBackup'] == true,
        provider: json['provider']?.toString() ?? '',
        safetyBackupFileName: json['safetyBackupFileName']?.toString(),
        requestedBy: json['requestedBy']?.toString(),
        reason: json['reason']?.toString(),
      );
}

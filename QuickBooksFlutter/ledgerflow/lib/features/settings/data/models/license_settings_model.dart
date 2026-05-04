enum LicenseEdition {
  trial,
  solo,
  network,
  hosted;

  String get label => switch (this) {
        LicenseEdition.trial => 'Trial / Demo',
        LicenseEdition.solo => 'Solo Desktop',
        LicenseEdition.network => 'Network / LAN',
        LicenseEdition.hosted => 'Hosted / Cloud',
      };

  String get description => switch (this) {
        LicenseEdition.trial => 'For demos, evaluation, and limited sample-company usage.',
        LicenseEdition.solo => 'Single device, local API, local SQLite/company file.',
        LicenseEdition.network => 'LAN server/client setup with SQL Server and multiple users/devices.',
        LicenseEdition.hosted => 'Hosted API/database subscription with remote access.',
      };

  static LicenseEdition fromName(String? value) {
    return LicenseEdition.values.firstWhere(
      (edition) => edition.name == value,
      orElse: () => LicenseEdition.trial,
    );
  }
}

enum LicenseStatus {
  inactive,
  trial,
  active,
  expired,
  blocked;

  String get label => switch (this) {
        LicenseStatus.inactive => 'Inactive',
        LicenseStatus.trial => 'Trial',
        LicenseStatus.active => 'Active',
        LicenseStatus.expired => 'Expired',
        LicenseStatus.blocked => 'Blocked',
      };

  static LicenseStatus fromName(String? value) {
    return LicenseStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => LicenseStatus.trial,
    );
  }
}

class LicenseSettingsModel {
  const LicenseSettingsModel({
    required this.edition,
    required this.status,
    required this.maxUsers,
    required this.maxDevices,
    required this.offlineGraceDays,
    required this.allowLocalMode,
    required this.allowLanMode,
    required this.allowHostedMode,
    required this.allowBackupRestore,
    required this.allowDemoCompany,
    required this.allowAdvancedInventory,
    required this.allowPayroll,
    this.licenseKey,
    this.companyName,
    this.activatedDeviceId,
    this.expiresAtIso,
    this.lastValidatedAtIso,
  });

  final LicenseEdition edition;
  final LicenseStatus status;
  final int maxUsers;
  final int maxDevices;
  final int offlineGraceDays;
  final bool allowLocalMode;
  final bool allowLanMode;
  final bool allowHostedMode;
  final bool allowBackupRestore;
  final bool allowDemoCompany;
  final bool allowAdvancedInventory;
  final bool allowPayroll;
  final String? licenseKey;
  final String? companyName;
  final String? activatedDeviceId;
  final String? expiresAtIso;
  final String? lastValidatedAtIso;

  factory LicenseSettingsModel.defaults() => const LicenseSettingsModel(
        edition: LicenseEdition.trial,
        status: LicenseStatus.trial,
        maxUsers: 1,
        maxDevices: 1,
        offlineGraceDays: 7,
        allowLocalMode: true,
        allowLanMode: false,
        allowHostedMode: false,
        allowBackupRestore: false,
        allowDemoCompany: true,
        allowAdvancedInventory: false,
        allowPayroll: false,
      );

  factory LicenseSettingsModel.forEdition(LicenseEdition edition) {
    return switch (edition) {
      LicenseEdition.trial => LicenseSettingsModel.defaults(),
      LicenseEdition.solo => const LicenseSettingsModel(
          edition: LicenseEdition.solo,
          status: LicenseStatus.active,
          maxUsers: 1,
          maxDevices: 1,
          offlineGraceDays: 30,
          allowLocalMode: true,
          allowLanMode: false,
          allowHostedMode: false,
          allowBackupRestore: true,
          allowDemoCompany: true,
          allowAdvancedInventory: false,
          allowPayroll: false,
        ),
      LicenseEdition.network => const LicenseSettingsModel(
          edition: LicenseEdition.network,
          status: LicenseStatus.active,
          maxUsers: 5,
          maxDevices: 3,
          offlineGraceDays: 14,
          allowLocalMode: true,
          allowLanMode: true,
          allowHostedMode: false,
          allowBackupRestore: true,
          allowDemoCompany: true,
          allowAdvancedInventory: true,
          allowPayroll: false,
        ),
      LicenseEdition.hosted => const LicenseSettingsModel(
          edition: LicenseEdition.hosted,
          status: LicenseStatus.active,
          maxUsers: 10,
          maxDevices: 10,
          offlineGraceDays: 3,
          allowLocalMode: false,
          allowLanMode: false,
          allowHostedMode: true,
          allowBackupRestore: true,
          allowDemoCompany: true,
          allowAdvancedInventory: true,
          allowPayroll: true,
        ),
    };
  }

  LicenseSettingsModel copyWith({
    LicenseEdition? edition,
    LicenseStatus? status,
    int? maxUsers,
    int? maxDevices,
    int? offlineGraceDays,
    bool? allowLocalMode,
    bool? allowLanMode,
    bool? allowHostedMode,
    bool? allowBackupRestore,
    bool? allowDemoCompany,
    bool? allowAdvancedInventory,
    bool? allowPayroll,
    String? licenseKey,
    String? companyName,
    String? activatedDeviceId,
    String? expiresAtIso,
    String? lastValidatedAtIso,
  }) {
    return LicenseSettingsModel(
      edition: edition ?? this.edition,
      status: status ?? this.status,
      maxUsers: maxUsers ?? this.maxUsers,
      maxDevices: maxDevices ?? this.maxDevices,
      offlineGraceDays: offlineGraceDays ?? this.offlineGraceDays,
      allowLocalMode: allowLocalMode ?? this.allowLocalMode,
      allowLanMode: allowLanMode ?? this.allowLanMode,
      allowHostedMode: allowHostedMode ?? this.allowHostedMode,
      allowBackupRestore: allowBackupRestore ?? this.allowBackupRestore,
      allowDemoCompany: allowDemoCompany ?? this.allowDemoCompany,
      allowAdvancedInventory: allowAdvancedInventory ?? this.allowAdvancedInventory,
      allowPayroll: allowPayroll ?? this.allowPayroll,
      licenseKey: licenseKey ?? this.licenseKey,
      companyName: companyName ?? this.companyName,
      activatedDeviceId: activatedDeviceId ?? this.activatedDeviceId,
      expiresAtIso: expiresAtIso ?? this.expiresAtIso,
      lastValidatedAtIso: lastValidatedAtIso ?? this.lastValidatedAtIso,
    );
  }

  Map<String, String> toStorage() => {
        'edition': edition.name,
        'status': status.name,
        'maxUsers': maxUsers.toString(),
        'maxDevices': maxDevices.toString(),
        'offlineGraceDays': offlineGraceDays.toString(),
        'allowLocalMode': allowLocalMode.toString(),
        'allowLanMode': allowLanMode.toString(),
        'allowHostedMode': allowHostedMode.toString(),
        'allowBackupRestore': allowBackupRestore.toString(),
        'allowDemoCompany': allowDemoCompany.toString(),
        'allowAdvancedInventory': allowAdvancedInventory.toString(),
        'allowPayroll': allowPayroll.toString(),
        'licenseKey': licenseKey ?? '',
        'companyName': companyName ?? '',
        'activatedDeviceId': activatedDeviceId ?? '',
        'expiresAtIso': expiresAtIso ?? '',
        'lastValidatedAtIso': lastValidatedAtIso ?? '',
      };

  factory LicenseSettingsModel.fromStorage(Map<String, String?> values) {
    final defaults = LicenseSettingsModel.defaults();
    bool boolValue(String key, bool fallback) => values[key] == null ? fallback : values[key] == 'true';
    int intValue(String key, int fallback) => int.tryParse(values[key] ?? '') ?? fallback;
    String? stringValue(String key) => values[key]?.isNotEmpty == true ? values[key] : null;

    return LicenseSettingsModel(
      edition: LicenseEdition.fromName(values['edition']),
      status: LicenseStatus.fromName(values['status']),
      maxUsers: intValue('maxUsers', defaults.maxUsers),
      maxDevices: intValue('maxDevices', defaults.maxDevices),
      offlineGraceDays: intValue('offlineGraceDays', defaults.offlineGraceDays),
      allowLocalMode: boolValue('allowLocalMode', defaults.allowLocalMode),
      allowLanMode: boolValue('allowLanMode', defaults.allowLanMode),
      allowHostedMode: boolValue('allowHostedMode', defaults.allowHostedMode),
      allowBackupRestore: boolValue('allowBackupRestore', defaults.allowBackupRestore),
      allowDemoCompany: boolValue('allowDemoCompany', defaults.allowDemoCompany),
      allowAdvancedInventory: boolValue('allowAdvancedInventory', defaults.allowAdvancedInventory),
      allowPayroll: boolValue('allowPayroll', defaults.allowPayroll),
      licenseKey: stringValue('licenseKey'),
      companyName: stringValue('companyName'),
      activatedDeviceId: stringValue('activatedDeviceId'),
      expiresAtIso: stringValue('expiresAtIso'),
      lastValidatedAtIso: stringValue('lastValidatedAtIso'),
    );
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import 'license_package_verifier.dart';
import 'models/license_settings_model.dart';

class ApplyLicensePackageResult {
  const ApplyLicensePackageResult({
    required this.success,
    required this.message,
    this.license,
  });

  final bool success;
  final String message;
  final LicenseSettingsModel? license;
}

class LicenseSettingsRepository {
  static const _prefix = 'license.';

  Future<LicenseSettingsModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LicenseSettingsModel.fromStorage({
      'edition': prefs.getString('${_prefix}edition'),
      'status': prefs.getString('${_prefix}status'),
      'maxUsers': prefs.getString('${_prefix}maxUsers'),
      'maxDevices': prefs.getString('${_prefix}maxDevices'),
      'offlineGraceDays': prefs.getString('${_prefix}offlineGraceDays'),
      'allowLocalMode': prefs.getString('${_prefix}allowLocalMode'),
      'allowLanMode': prefs.getString('${_prefix}allowLanMode'),
      'allowHostedMode': prefs.getString('${_prefix}allowHostedMode'),
      'allowBackupRestore': prefs.getString('${_prefix}allowBackupRestore'),
      'allowDemoCompany': prefs.getString('${_prefix}allowDemoCompany'),
      'allowAdvancedInventory': prefs.getString('${_prefix}allowAdvancedInventory'),
      'allowPayroll': prefs.getString('${_prefix}allowPayroll'),
      'licenseKey': prefs.getString('${_prefix}licenseKey'),
      'companyName': prefs.getString('${_prefix}companyName'),
      'activatedDeviceId': prefs.getString('${_prefix}activatedDeviceId'),
      'expiresAtIso': prefs.getString('${_prefix}expiresAtIso'),
      'lastValidatedAtIso': prefs.getString('${_prefix}lastValidatedAtIso'),
    });
  }

  Future<LicenseSettingsModel> save(LicenseSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final values = settings.toStorage();
    for (final entry in values.entries) {
      await prefs.setString('$_prefix${entry.key}', entry.value);
    }
    return settings;
  }

  Future<LicenseSettingsModel> applyEdition(LicenseEdition edition) async {
    final current = await load();
    final next = LicenseSettingsModel.forEdition(edition).copyWith(
      licenseKey: current.licenseKey,
      companyName: current.companyName,
      activatedDeviceId: current.activatedDeviceId,
      expiresAtIso: current.expiresAtIso,
      lastValidatedAtIso: DateTime.now().toIso8601String(),
    );
    return save(next);
  }

  Future<ApplyLicensePackageResult> applyPackage({
    required String package,
    required String deviceFingerprint,
  }) async {
    final result = LicensePackageVerifier().verifyPackage(
      package: package,
      deviceFingerprint: deviceFingerprint,
    );

    if (!result.success || result.license == null) {
      return ApplyLicensePackageResult(success: false, message: result.message);
    }

    final saved = await save(result.license!);
    return ApplyLicensePackageResult(success: true, message: result.message, license: saved);
  }

  Future<LicenseSettingsModel> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    return LicenseSettingsModel.defaults();
  }
}

import 'dart:convert';

import 'models/license_settings_model.dart';

class LicensePackageVerificationResult {
  const LicensePackageVerificationResult({
    required this.success,
    required this.message,
    this.license,
    this.payload,
  });

  final bool success;
  final String message;
  final LicenseSettingsModel? license;
  final Map<String, dynamic>? payload;
}

class LicensePackageVerifier {
  /// Expected development format:
  ///
  /// base64Url(payloadJson).base64Url(signature)
  ///
  /// Current stage validates structure, decodes payload, checks optional device id,
  /// and maps the payload to LicenseSettingsModel. Real production signature
  /// verification should use a public key and must replace [_verifySignature].
  LicensePackageVerificationResult verifyPackage({
    required String package,
    required String deviceFingerprint,
  }) {
    final trimmed = package.trim();
    if (trimmed.isEmpty) {
      return const LicensePackageVerificationResult(success: false, message: 'License package is empty.');
    }

    final parts = trimmed.split('.');
    if (parts.length != 2) {
      return const LicensePackageVerificationResult(
        success: false,
        message: 'Invalid package format. Expected payload.signature.',
      );
    }

    try {
      final payloadText = utf8.decode(base64Url.decode(base64Url.normalize(parts[0])));
      final payload = jsonDecode(payloadText) as Map<String, dynamic>;
      final signature = parts[1];

      if (!_verifySignature(payloadText: payloadText, signature: signature)) {
        return const LicensePackageVerificationResult(
          success: false,
          message: 'License signature is invalid or unsupported in this build.',
        );
      }

      final payloadDeviceId = payload['deviceId']?.toString();
      if (payloadDeviceId != null && payloadDeviceId.isNotEmpty && payloadDeviceId != deviceFingerprint) {
        return const LicensePackageVerificationResult(
          success: false,
          message: 'This license package is for another device.',
        );
      }

      final license = _licenseFromPayload(payload, deviceFingerprint);
      return LicensePackageVerificationResult(
        success: true,
        message: 'License package decoded successfully. Production signature verification is still pending.',
        license: license,
        payload: payload,
      );
    } catch (error) {
      return LicensePackageVerificationResult(
        success: false,
        message: 'Could not decode license package: $error',
      );
    }
  }

  bool _verifySignature({required String payloadText, required String signature}) {
    // TODO: Replace this development placeholder with Ed25519/RSA/ECDSA public-key verification.
    // For now we only require a non-empty signature so the app can be wired end-to-end.
    return payloadText.isNotEmpty && signature.trim().isNotEmpty;
  }

  LicenseSettingsModel _licenseFromPayload(Map<String, dynamic> payload, String fallbackDeviceFingerprint) {
    final features = (payload['features'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final edition = LicenseEdition.fromName(payload['edition']?.toString());
    final base = LicenseSettingsModel.forEdition(edition);

    bool feature(String key, bool fallback) => features[key] is bool ? features[key] as bool : fallback;
    int intValue(String key, int fallback) => payload[key] is num ? (payload[key] as num).toInt() : int.tryParse(payload[key]?.toString() ?? '') ?? fallback;

    return base.copyWith(
      status: LicenseStatus.fromName(payload['status']?.toString()),
      maxUsers: intValue('maxUsers', base.maxUsers),
      maxDevices: intValue('maxDevices', base.maxDevices),
      offlineGraceDays: intValue('offlineGraceDays', base.offlineGraceDays),
      allowLocalMode: feature('localMode', base.allowLocalMode),
      allowLanMode: feature('lanMode', base.allowLanMode),
      allowHostedMode: feature('hostedMode', base.allowHostedMode),
      allowBackupRestore: feature('backupRestore', base.allowBackupRestore),
      allowDemoCompany: feature('demoCompany', base.allowDemoCompany),
      allowAdvancedInventory: feature('advancedInventory', base.allowAdvancedInventory),
      allowPayroll: feature('payroll', base.allowPayroll),
      licenseKey: payload['serial']?.toString() ?? payload['licenseId']?.toString(),
      companyName: payload['customerName']?.toString(),
      activatedDeviceId: payload['deviceId']?.toString() ?? fallbackDeviceFingerprint,
      expiresAtIso: payload['expiresAt']?.toString(),
      lastValidatedAtIso: DateTime.now().toUtc().toIso8601String(),
    );
  }
}

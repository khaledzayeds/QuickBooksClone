import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'license_public_key.dart';
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
  /// Expected production format:
  ///
  /// base64Url(payloadJson).base64Url(ed25519Signature)
  ///
  /// The app verifies the signature using the embedded Ed25519 public key.
  Future<LicensePackageVerificationResult> verifyPackage({
    required String package,
    required String deviceFingerprint,
  }) async {
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
      final payloadBytes = base64Url.decode(base64Url.normalize(parts[0]));
      final payloadText = utf8.decode(payloadBytes);
      final payload = jsonDecode(payloadText) as Map<String, dynamic>;
      final signatureBytes = base64Url.decode(base64Url.normalize(parts[1]));

      final signatureOk = await _verifySignature(payloadBytes: payloadBytes, signatureBytes: signatureBytes);
      if (!signatureOk) {
        return const LicensePackageVerificationResult(
          success: false,
          message: 'License signature is invalid. Check the public key or package contents.',
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
        message: 'License package verified and applied successfully.',
        license: license,
        payload: payload,
      );
    } catch (error) {
      return LicensePackageVerificationResult(
        success: false,
        message: 'Could not verify license package: $error',
      );
    }
  }

  Future<bool> _verifySignature({required List<int> payloadBytes, required List<int> signatureBytes}) async {
    if (!LicensePublicKeyConfig.hasConfiguredPublicKey) {
      throw StateError('License public key is not configured. Generate a keypair and paste the public key in LicensePublicKeyConfig.');
    }

    final publicKeyBytes = base64.decode(LicensePublicKeyConfig.ed25519PublicKeyBase64);
    final algorithm = Ed25519();
    final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);
    final signature = Signature(signatureBytes, publicKey: publicKey);
    return algorithm.verify(payloadBytes, signature: signature);
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

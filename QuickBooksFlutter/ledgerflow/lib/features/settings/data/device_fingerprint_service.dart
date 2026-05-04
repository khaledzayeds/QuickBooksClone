import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceFingerprintInfo {
  const DeviceFingerprintInfo({
    required this.installationId,
    required this.deviceFingerprint,
    required this.generatedAtIso,
  });

  final String installationId;
  final String deviceFingerprint;
  final String generatedAtIso;
}

class DeviceFingerprintService {
  static const _installationIdKey = 'license.installationId';
  static const _generatedAtKey = 'license.installationGeneratedAt';
  static const _salt = 'LedgerFlow-License-Fingerprint-v1';

  Future<DeviceFingerprintInfo> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    var installationId = prefs.getString(_installationIdKey);
    var generatedAt = prefs.getString(_generatedAtKey);

    if (installationId == null || installationId.isEmpty) {
      installationId = _createInstallationId();
      generatedAt = DateTime.now().toUtc().toIso8601String();
      await prefs.setString(_installationIdKey, installationId);
      await prefs.setString(_generatedAtKey, generatedAt);
    }

    final fingerprint = _hashInstallationId(installationId);
    return DeviceFingerprintInfo(
      installationId: installationId,
      deviceFingerprint: fingerprint,
      generatedAtIso: generatedAt ?? '',
    );
  }

  Future<DeviceFingerprintInfo> rotateForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    final installationId = _createInstallationId();
    final generatedAt = DateTime.now().toUtc().toIso8601String();
    await prefs.setString(_installationIdKey, installationId);
    await prefs.setString(_generatedAtKey, generatedAt);

    return DeviceFingerprintInfo(
      installationId: installationId,
      deviceFingerprint: _hashInstallationId(installationId),
      generatedAtIso: generatedAt,
    );
  }

  static String _hashInstallationId(String installationId) {
    final bytes = utf8.encode('$_salt|$installationId');
    return sha256.convert(bytes).toString();
  }

  static String _createInstallationId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final time = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(16);
    return '$time-${base64UrlEncode(bytes).replaceAll('=', '')}';
  }
}

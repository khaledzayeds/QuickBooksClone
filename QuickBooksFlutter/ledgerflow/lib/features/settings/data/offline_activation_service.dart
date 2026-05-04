import 'dart:convert';

import 'device_fingerprint_service.dart';
import 'models/license_settings_model.dart';

class OfflineActivationRequest {
  const OfflineActivationRequest({
    required this.requestCode,
    required this.payload,
    required this.createdAtIso,
  });

  final String requestCode;
  final Map<String, dynamic> payload;
  final String createdAtIso;
}

class OfflineActivationService {
  static const requestPrefix = 'LFREQ';

  Future<OfflineActivationRequest> createRequest({
    required LicenseSettingsModel currentLicense,
  }) async {
    final device = await DeviceFingerprintService().getOrCreate();
    final createdAt = DateTime.now().toUtc().toIso8601String();

    final payload = <String, dynamic>{
      'schema': 'ledgerflow-offline-activation-request-v1',
      'createdAt': createdAt,
      'serial': currentLicense.licenseKey ?? '',
      'customerName': currentLicense.companyName ?? '',
      'requestedEdition': currentLicense.edition.name,
      'deviceFingerprint': device.deviceFingerprint,
      'installationId': device.installationId,
      'app': 'LedgerFlow',
    };

    final jsonText = jsonEncode(payload);
    final encoded = base64UrlEncode(utf8.encode(jsonText)).replaceAll('=', '');

    return OfflineActivationRequest(
      requestCode: '$requestPrefix.$encoded',
      payload: payload,
      createdAtIso: createdAt,
    );
  }

  Map<String, dynamic> decodeRequestCode(String requestCode) {
    final trimmed = requestCode.trim();
    if (!trimmed.startsWith('$requestPrefix.')) {
      throw const FormatException('Invalid offline activation request prefix.');
    }

    final encoded = trimmed.substring(requestPrefix.length + 1);
    final jsonText = utf8.decode(base64Url.decode(base64Url.normalize(encoded)));
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid offline activation request payload.');
    }

    return decoded;
  }
}

import '../../../../core/constants/app_constants.dart';

enum ConnectionProfileType {
  local,
  lan,
  hosted,
  custom;

  String get label => switch (this) {
    ConnectionProfileType.local => 'Local',
    ConnectionProfileType.lan => 'LAN',
    ConnectionProfileType.hosted => 'Hosted',
    ConnectionProfileType.custom => 'Custom',
  };

  static ConnectionProfileType fromName(String? value) {
    return ConnectionProfileType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ConnectionProfileType.local,
    );
  }
}

class ConnectionSettingsModel {
  const ConnectionSettingsModel({
    required this.profileType,
    required this.baseUrl,
    this.lanHost,
    this.hostedUrl,
    this.customUrl,
  });

  final ConnectionProfileType profileType;
  final String baseUrl;
  final String? lanHost;
  final String? hostedUrl;
  final String? customUrl;

  static const offlineOnly = true;
  static const defaultLocalUrl = AppConstants.defaultBaseUrl;

  // Kept for source compatibility with LAN/hosted screens until those are split
  // into their own future branches. The offline build never resolves to them.
  static const defaultLanHost = '';
  static const defaultHostedUrl = '';

  factory ConnectionSettingsModel.defaults() {
    return const ConnectionSettingsModel(
      profileType: ConnectionProfileType.local,
      baseUrl: defaultLocalUrl,
    );
  }

  ConnectionSettingsModel copyWith({
    ConnectionProfileType? profileType,
    String? baseUrl,
    String? lanHost,
    String? hostedUrl,
    String? customUrl,
  }) {
    return ConnectionSettingsModel(
      profileType: profileType ?? this.profileType,
      baseUrl: baseUrl ?? this.baseUrl,
      lanHost: lanHost ?? this.lanHost,
      hostedUrl: hostedUrl ?? this.hostedUrl,
      customUrl: customUrl ?? this.customUrl,
    );
  }

  ConnectionSettingsModel resolveBaseUrl() {
    return const ConnectionSettingsModel(
      profileType: ConnectionProfileType.local,
      baseUrl: defaultLocalUrl,
    );
  }

  Map<String, String> toStorage() => const {
    'profileType': 'local',
    'baseUrl': defaultLocalUrl,
    'lanHost': '',
    'hostedUrl': '',
    'customUrl': '',
  };

  factory ConnectionSettingsModel.fromStorage(Map<String, String?> values) {
    return ConnectionSettingsModel.defaults();
  }
}

class ConnectionTestResult {
  const ConnectionTestResult({required this.success, required this.message});

  final bool success;
  final String message;
}

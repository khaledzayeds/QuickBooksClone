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

  static const defaultLocalUrl = 'http://localhost:5014';
  static const defaultLanHost = '192.168.1.100:5014';
  static const defaultHostedUrl = 'https://your-server.com';

  factory ConnectionSettingsModel.defaults() {
    return const ConnectionSettingsModel(
      profileType: ConnectionProfileType.local,
      baseUrl: defaultLocalUrl,
      lanHost: defaultLanHost,
      hostedUrl: defaultHostedUrl,
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
    final resolved = switch (profileType) {
      ConnectionProfileType.local => defaultLocalUrl,
      ConnectionProfileType.lan => _normalizeLanHost(lanHost ?? defaultLanHost),
      ConnectionProfileType.hosted => _normalizeUrl(
        hostedUrl ?? defaultHostedUrl,
      ),
      ConnectionProfileType.custom => _normalizeUrl(customUrl ?? baseUrl),
    };

    return copyWith(baseUrl: resolved);
  }

  Map<String, String> toStorage() => {
    'profileType': profileType.name,
    'baseUrl': baseUrl,
    'lanHost': lanHost ?? '',
    'hostedUrl': hostedUrl ?? '',
    'customUrl': customUrl ?? '',
  };

  factory ConnectionSettingsModel.fromStorage(Map<String, String?> values) {
    final profileType = ConnectionProfileType.fromName(values['profileType']);
    final model = ConnectionSettingsModel(
      profileType: profileType,
      baseUrl: values['baseUrl']?.isNotEmpty == true
          ? values['baseUrl']!
          : defaultLocalUrl,
      lanHost: values['lanHost']?.isNotEmpty == true
          ? values['lanHost']
          : defaultLanHost,
      hostedUrl: values['hostedUrl']?.isNotEmpty == true
          ? values['hostedUrl']
          : defaultHostedUrl,
      customUrl: values['customUrl']?.isNotEmpty == true
          ? values['customUrl']
          : null,
    );
    return model.resolveBaseUrl();
  }

  static String _normalizeLanHost(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
      return trimmed;
    return 'http://$trimmed';
  }

  static String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
      return trimmed;
    return 'http://$trimmed';
  }
}

class ConnectionTestResult {
  const ConnectionTestResult({required this.success, required this.message});

  final bool success;
  final String message;
}

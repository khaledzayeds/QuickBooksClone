// features/runtime/data/models/runtime_model.dart

class RuntimeModel {
  const RuntimeModel({
    required this.provider,
    required this.environment,
    required this.databasePath,
    required this.backupSupported,
  });

  final String provider;        // "Sqlite" | "SqlServer"
  final String environment;
  final String databasePath;
  final bool   backupSupported;

  factory RuntimeModel.fromJson(Map<String, dynamic> json) =>
      RuntimeModel(
        provider:        json['provider'] as String,
        environment:     json['environment'] as String,
        databasePath:    json['databasePath'] as String? ?? '',
        backupSupported: json['backupSupported'] as bool? ?? false,
      );

  bool get isSqlite    => provider == 'Sqlite';
  bool get isSqlServer => provider == 'SqlServer';
}
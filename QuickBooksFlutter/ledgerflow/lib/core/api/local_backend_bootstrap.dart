import 'dart:async';
import 'dart:io';

import '../constants/app_constants.dart';

class LocalBackendBootstrap {
  LocalBackendBootstrap._();

  static Future<void> ensureStarted({
    String baseUrl = AppConstants.defaultBaseUrl,
  }) async {
    if (await _isReady(baseUrl)) return;

    final launch = await _resolveLaunchCommand(baseUrl);
    if (launch == null) {
      throw StateError(
        'LedgerFlow local API was not found. Expected a bundled API executable or the backend project in the workspace.',
      );
    }

    await Process.start(
      launch.executable,
      launch.arguments,
      mode: ProcessStartMode.detached,
      environment: launch.environment,
      workingDirectory: launch.workingDirectory,
    );

    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (DateTime.now().isBefore(deadline)) {
      if (await _isReady(baseUrl)) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    throw StateError('LedgerFlow local API did not become ready in time.');
  }

  static Future<bool> _isReady(String baseUrl) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 1);
    try {
      final uri = Uri.parse('$baseUrl/api/companies/active');
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 2));
      final response = await request.close().timeout(
        const Duration(seconds: 2),
      );
      await response.drain<void>();
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  static Future<_BackendLaunch?> _resolveLaunchCommand(String baseUrl) async {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final bundledExeCandidates = [
      _join(exeDir, 'QuickBooksClone.Api.exe'),
      _join(exeDir, 'api', 'QuickBooksClone.Api.exe'),
      _join(Directory.current.path, 'QuickBooksClone.Api.exe'),
      _join(Directory.current.path, 'api', 'QuickBooksClone.Api.exe'),
    ];

    for (final candidate in bundledExeCandidates) {
      if (await File(candidate).exists()) {
        return _BackendLaunch(
          executable: candidate,
          arguments: const [],
          workingDirectory: File(candidate).parent.path,
          environment: {'ASPNETCORE_URLS': baseUrl},
        );
      }
    }

    final projectCandidates = {
      ..._findBackendProjects(Directory.current),
      ..._findBackendProjects(Directory(exeDir)),
    };

    for (final candidate in projectCandidates) {
      final fullPath = File(candidate).absolute.path;
      if (await File(fullPath).exists()) {
        final builtDll = _builtApiDllForProject(fullPath);
        if (await File(builtDll).exists()) {
          return _BackendLaunch(
            executable: 'dotnet',
            arguments: [builtDll],
            workingDirectory: File(builtDll).parent.path,
            environment: {'ASPNETCORE_URLS': baseUrl},
          );
        }

        return _BackendLaunch(
          executable: 'dotnet',
          arguments: ['run', '--project', fullPath, '--urls', baseUrl],
          workingDirectory: File(fullPath).parent.path,
          environment: {'ASPNETCORE_URLS': baseUrl},
        );
      }
    }

    return null;
  }

  static String _join(
    String first,
    String second, [
    String? third,
    String? fourth,
    String? fifth,
  ]) {
    final parts = [first, second, third, fourth, fifth].whereType<String>();
    return parts.join(Platform.pathSeparator);
  }

  static String _joinAll(List<String> parts) =>
      parts.join(Platform.pathSeparator);

  static Iterable<String> _findBackendProjects(Directory start) sync* {
    var current = start.absolute;
    for (var i = 0; i < 8; i++) {
      yield _joinAll([
        current.path,
        'QuickBooksClone.Api',
        'QuickBooksClone.Api.csproj',
      ]);

      final parent = current.parent;
      if (parent.path == current.path) break;
      current = parent;
    }
  }

  static String _builtApiDllForProject(String projectPath) {
    final projectDir = File(projectPath).parent.path;
    return _joinAll([
      projectDir,
      'bin',
      'Debug',
      'net10.0',
      'QuickBooksClone.Api.dll',
    ]);
  }
}

class _BackendLaunch {
  const _BackendLaunch({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
    required this.environment,
  });

  final String executable;
  final List<String> arguments;
  final String workingDirectory;
  final Map<String, String> environment;
}

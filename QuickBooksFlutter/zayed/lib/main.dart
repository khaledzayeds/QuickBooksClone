import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/api/local_backend_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: StartupGate()));
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<void> _startup;
  bool _slowStartup = false;
  int _startupGeneration = 0;

  @override
  void initState() {
    super.initState();
    _startup = _start();
    _scheduleSlowStartupNotice();
  }

  Future<void> _start() async {
    await LocalBackendBootstrap.ensureStarted();
    ApiClient.instance.init();
  }

  void _retry() {
    setState(() {
      _slowStartup = false;
      _startupGeneration++;
      _startup = _start();
    });
    _scheduleSlowStartupNotice();
  }

  Future<void> _restartService() async {
    await LocalBackendBootstrap.stopRunningService();
    _retry();
  }

  void _scheduleSlowStartupNotice() {
    final generation = _startupGeneration;
    Future<void>.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (generation != _startupGeneration) return;
      setState(() => _slowStartup = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const App();
        }

        if (snapshot.hasError) {
          return _StartupIssueApp(
            message: _startupMessage(snapshot.error),
            onRetry: _retry,
            onRestartService: _restartService,
          );
        }

        return _StartupLoadingApp(slowStartup: _slowStartup);
      },
    );
  }

  String _startupMessage(Object? error) {
    if (error is ZayedServiceMissingException) {
      return 'Zayed service files are missing. Please reinstall Zayed.';
    }
    if (error is ZayedServiceTimeoutException) {
      return 'Zayed service could not start. Please try again or contact support.';
    }
    return 'Zayed service could not start. Please try again or contact support.';
  }
}

class _StartupLoadingApp extends StatelessWidget {
  const _StartupLoadingApp({required this.slowStartup});

  final bool slowStartup;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8F3FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business_center_outlined, size: 46),
              const SizedBox(height: 18),
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 18),
              Text(
                slowStartup ? 'Preparing your workspace...' : 'Starting Zayed',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                slowStartup
                    ? 'This can take a little longer on first launch.'
                    : 'Opening the local company service.',
                style: const TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupIssueApp extends StatelessWidget {
  const _StartupIssueApp({
    required this.message,
    required this.onRetry,
    required this.onRestartService,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onRestartService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8F3FA),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'We could not start Zayed',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onRestartService,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Restart service'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Details for support',
                        style: TextStyle(fontSize: 13),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            message,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

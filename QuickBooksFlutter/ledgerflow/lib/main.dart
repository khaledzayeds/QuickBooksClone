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

  @override
  void initState() {
    super.initState();
    _startup = _start();
  }

  Future<void> _start() async {
    await LocalBackendBootstrap.ensureStarted();
    ApiClient.instance.init();
  }

  void _retry() {
    setState(() {
      _startup = _start();
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
          );
        }

        return const _StartupLoadingApp();
      },
    );
  }

  String _startupMessage(Object? error) {
    final raw = error?.toString().toLowerCase() ?? '';
    if (raw.contains('not found')) {
      return 'LedgerFlow could not find the company service. Reinstall the application or place the service files beside the app, then try again.';
    }
    if (raw.contains('ready in time') || raw.contains('timeout')) {
      return 'The company service is taking longer than expected to start. Wait a moment, then try again.';
    }
    return 'LedgerFlow could not start the company service. Try again or open a different company.';
  }
}

class _StartupLoadingApp extends StatelessWidget {
  const _StartupLoadingApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(height: 16),
              Text('Starting LedgerFlow...'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupIssueApp extends StatelessWidget {
  const _StartupIssueApp({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
                      'Service unavailable',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
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

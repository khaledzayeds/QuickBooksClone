// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/api/local_backend_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalBackendBootstrap.ensureStarted();
  ApiClient.instance.init();

  runApp(const ProviderScope(child: App()));
}

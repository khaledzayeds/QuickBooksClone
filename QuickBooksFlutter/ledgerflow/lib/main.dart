// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/api/api_bootstrap.dart';
import 'core/api/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialBaseUrl = await ApiBootstrap.loadInitialBaseUrl();
  ApiClient.instance.init(baseUrl: initialBaseUrl);

  runApp(const ProviderScope(child: App()));
}

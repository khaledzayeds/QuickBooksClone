// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/api/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ApiClient.instance.init();
  

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
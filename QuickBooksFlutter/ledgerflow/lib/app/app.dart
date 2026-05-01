// app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ledgerflow/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/locale_provider.dart';
import 'router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final router        = ref.watch(routerProvider); // ← Riverpod-aware router with auth redirect

    return MaterialApp.router(
      title: 'LedgerFlow',
      debugShowCheckedModeBanner: false,

      // ── Localization ──────────────────────────────
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: currentLocale,

      // ─── Theme ─────────────────────────────────────
      theme:     AppTheme.lightTheme(currentLocale.languageCode),
      darkTheme: AppTheme.darkTheme(currentLocale.languageCode),
      themeMode: ThemeMode.system,

      // ── Router (with auth guard) ──────────────────
      routerConfig: router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ar', 'EG'));

  void setLocale(Locale locale) {
    state = locale;
  }

  void toggleLocale() {
    if (state.languageCode == 'ar') {
      state = const Locale('en', 'US');
    } else {
      state = const Locale('ar', 'EG');
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

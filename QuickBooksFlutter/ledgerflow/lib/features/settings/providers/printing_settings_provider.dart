import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/printing_settings_model.dart';
import '../data/printing_settings_repository.dart';

final printingSettingsRepositoryProvider = Provider<PrintingSettingsRepository>((ref) => PrintingSettingsRepository());

class PrintingSettingsState {
  const PrintingSettingsState({
    required this.settings,
    this.loading = false,
    this.saving = false,
    this.saved = false,
    this.errorMessage,
  });

  final PrintingSettingsModel settings;
  final bool loading;
  final bool saving;
  final bool saved;
  final String? errorMessage;

  PrintingSettingsState copyWith({
    PrintingSettingsModel? settings,
    bool? loading,
    bool? saving,
    bool? saved,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PrintingSettingsState(
      settings: settings ?? this.settings,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PrintingSettingsNotifier extends Notifier<PrintingSettingsState> {
  late final PrintingSettingsRepository _repository;

  @override
  PrintingSettingsState build() {
    _repository = ref.watch(printingSettingsRepositoryProvider);
    Future.microtask(load);
    return PrintingSettingsState(settings: PrintingSettingsModel.defaults(), loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true, saved: false);
    try {
      final settings = await _repository.load();
      state = state.copyWith(settings: settings, loading: false, clearError: true);
    } catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.toString());
    }
  }

  void update(PrintingSettingsModel Function(PrintingSettingsModel current) change) {
    state = state.copyWith(settings: change(state.settings), saved: false, clearError: true);
  }

  Future<void> save() async {
    state = state.copyWith(saving: true, saved: false, clearError: true);
    try {
      final saved = await _repository.save(state.settings);
      state = state.copyWith(settings: saved, saving: false, saved: true, clearError: true);
    } catch (error) {
      state = state.copyWith(saving: false, saved: false, errorMessage: error.toString());
    }
  }

  Future<void> reset() async {
    state = state.copyWith(saving: true, saved: false, clearError: true);
    try {
      final settings = await _repository.reset();
      state = state.copyWith(settings: settings, saving: false, saved: true, clearError: true);
    } catch (error) {
      state = state.copyWith(saving: false, saved: false, errorMessage: error.toString());
    }
  }
}

final printingSettingsProvider = NotifierProvider<PrintingSettingsNotifier, PrintingSettingsState>(
  PrintingSettingsNotifier.new,
);

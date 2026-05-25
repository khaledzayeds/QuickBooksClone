import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/settings_models.dart';
import 'settings_provider.dart';

class CompanySettingsFormState {
  const CompanySettingsFormState({
    required this.form,
    this.loading = false,
    this.saving = false,
    this.errorMessage,
    this.saved = false,
  });

  final CompanySettingsModel form;
  final bool loading;
  final bool saving;
  final String? errorMessage;
  final bool saved;

  CompanySettingsFormState copyWith({
    CompanySettingsModel? form,
    bool? loading,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
    bool? saved,
  }) {
    return CompanySettingsFormState(
      form: form ?? this.form,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      saved: saved ?? this.saved,
    );
  }
}

class CompanySettingsFormNotifier extends Notifier<CompanySettingsFormState> {
  @override
  CompanySettingsFormState build() {
    Future.microtask(load);
    return CompanySettingsFormState(form: CompanySettingsModel.empty(), loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true, saved: false);
    try {
      final company = await ref.read(settingsRepositoryProvider).getCompany();
      state = state.copyWith(form: company ?? CompanySettingsModel.empty(), loading: false, clearError: true);
    } catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.toString());
    }
  }

  void update(CompanySettingsModel Function(CompanySettingsModel current) change) {
    state = state.copyWith(form: change(state.form), clearError: true, saved: false);
  }

  Future<void> save() async {
    if (state.form.companyName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Company name is required.', saved: false);
      return;
    }

    state = state.copyWith(saving: true, clearError: true, saved: false);
    try {
      final saved = await ref.read(settingsRepositoryProvider).updateCompany(state.form);
      ref.invalidate(companySettingsProvider);
      ref.invalidate(runtimeSettingsProvider);
      state = state.copyWith(form: saved, saving: false, clearError: true, saved: true);
    } catch (error) {
      state = state.copyWith(saving: false, errorMessage: error.toString(), saved: false);
    }
  }
}

final companySettingsFormProvider = NotifierProvider<CompanySettingsFormNotifier, CompanySettingsFormState>(
  CompanySettingsFormNotifier.new,
);

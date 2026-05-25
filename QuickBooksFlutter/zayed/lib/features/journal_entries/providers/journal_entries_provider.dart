// journal_entries_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../data/datasources/journal_entries_remote_datasource.dart';
import '../data/models/journal_entry_model.dart';
import '../data/repositories/journal_entries_repository.dart';

final journalEntriesDatasourceProvider = Provider<JournalEntriesRemoteDatasource>(
  (ref) => JournalEntriesRemoteDatasource(ApiClient.instance),
);

final journalEntriesRepositoryProvider = Provider<JournalEntriesRepository>(
  (ref) => JournalEntriesRepository(ref.watch(journalEntriesDatasourceProvider)),
);

final journalEntriesProvider = AsyncNotifierProvider<JournalEntriesNotifier, List<JournalEntryModel>>(
  JournalEntriesNotifier.new,
);

class JournalEntriesNotifier extends AsyncNotifier<List<JournalEntryModel>> {
  String _search = '';
  bool _includeVoid = false;

  @override
  Future<List<JournalEntryModel>> build() => _fetch();

  Future<List<JournalEntryModel>> _fetch() async {
    final result = await ref.read(journalEntriesRepositoryProvider).getAll(
          search: _search,
          includeVoid: _includeVoid,
        );
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  void setIncludeVoid(bool value) {
    _includeVoid = value;
    refresh();
  }

  Future<ApiResult<JournalEntryModel>> create(CreateJournalEntryDto dto) async {
    final result = await ref.read(journalEntriesRepositoryProvider).create(dto);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<JournalEntryModel>> post(String id) async {
    final result = await ref.read(journalEntriesRepositoryProvider).post(id);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<JournalEntryModel>> voidEntry(String id) async {
    final result = await ref.read(journalEntriesRepositoryProvider).voidEntry(id);
    if (result.isSuccess) refresh();
    return result;
  }
}

final journalEntryDetailsProvider = FutureProvider.family<JournalEntryModel, String>((ref, id) async {
  final result = await ref.read(journalEntriesRepositoryProvider).getById(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});

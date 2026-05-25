// journal_entries_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/journal_entries_remote_datasource.dart';
import '../models/journal_entry_model.dart';

class JournalEntriesRepository {
  JournalEntriesRepository(this._datasource);

  final JournalEntriesRemoteDatasource _datasource;

  Future<ApiResult<List<JournalEntryModel>>> getAll({
    String? search,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) =>
      _datasource.getAll(
        search: search,
        includeVoid: includeVoid,
        page: page,
        pageSize: pageSize,
      );

  Future<ApiResult<JournalEntryModel>> getById(String id) => _datasource.getById(id);

  Future<ApiResult<JournalEntryModel>> create(CreateJournalEntryDto dto) => _datasource.create(dto);

  Future<ApiResult<JournalEntryModel>> post(String id) => _datasource.post(id);

  Future<ApiResult<JournalEntryModel>> voidEntry(String id) => _datasource.voidEntry(id);
}

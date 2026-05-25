// journal_entries_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/journal_entry_model.dart';

class JournalEntriesRemoteDatasource {
  JournalEntriesRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApiResult<List<JournalEntryModel>>> getAll({
    String? search,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/journal-entries',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'includeVoid': includeVoid,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final entries = ((response.data?['items'] as List?) ?? const [])
          .map((json) => JournalEntryModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(entries);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<JournalEntryModel>> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/journal-entries/$id');
      return Success(JournalEntryModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<JournalEntryModel>> create(CreateJournalEntryDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/journal-entries',
        data: dto.toJson(),
      );
      return Success(JournalEntryModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<JournalEntryModel>> post(String id) async {
    try {
      final response = await _client.post<Map<String, dynamic>>('/api/journal-entries/$id/post');
      return Success(JournalEntryModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<JournalEntryModel>> voidEntry(String id) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>('/api/journal-entries/$id/void');
      return Success(JournalEntryModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}

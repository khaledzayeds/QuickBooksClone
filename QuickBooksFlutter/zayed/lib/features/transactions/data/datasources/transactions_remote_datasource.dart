// transactions_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/transaction_model.dart';

class TransactionsRemoteDatasource {
  TransactionsRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApiResult<List<TransactionModel>>> getAll({
    String? search,
    String? sourceEntityType,
    String? sourceEntityId,
    bool includeVoided = false,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/transactions',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (sourceEntityType != null && sourceEntityType.isNotEmpty)
            'sourceEntityType': sourceEntityType,
          if (sourceEntityId != null && sourceEntityId.isNotEmpty)
            'sourceEntityId': sourceEntityId,
          'includeVoided': includeVoided,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final items = ((response.data?['items'] as List?) ?? const [])
          .map(
            (json) => TransactionModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      return Success(items);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<TransactionModel>> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/transactions/$id',
      );
      return Success(TransactionModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}

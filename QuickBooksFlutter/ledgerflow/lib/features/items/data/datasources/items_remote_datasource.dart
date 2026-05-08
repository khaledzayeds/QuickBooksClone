// items_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/item_model.dart';

class ItemsRemoteDatasource {
  ItemsRemoteDatasource(this._client);
  final ApiClient _client;

  Future<ApiResult<List<ItemModel>>> getItems({
    String? search,
    int? itemType,
    bool includeInactive = false,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/items',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'itemType': ?itemType,
          'includeInactive': includeInactive,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final items = (response.data?['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ItemModel.fromJson)
          .toList();
      return Success(items);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<ItemModel>> getItem(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/items/$id');
      return Success(ItemModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<ItemModel>> createItem(Map<String, dynamic> body) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/items',
        data: body,
      );
      return Success(ItemModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<ItemModel>> updateItem(String id, Map<String, dynamic> body) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/api/items/$id',
        data: body,
      );
      return Success(ItemModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<ItemModel>> toggleActive(String id, bool isActive) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/api/items/$id/active',
        data: {'isActive': isActive},
      );
      return Success(ItemModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}
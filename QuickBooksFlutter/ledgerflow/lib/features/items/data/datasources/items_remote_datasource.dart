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
          if (itemType != null) 'itemType': itemType,
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

  /// Bulk price change. Returns number of updated items.
  Future<ApiResult<int>> bulkPriceChange({
    required List<String> itemIds,
    required int target,   // 1=Sales 2=Purchase 3=Both
    required int mode,     // 1=SetFixed 2=+Amount 3=+% 4=-Amount 5=-%
    required double value,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/items/bulk-price-change',
        data: {
          'itemIds': itemIds,
          'target': target,
          'mode': mode,
          'value': value,
        },
      );
      final updated = (response.data?['updatedCount'] as num?)?.toInt() ?? 0;
      return Success(updated);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  /// Export items as CSV string built client-side.
  Future<ApiResult<String>> exportCsv() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/items',
        queryParameters: {'includeInactive': true, 'page': 1, 'pageSize': 10000},
      );
      final rows = (response.data?['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      final buf = StringBuffer();
      buf.writeln('Name,Type,SKU,Barcode,Unit,Sales Price,Purchase Cost,Qty on Hand,Active');
      for (final r in rows) {
        String esc(dynamic v) {
          final s = v?.toString() ?? '';
          return s.contains(',') || s.contains('"') ? '"${s.replaceAll('"', '""')}"' : s;
        }
        buf.writeln([
          esc(r['name']), esc(r['itemType']), esc(r['sku']), esc(r['barcode']),
          esc(r['unit']), esc(r['salesPrice']), esc(r['purchasePrice']),
          esc(r['quantityOnHand']), r['isActive'] == true ? 'Yes' : 'No',
        ].join(','));
      }
      return Success(buf.toString());
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }


  /// Export items as JSON list (for Excel generation on client side).
  Future<ApiResult<List<Map<String, dynamic>>>> exportItemsJson() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/items',
        queryParameters: {'includeInactive': true, 'page': 1, 'pageSize': 10000},
      );
      final items = (response.data?['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      return Success(items);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}
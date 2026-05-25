// printing_api.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/print_data_contracts.dart';

class PrintingApi {
  PrintingApi(this._client);

  final ApiClient _client;

  Future<ApiResult<DocumentPrintDataModel>> getDocumentPrintData({
    required String documentType,
    required String documentId,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/printing/documents/$documentType/$documentId/data',
      );
      return Success(DocumentPrintDataModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}

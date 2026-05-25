// printing_repo.dart

import '../../../../core/api/api_result.dart';
import '../datasources/printing_api.dart';
import '../models/print_data_contracts.dart';

class PrintingRepo {
  PrintingRepo(this._api);

  final PrintingApi _api;

  Future<ApiResult<DocumentPrintDataModel>> getDocumentPrintData({
    required String documentType,
    required String documentId,
  }) =>
      _api.getDocumentPrintData(
        documentType: documentType,
        documentId: documentId,
      );
}

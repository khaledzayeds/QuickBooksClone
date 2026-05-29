// printing_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../settings/data/models/printing_settings_model.dart';
import '../data/datasources/printing_api.dart';
import '../data/models/print_data_contracts.dart';
import '../data/repositories/printing_repo.dart';
import '../../companies/providers/company_registry_provider.dart';

final printingApiProvider = Provider<PrintingApi>(
  (ref) => PrintingApi(ApiClient.instance),
);

final printingRepoProvider = Provider<PrintingRepo>(
  (ref) => PrintingRepo(ref.watch(printingApiProvider)),
);

final documentPrintDataProvider =
    FutureProvider.family<DocumentPrintDataModel, DocumentPrintDataRequest>((
      ref,
      request,
    ) async {
      final activeCompanyScope = ref.watch(activeCompanyScopeProvider);
      if (activeCompanyScope == null) {
        throw StateError('No active company selected.');
      }
      final result = await ref
          .read(printingRepoProvider)
          .getDocumentPrintData(
            documentType: request.documentType,
            documentId: request.documentId,
          );
      return result.when(
        success: (data) => data,
        failure: (error) => throw error,
      );
    });

class DocumentPrintDataRequest {
  DocumentPrintDataRequest({
    required String documentType,
    required this.documentId,
  }) : documentType = normalizePrintDocumentType(documentType);

  final String documentType;
  final String documentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentPrintDataRequest &&
          runtimeType == other.runtimeType &&
          documentType == other.documentType &&
          documentId == other.documentId;

  @override
  int get hashCode => Object.hash(documentType, documentId);
}

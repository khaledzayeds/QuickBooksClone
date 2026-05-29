// sales_receipts_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../companies/providers/company_registry_provider.dart';
import '../data/datasources/sales_receipts_remote_datasource.dart';
import '../data/models/sales_receipt_models.dart';
import '../data/repositories/sales_receipts_repository.dart';

final salesReceiptsDatasourceProvider = Provider<SalesReceiptsRemoteDatasource>(
  (ref) => SalesReceiptsRemoteDatasource(ApiClient.instance),
);

final salesReceiptsRepositoryProvider = Provider<SalesReceiptsRepository>(
  (ref) => SalesReceiptsRepository(ref.watch(salesReceiptsDatasourceProvider)),
);

final salesReceiptsProvider =
    AsyncNotifierProvider<SalesReceiptsNotifier, List<SalesReceiptModel>>(
      SalesReceiptsNotifier.new,
    );

class SalesReceiptsNotifier extends AsyncNotifier<List<SalesReceiptModel>> {
  @override
  Future<List<SalesReceiptModel>> build() {
    final activeCompanyScope = ref.watch(activeCompanyScopeProvider);
    if (activeCompanyScope == null) return Future.value(const []);
    return _fetch();
  }

  Future<List<SalesReceiptModel>> _fetch() async {
    final result = await ref.read(salesReceiptsRepositoryProvider).getAll();
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final salesReceiptDetailsProvider =
    FutureProvider.family<SalesReceiptModel, String>((ref, id) async {
      final activeCompanyScope = ref.watch(activeCompanyScopeProvider);
      if (activeCompanyScope == null) {
        throw StateError('No active company selected.');
      }
      final result = await ref
          .read(salesReceiptsRepositoryProvider)
          .getById(id);
      return result.when(
        success: (data) => data,
        failure: (error) => throw error,
      );
    });

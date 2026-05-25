// sales_receipts_state.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/datasources/sales_receipts_api.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../data/repositories/sales_receipts_repo.dart';

final salesReceiptsApiProvider = Provider<SalesReceiptsApi>(
  (ref) => SalesReceiptsApi(ApiClient.instance),
);

final salesReceiptsRepoProvider = Provider<SalesReceiptsRepo>(
  (ref) => SalesReceiptsRepo(ref.watch(salesReceiptsApiProvider)),
);

final salesReceiptsStateProvider =
    AsyncNotifierProvider<SalesReceiptsState, List<SalesReceiptModel>>(
  SalesReceiptsState.new,
);

class SalesReceiptsState extends AsyncNotifier<List<SalesReceiptModel>> {
  @override
  Future<List<SalesReceiptModel>> build() => _fetch();

  Future<List<SalesReceiptModel>> _fetch() async {
    final result = await ref.read(salesReceiptsRepoProvider).getAll();
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

final salesReceiptDetailsStateProvider =
    FutureProvider.family<SalesReceiptModel, String>((ref, id) async {
  final result = await ref.read(salesReceiptsRepoProvider).getById(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});

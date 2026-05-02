// purchase_bills_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../data/datasources/purchase_bills_remote_datasource.dart';
import '../data/repositories/purchase_bills_repository.dart';
import '../data/models/purchase_bill_model.dart';

final purchaseBillsDatasourceProvider = Provider<PurchaseBillsRemoteDatasource>(
  (ref) => PurchaseBillsRemoteDatasource(ApiClient.instance),
);

final purchaseBillsRepositoryProvider = Provider<PurchaseBillsRepository>(
  (ref) => PurchaseBillsRepository(ref.watch(purchaseBillsDatasourceProvider)),
);

final purchaseBillsProvider =
    AsyncNotifierProvider<PurchaseBillsNotifier, List<PurchaseBillModel>>(
  PurchaseBillsNotifier.new,
);

class PurchaseBillsNotifier extends AsyncNotifier<List<PurchaseBillModel>> {
  String? _search;
  String? _vendorId;
  bool _includeVoid = false;

  @override
  Future<List<PurchaseBillModel>> build() => _fetch();

  Future<List<PurchaseBillModel>> _fetch() async {
    final result = await ref.read(purchaseBillsRepositoryProvider).getBills(
          search: _search,
          vendorId: _vendorId,
          includeVoid: _includeVoid,
        );
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void filter({String? search, String? vendorId, bool? includeVoid}) {
    if (search != null) _search = search;
    if (vendorId != null) _vendorId = vendorId;
    if (includeVoid != null) _includeVoid = includeVoid;
    refresh();
  }
}

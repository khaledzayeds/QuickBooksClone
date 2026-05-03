// sales_returns_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../data/datasources/sales_returns_remote_datasource.dart';
import '../data/models/sales_return_model.dart';
import '../data/repositories/sales_returns_repository.dart';

final salesReturnsDatasourceProvider = Provider<SalesReturnsRemoteDatasource>(
  (ref) => SalesReturnsRemoteDatasource(ApiClient.instance),
);

final salesReturnsRepositoryProvider = Provider<SalesReturnsRepository>(
  (ref) => SalesReturnsRepository(ref.watch(salesReturnsDatasourceProvider)),
);

final salesReturnsProvider = AsyncNotifierProvider<SalesReturnsNotifier, List<SalesReturnModel>>(
  SalesReturnsNotifier.new,
);

class SalesReturnsNotifier extends AsyncNotifier<List<SalesReturnModel>> {
  String _search = '';
  String? _invoiceId;
  String? _customerId;
  bool _includeVoid = false;

  @override
  Future<List<SalesReturnModel>> build() => _fetch();

  Future<List<SalesReturnModel>> _fetch() async {
    final result = await ref.read(salesReturnsRepositoryProvider).getAll(
          search: _search,
          invoiceId: _invoiceId,
          customerId: _customerId,
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

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  void setInvoice(String? value) {
    _invoiceId = value;
    refresh();
  }

  void setCustomer(String? value) {
    _customerId = value;
    refresh();
  }

  void setIncludeVoid(bool value) {
    _includeVoid = value;
    refresh();
  }

  Future<ApiResult<SalesReturnModel>> create(CreateSalesReturnDto dto) async {
    final result = await ref.read(salesReturnsRepositoryProvider).create(dto);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<SalesReturnModel>> post(String id) async {
    final result = await ref.read(salesReturnsRepositoryProvider).post(id);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<SalesReturnModel>> voidReturn(String id) async {
    final result = await ref.read(salesReturnsRepositoryProvider).voidReturn(id);
    if (result.isSuccess) refresh();
    return result;
  }
}

final salesReturnDetailsProvider = FutureProvider.family<SalesReturnModel, String>((ref, id) async {
  final result = await ref.read(salesReturnsRepositoryProvider).getById(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});

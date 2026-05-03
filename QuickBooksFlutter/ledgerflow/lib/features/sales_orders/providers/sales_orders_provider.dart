// sales_orders_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../data/datasources/sales_orders_remote_datasource.dart';
import '../data/models/sales_order_model.dart';
import '../data/repositories/sales_orders_repository.dart';

final salesOrdersDatasourceProvider = Provider<SalesOrdersRemoteDatasource>(
  (ref) => SalesOrdersRemoteDatasource(ApiClient.instance),
);

final salesOrdersRepositoryProvider = Provider<SalesOrdersRepository>(
  (ref) => SalesOrdersRepository(ref.watch(salesOrdersDatasourceProvider)),
);

final salesOrdersProvider = AsyncNotifierProvider<SalesOrdersNotifier, List<SalesOrderModel>>(
  SalesOrdersNotifier.new,
);

class SalesOrdersNotifier extends AsyncNotifier<List<SalesOrderModel>> {
  String _search = '';
  String? _customerId;
  bool _includeClosed = false;
  bool _includeCancelled = false;

  @override
  Future<List<SalesOrderModel>> build() => _fetch();

  Future<List<SalesOrderModel>> _fetch() async {
    final result = await ref.read(salesOrdersRepositoryProvider).getAll(
          search: _search,
          customerId: _customerId,
          includeClosed: _includeClosed,
          includeCancelled: _includeCancelled,
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

  void setCustomer(String? value) {
    _customerId = value;
    refresh();
  }

  void setIncludeClosed(bool value) {
    _includeClosed = value;
    refresh();
  }

  void setIncludeCancelled(bool value) {
    _includeCancelled = value;
    refresh();
  }

  Future<ApiResult<SalesOrderModel>> create(CreateSalesOrderDto dto) async {
    final result = await ref.read(salesOrdersRepositoryProvider).create(dto);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<SalesOrderModel>> open(String id) => _action(() => ref.read(salesOrdersRepositoryProvider).open(id));
  Future<ApiResult<SalesOrderModel>> close(String id) => _action(() => ref.read(salesOrdersRepositoryProvider).close(id));
  Future<ApiResult<SalesOrderModel>> cancel(String id) => _action(() => ref.read(salesOrdersRepositoryProvider).cancel(id));

  Future<ApiResult<SalesOrderModel>> _action(Future<ApiResult<SalesOrderModel>> Function() call) async {
    final result = await call();
    if (result.isSuccess) refresh();
    return result;
  }
}

final salesOrderDetailsProvider = FutureProvider.family<SalesOrderModel, String>((ref, id) async {
  final result = await ref.read(salesOrdersRepositoryProvider).getById(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});

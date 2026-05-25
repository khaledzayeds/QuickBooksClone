// customers_provider.dart
// customers_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../data/datasources/customers_remote_datasource.dart';
import '../data/models/customer_model.dart';
import '../data/repositories/customers_repository.dart';

// ─── Dependencies ─────────────────────────────────
final customersDatasourceProvider = Provider<CustomersRemoteDatasource>(
  (ref) => CustomersRemoteDatasource(ApiClient.instance),
);

final customersRepositoryProvider = Provider<CustomersRepository>(
  (ref) => CustomersRepository(ref.watch(customersDatasourceProvider)),
);

// ─── List Provider ────────────────────────────────
final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<CustomerModel>>(
  CustomersNotifier.new,
);

class CustomersNotifier extends AsyncNotifier<List<CustomerModel>> {
  String _search = '';
  bool _includeInactive = false;
  int _page = 1;

  @override
  Future<List<CustomerModel>> build() => _fetch();

  Future<List<CustomerModel>> _fetch() async {
    final result = await ref
        .read(customersRepositoryProvider)
        .getCustomers(
          search: _search,
          includeInactive: _includeInactive,
          page: _page,
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
    _page = 1;
    refresh();
  }

  void setIncludeInactive(bool value) {
    _includeInactive = value;
    refresh();
  }

  Future<ApiResult<CustomerModel>> createCustomer(
      Map<String, dynamic> body) async {
    final result =
        await ref.read(customersRepositoryProvider).createCustomer(body);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<CustomerModel>> updateCustomer(
      String id, Map<String, dynamic> body) async {
    final result = await ref
        .read(customersRepositoryProvider)
        .updateCustomer(id, body);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<CustomerModel>> toggleActive(
      String id, bool isActive) async {
    final result = await ref
        .read(customersRepositoryProvider)
        .toggleActive(id, isActive);
    if (result.isSuccess) refresh();
    return result;
  }
}

// ─── Single Customer ──────────────────────────────
final customerDetailProvider =
    FutureProvider.family<CustomerModel, String>((ref, id) async {
  final result =
      await ref.read(customersRepositoryProvider).getCustomer(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});
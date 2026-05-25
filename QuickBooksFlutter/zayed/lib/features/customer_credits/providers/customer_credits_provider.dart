// customer_credits_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../data/datasources/customer_credits_remote_datasource.dart';
import '../data/models/customer_credit_model.dart';
import '../data/repositories/customer_credits_repository.dart';

final customerCreditsDatasourceProvider = Provider<CustomerCreditsRemoteDatasource>(
  (ref) => CustomerCreditsRemoteDatasource(ApiClient.instance),
);

final customerCreditsRepositoryProvider = Provider<CustomerCreditsRepository>(
  (ref) => CustomerCreditsRepository(ref.watch(customerCreditsDatasourceProvider)),
);

final customerCreditsProvider = AsyncNotifierProvider<CustomerCreditsNotifier, List<CustomerCreditModel>>(
  CustomerCreditsNotifier.new,
);

class CustomerCreditsNotifier extends AsyncNotifier<List<CustomerCreditModel>> {
  String _search = '';
  String? _customerId;
  int? _action;
  bool _includeVoid = false;

  @override
  Future<List<CustomerCreditModel>> build() => _fetch();

  Future<List<CustomerCreditModel>> _fetch() async {
    final result = await ref.read(customerCreditsRepositoryProvider).getAll(
          search: _search,
          customerId: _customerId,
          action: _action,
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

  void setCustomer(String? value) {
    _customerId = value;
    refresh();
  }

  void setAction(int? value) {
    _action = value;
    refresh();
  }

  void setIncludeVoid(bool value) {
    _includeVoid = value;
    refresh();
  }

  Future<ApiResult<CustomerCreditModel>> create(CreateCustomerCreditDto dto) async {
    final result = await ref.read(customerCreditsRepositoryProvider).create(dto);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<CustomerCreditModel>> post(String id) async {
    final result = await ref.read(customerCreditsRepositoryProvider).post(id);
    if (result.isSuccess) refresh();
    return result;
  }
}

final customerCreditDetailsProvider = FutureProvider.family<CustomerCreditModel, String>((ref, id) async {
  final result = await ref.read(customerCreditsRepositoryProvider).getById(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});

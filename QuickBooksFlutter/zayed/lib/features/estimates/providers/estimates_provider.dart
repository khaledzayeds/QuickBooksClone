// estimates_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../data/datasources/estimates_remote_datasource.dart';
import '../data/models/estimate_model.dart';
import '../data/repositories/estimates_repository.dart';

final estimatesDatasourceProvider = Provider<EstimatesRemoteDatasource>(
  (ref) => EstimatesRemoteDatasource(ApiClient.instance),
);

final estimatesRepositoryProvider = Provider<EstimatesRepository>(
  (ref) => EstimatesRepository(ref.watch(estimatesDatasourceProvider)),
);

final estimatesProvider =
    AsyncNotifierProvider<EstimatesNotifier, List<EstimateModel>>(
      EstimatesNotifier.new,
    );

class EstimatesNotifier extends AsyncNotifier<List<EstimateModel>> {
  String _search = '';
  String? _customerId;
  bool _includeClosed = false;
  bool _includeCancelled = false;

  @override
  Future<List<EstimateModel>> build() => _fetch();

  Future<List<EstimateModel>> _fetch() async {
    final result = await ref
        .read(estimatesRepositoryProvider)
        .getAll(
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

  Future<ApiResult<EstimateModel>> create(CreateEstimateDto dto) async {
    final result = await ref.read(estimatesRepositoryProvider).create(dto);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<EstimateModel>> send(String id) =>
      _action(() => ref.read(estimatesRepositoryProvider).send(id));
  Future<ApiResult<EstimateModel>> accept(String id) =>
      _action(() => ref.read(estimatesRepositoryProvider).accept(id));
  Future<ApiResult<EstimateModel>> decline(String id) =>
      _action(() => ref.read(estimatesRepositoryProvider).decline(id));
  Future<ApiResult<EstimateModel>> cancel(String id) =>
      _action(() => ref.read(estimatesRepositoryProvider).cancel(id));

  Future<ApiResult<void>> convertToSalesOrder(String id) async {
    final result = await ref
        .read(estimatesRepositoryProvider)
        .convertToSalesOrder(id);
    if (result.isSuccess) refresh();
    return result.when(
      success: (_) => const Success(null),
      failure: (error) => Failure(error),
    );
  }

  Future<ApiResult<EstimateModel>> _action(
    Future<ApiResult<EstimateModel>> Function() call,
  ) async {
    final result = await call();
    if (result.isSuccess) refresh();
    return result;
  }
}

final estimateDetailsProvider = FutureProvider.family<EstimateModel, String>((
  ref,
  id,
) async {
  final result = await ref.read(estimatesRepositoryProvider).getById(id);
  return result.when(success: (data) => data, failure: (error) => throw error);
});

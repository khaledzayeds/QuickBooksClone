// vendor_credits_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../data/datasources/vendor_credits_remote_datasource.dart';
import '../data/models/vendor_credit_model.dart';
import '../data/repositories/vendor_credits_repository.dart';

final vendorCreditsDatasourceProvider = Provider<VendorCreditsRemoteDatasource>(
  (ref) => VendorCreditsRemoteDatasource(ApiClient.instance),
);

final vendorCreditsRepositoryProvider = Provider<VendorCreditsRepository>(
  (ref) => VendorCreditsRepository(ref.watch(vendorCreditsDatasourceProvider)),
);

final vendorCreditsProvider = AsyncNotifierProvider<VendorCreditsNotifier, List<VendorCreditModel>>(
  VendorCreditsNotifier.new,
);

class VendorCreditsNotifier extends AsyncNotifier<List<VendorCreditModel>> {
  String _search = '';
  String? _vendorId;
  int? _action;
  bool _includeVoid = false;

  @override
  Future<List<VendorCreditModel>> build() => _fetch();

  Future<List<VendorCreditModel>> _fetch() async {
    final result = await ref.read(vendorCreditsRepositoryProvider).getAll(
          search: _search,
          vendorId: _vendorId,
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

  void setVendor(String? value) {
    _vendorId = value;
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

  Future<ApiResult<VendorCreditModel>> create(CreateVendorCreditDto dto) async {
    final result = await ref.read(vendorCreditsRepositoryProvider).create(dto);
    if (result.isSuccess) refresh();
    return result;
  }
}

final vendorCreditDetailsProvider = FutureProvider.family<VendorCreditModel, String>((ref, id) async {
  final result = await ref.read(vendorCreditsRepositoryProvider).getById(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});

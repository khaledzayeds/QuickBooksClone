// vendors_provider.dart
// vendors_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../data/datasources/vendors_remote_datasource.dart';
import '../data/models/vendor_model.dart';
import '../data/repositories/vendors_repository.dart';

final vendorsDatasourceProvider = Provider<VendorsRemoteDatasource>(
  (ref) => VendorsRemoteDatasource(ApiClient.instance),
);

final vendorsRepositoryProvider = Provider<VendorsRepository>(
  (ref) => VendorsRepository(ref.watch(vendorsDatasourceProvider)),
);

final vendorsProvider =
    AsyncNotifierProvider<VendorsNotifier, List<VendorModel>>(
  VendorsNotifier.new,
);

class VendorsNotifier extends AsyncNotifier<List<VendorModel>> {
  String _search          = '';
  bool   _includeInactive = false;
  int    _page            = 1;

  @override
  Future<List<VendorModel>> build() => _fetch();

  Future<List<VendorModel>> _fetch() async {
    final result = await ref.read(vendorsRepositoryProvider).getVendors(
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
    _page   = 1;
    refresh();
  }

  void setIncludeInactive(bool value) {
    _includeInactive = value;
    refresh();
  }

  Future<ApiResult<VendorModel>> createVendor(
      Map<String, dynamic> body) async {
    final result =
        await ref.read(vendorsRepositoryProvider).createVendor(body);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<VendorModel>> updateVendor(
      String id, Map<String, dynamic> body) async {
    final result =
        await ref.read(vendorsRepositoryProvider).updateVendor(id, body);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<VendorModel>> toggleActive(
      String id, bool isActive) async {
    final result =
        await ref.read(vendorsRepositoryProvider).toggleActive(id, isActive);
    if (result.isSuccess) refresh();
    return result;
  }
}

final vendorDetailProvider =
    FutureProvider.family<VendorModel, String>((ref, id) async {
  final result =
      await ref.read(vendorsRepositoryProvider).getVendor(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});
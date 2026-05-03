// payments_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../data/datasources/payments_remote_datasource.dart';
import '../data/models/payment_model.dart';
import '../data/repositories/payments_repository.dart';

final paymentsDatasourceProvider = Provider<PaymentsRemoteDatasource>(
  (ref) => PaymentsRemoteDatasource(ApiClient.instance),
);

final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => PaymentsRepository(ref.watch(paymentsDatasourceProvider)),
);

final paymentsProvider = AsyncNotifierProvider<PaymentsNotifier, List<PaymentModel>>(
  PaymentsNotifier.new,
);

class PaymentsNotifier extends AsyncNotifier<List<PaymentModel>> {
  String _search = '';
  String? _customerId;
  String? _invoiceId;
  bool _includeVoid = false;

  @override
  Future<List<PaymentModel>> build() => _fetch();

  Future<List<PaymentModel>> _fetch() async {
    final result = await ref.read(paymentsRepositoryProvider).getAll(
          search: _search,
          customerId: _customerId,
          invoiceId: _invoiceId,
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

  void setInvoice(String? value) {
    _invoiceId = value;
    refresh();
  }

  void setIncludeVoid(bool value) {
    _includeVoid = value;
    refresh();
  }

  Future<ApiResult<PaymentModel>> create(CreatePaymentDto dto) async {
    final result = await ref.read(paymentsRepositoryProvider).create(dto);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<PaymentModel>> voidPayment(String id) async {
    final result = await ref.read(paymentsRepositoryProvider).voidPayment(id);
    if (result.isSuccess) refresh();
    return result;
  }
}

final paymentDetailsProvider = FutureProvider.family<PaymentModel, String>((ref, id) async {
  final result = await ref.read(paymentsRepositoryProvider).getById(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});

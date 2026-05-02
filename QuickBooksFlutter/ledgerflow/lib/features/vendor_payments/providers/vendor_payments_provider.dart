// vendor_payments_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../data/datasources/vendor_payments_remote_datasource.dart';
import '../data/models/create_vendor_payment_dto.dart';
import '../data/models/vendor_payment_model.dart';
import '../data/repositories/vendor_payments_repository.dart';

final vendorPaymentsDatasourceProvider = Provider<VendorPaymentsRemoteDatasource>(
  (ref) => VendorPaymentsRemoteDatasource(ApiClient.instance),
);

final vendorPaymentsRepositoryProvider = Provider<VendorPaymentsRepository>(
  (ref) => VendorPaymentsRepository(ref.watch(vendorPaymentsDatasourceProvider)),
);

final vendorPaymentsProvider =
    AsyncNotifierProvider<VendorPaymentsNotifier, List<VendorPaymentModel>>(
  VendorPaymentsNotifier.new,
);

class VendorPaymentsNotifier extends AsyncNotifier<List<VendorPaymentModel>> {
  @override
  Future<List<VendorPaymentModel>> build() => _fetch();

  Future<List<VendorPaymentModel>> _fetch() async {
    final result = await ref.read(vendorPaymentsRepositoryProvider).getPayments();
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Batch payment logic: loops through selected bills and creates payments sequentially.
  /// Backend currently supports one payment per purchase bill, so this keeps the UI
  /// convenience while staying aligned with the backend contract.
  Future<ApiResult<void>> createBatchPayment({
    required List<String> billIds,
    required Map<String, double> amounts,
    required String paymentAccountId,
    required DateTime paymentDate,
    required String paymentMethod,
  }) async {
    final repo = ref.read(vendorPaymentsRepositoryProvider);

    for (final billId in billIds) {
      final amount = amounts[billId] ?? 0;
      if (amount <= 0) continue;

      final dto = CreateVendorPaymentDto(
        purchaseBillId: billId,
        paymentAccountId: paymentAccountId,
        paymentDate: paymentDate,
        amount: amount,
        paymentMethod: paymentMethod,
      );

      final result = await repo.createPayment(dto);

      if (result.isFailure) {
        return Failure(result.error!);
      }
    }

    refresh();
    return const Success(null);
  }
}

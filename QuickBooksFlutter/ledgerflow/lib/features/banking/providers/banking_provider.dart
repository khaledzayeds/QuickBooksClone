// banking_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../data/datasources/banking_remote_datasource.dart';
import '../data/models/banking_models.dart';
import '../data/repositories/banking_repository.dart';

final bankingDatasourceProvider = Provider<BankingRemoteDatasource>(
  (ref) => BankingRemoteDatasource(ApiClient.instance),
);

final bankingRepositoryProvider = Provider<BankingRepository>(
  (ref) => BankingRepository(ref.watch(bankingDatasourceProvider)),
);

final bankAccountsProvider = FutureProvider<List<BankAccountModel>>((ref) async {
  final result = await ref.read(bankingRepositoryProvider).getAccounts();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

final selectedBankAccountIdProvider = StateProvider<String?>((ref) => null);

final bankRegisterProvider = FutureProvider.autoDispose<BankRegisterResponseModel>((ref) async {
  final accountId = ref.watch(selectedBankAccountIdProvider);
  if (accountId == null || accountId.isEmpty) {
    return const BankRegisterResponseModel(
      accountId: '',
      accountName: '',
      openingBalance: 0,
      endingBalance: 0,
      items: [],
    );
  }

  final result = await ref.read(bankingRepositoryProvider).getRegister(accountId);
  return result.when(success: (data) => data, failure: (error) => throw error);
});

final bankTransferSavingProvider = StateProvider.autoDispose<bool>((ref) => false);
final bankDepositSavingProvider = StateProvider.autoDispose<bool>((ref) => false);
final bankCheckSavingProvider = StateProvider.autoDispose<bool>((ref) => false);

class BankingActions {
  BankingActions(this.ref);
  final Ref ref;

  Future<ApiResult<void>> createTransfer(CreateBankTransferDto dto) async {
    final result = await ref.read(bankingRepositoryProvider).createTransfer(dto);
    _refreshOnSuccess(result);
    return result;
  }

  Future<ApiResult<void>> createDeposit(CreateBankDepositDto dto) async {
    final result = await ref.read(bankingRepositoryProvider).createDeposit(dto);
    _refreshOnSuccess(result);
    return result;
  }

  Future<ApiResult<void>> createCheck(CreateBankCheckDto dto) async {
    final result = await ref.read(bankingRepositoryProvider).createCheck(dto);
    _refreshOnSuccess(result);
    return result;
  }

  void _refreshOnSuccess(ApiResult<void> result) {
    if (result.isSuccess) {
      ref.invalidate(bankAccountsProvider);
      ref.invalidate(bankRegisterProvider);
    }
  }
}

final bankingActionsProvider = Provider<BankingActions>((ref) => BankingActions(ref));

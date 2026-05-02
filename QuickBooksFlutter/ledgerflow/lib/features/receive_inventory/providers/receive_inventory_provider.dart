// receive_inventory_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/receive_inventory_remote_datasource.dart';
import '../data/models/receive_inventory_model.dart';
import '../data/models/receiving_plan_model.dart';
import '../data/repositories/receive_inventory_repository.dart';

final receiveInventoryDatasourceProvider = Provider(
  (_) => ReceiveInventoryRemoteDatasource(),
);

final receiveInventoryRepoProvider = Provider(
  (ref) => ReceiveInventoryRepository(
    ref.read(receiveInventoryDatasourceProvider),
  ),
);

final receiveInventoryListProvider =
    FutureProvider<List<ReceiveInventoryModel>>((ref) async {
  final result = await ref.read(receiveInventoryRepoProvider).getAll();
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final receiveInventoryDetailsProvider =
    FutureProvider.family<ReceiveInventoryModel, String>((ref, id) async {
  final result = await ref.read(receiveInventoryRepoProvider).getById(id);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final receivingPlanProvider =
    FutureProvider.family<ReceivingPlanModel, String>((ref, poId) async {
  final result = await ref.read(receiveInventoryRepoProvider).getReceivingPlan(poId);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final receiveInventoryByVendorProvider =
    FutureProvider.family<List<ReceiveInventoryModel>, String>((ref, vendorId) async {
  final result = await ref.read(receiveInventoryRepoProvider).getAll(vendorId: vendorId);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../companies/providers/company_registry_provider.dart';
import '../data/hotel_contracts_datasource.dart';
import '../data/hotel_contracts_models.dart';

final hotelContractsDatasourceProvider = Provider<HotelContractsDatasource>(
  (_) => HotelContractsDatasource(),
);

final hotelContractsProvider = FutureProvider<List<HotelContractModel>>((
  ref,
) async {
  ref.watch(activeCompanyScopeProvider);
  final result = await ref
      .read(hotelContractsDatasourceProvider)
      .getContracts();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

final hotelAllotmentsProvider = FutureProvider<List<HotelAllotmentModel>>((
  ref,
) async {
  ref.watch(activeCompanyScopeProvider);
  final result = await ref
      .read(hotelContractsDatasourceProvider)
      .getAllotments();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

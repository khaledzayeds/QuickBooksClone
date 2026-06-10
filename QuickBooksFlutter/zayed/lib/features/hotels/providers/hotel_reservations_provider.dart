import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../companies/providers/company_registry_provider.dart';
import '../data/hotel_reservations_datasource.dart';
import '../data/hotel_reservations_models.dart';

final hotelReservationsDatasourceProvider =
    Provider<HotelReservationsDatasource>((_) => HotelReservationsDatasource());

final hotelReservationsProvider = FutureProvider<List<HotelReservationModel>>((
  ref,
) async {
  ref.watch(activeCompanyScopeProvider);
  final result = await ref
      .read(hotelReservationsDatasourceProvider)
      .getReservations();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

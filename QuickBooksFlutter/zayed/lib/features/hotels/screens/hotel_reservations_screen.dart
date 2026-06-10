import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hotel_contracts_models.dart';
import '../data/hotel_master_data_models.dart';
import '../data/hotel_reservations_models.dart';
import '../providers/hotel_contracts_provider.dart';
import '../providers/hotel_master_data_provider.dart';
import '../providers/hotel_reservations_provider.dart';

class HotelReservationsScreen extends ConsumerWidget {
  const HotelReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hotelReservationsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available_outlined),
                const SizedBox(width: 10),
                Text(
                  '400 - Individual Reservation / حجز فردي',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => ref.invalidate(hotelReservationsProvider),
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _editReservation(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('New Reservation'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (items) => items.isEmpty
                    ? const Center(
                        child: Text(
                          'No reservations yet. Create a contract and allotment first.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _ReservationTile(
                            item: item,
                            onEdit: () => _editReservation(context, ref, item),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editReservation(
    BuildContext context,
    WidgetRef ref, [
    HotelReservationModel? item,
  ]) async {
    final result = await showDialog<HotelReservationModel>(
      context: context,
      builder: (_) => _ReservationDialog(item: item),
    );
    if (result == null) return;
    final save = await ref
        .read(hotelReservationsDatasourceProvider)
        .saveReservation(result);
    if (!context.mounted) return;
    save.when(
      success: (_) => ref.invalidate(hotelReservationsProvider),
      failure: (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString()))),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  const _ReservationTile({required this.item, required this.onEdit});

  final HotelReservationModel item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        leading: Icon(
          item.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: item.isActive ? cs.primary : cs.error,
        ),
        title: Text('${item.reservationNumber} - ${item.guestName}'),
        subtitle: Text(
          '${item.hotelName} - ${item.roomTypeName}/${item.mealPlanName} - '
          '${_fmt(item.checkIn)} to ${_fmt(item.checkOut)} - '
          '${item.rooms} rooms - total ${item.totalAmount.toStringAsFixed(2)}',
        ),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text('Available ${item.availableRooms}'),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationDialog extends ConsumerStatefulWidget {
  const _ReservationDialog({this.item});

  final HotelReservationModel? item;

  @override
  ConsumerState<_ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends ConsumerState<_ReservationDialog> {
  late final _number = TextEditingController(
    text:
        widget.item?.reservationNumber ??
        'HR-${DateTime.now().millisecondsSinceEpoch}',
  );
  late final _guest = TextEditingController(text: widget.item?.guestName ?? '');
  late final _phone = TextEditingController(
    text: widget.item?.guestPhone ?? '',
  );
  late final _rooms = TextEditingController(
    text: (widget.item?.rooms ?? 1).toString(),
  );
  late final _adults = TextEditingController(
    text: (widget.item?.adults ?? 1).toString(),
  );
  late final _children = TextEditingController(
    text: (widget.item?.children ?? 0).toString(),
  );
  late final _rate = TextEditingController(
    text: (widget.item?.nightlyRate ?? 0).toStringAsFixed(2),
  );

  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  String? _contractId;
  String? _hotelId;
  String? _agentId;
  String? _roomTypeId;
  String? _mealPlanId;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _checkIn = item.checkIn;
      _checkOut = item.checkOut;
      _contractId = item.contractId;
      _hotelId = item.hotelId;
      _agentId = item.agentId;
      _roomTypeId = item.roomTypeId;
      _mealPlanId = item.mealPlanId;
    }
  }

  @override
  void dispose() {
    _number.dispose();
    _guest.dispose();
    _phone.dispose();
    _rooms.dispose();
    _adults.dispose();
    _children.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contracts =
        ref.watch(hotelContractsProvider).value ?? const <HotelContractModel>[];
    final hotels =
        ref.watch(hotelPropertiesProvider).value ??
        const <HotelPropertyModel>[];
    final agents =
        ref.watch(hotelAgentsProvider).value ?? const <HotelAgentModel>[];
    final roomTypes =
        ref.watch(hotelRoomTypesProvider).value ?? const <HotelRoomTypeModel>[];
    final mealPlans =
        ref.watch(hotelMealPlansProvider).value ?? const <HotelMealPlanModel>[];

    _contractId ??= contracts.firstOrNull?.id;
    final selectedContract = contracts
        .where((item) => item.id == _contractId)
        .firstOrNull;
    _hotelId ??= selectedContract?.hotelId ?? hotels.firstOrNull?.id;
    _agentId ??= selectedContract?.agentId;
    _roomTypeId ??=
        selectedContract?.rates.firstOrNull?.roomTypeId ??
        roomTypes.firstOrNull?.id;
    _mealPlanId ??=
        selectedContract?.rates.firstOrNull?.mealPlanId ??
        mealPlans.firstOrNull?.id;
    if ((double.tryParse(_rate.text) ?? 0) == 0) {
      final rate = _selectedRate(selectedContract);
      if (rate > 0) _rate.text = rate.toStringAsFixed(2);
    }

    final nights = _nights;
    final total =
        nights *
        (int.tryParse(_rooms.text) ?? 1) *
        (double.tryParse(_rate.text) ?? 0);

    return AlertDialog(
      title: Text(widget.item == null ? 'New Reservation' : 'Edit Reservation'),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_number, 'Reservation number'),
              _dropdown(
                'Contract',
                _contractId,
                contracts.map((x) => MapEntry(x.id, x.contractNumber)),
                (value) {
                  final contract = contracts
                      .where((item) => item.id == value)
                      .firstOrNull;
                  setState(() {
                    _contractId = value;
                    _hotelId = contract?.hotelId ?? _hotelId;
                    _agentId = contract?.agentId;
                    _roomTypeId =
                        contract?.rates.firstOrNull?.roomTypeId ?? _roomTypeId;
                    _mealPlanId =
                        contract?.rates.firstOrNull?.mealPlanId ?? _mealPlanId;
                    final rate = _selectedRate(contract);
                    if (rate > 0) _rate.text = rate.toStringAsFixed(2);
                  });
                },
              ),
              _dropdown(
                'Hotel',
                _hotelId,
                hotels.map((x) => MapEntry(x.id, x.name)),
                (value) => setState(() => _hotelId = value),
              ),
              _dropdown(
                'Agent',
                _agentId,
                agents.map((x) => MapEntry(x.id, x.name)),
                (value) => setState(() => _agentId = value),
                allowEmpty: true,
              ),
              _dropdown(
                'Room type',
                _roomTypeId,
                roomTypes.map((x) => MapEntry(x.id, x.name)),
                (value) => setState(() {
                  _roomTypeId = value;
                  final rate = _selectedRate(selectedContract);
                  if (rate > 0) _rate.text = rate.toStringAsFixed(2);
                }),
              ),
              _dropdown(
                'Meal plan',
                _mealPlanId,
                mealPlans.map((x) => MapEntry(x.id, x.name)),
                (value) => setState(() {
                  _mealPlanId = value;
                  final rate = _selectedRate(selectedContract);
                  if (rate > 0) _rate.text = rate.toStringAsFixed(2);
                }),
              ),
              _field(_guest, 'Guest name'),
              _field(_phone, 'Guest phone'),
              Row(
                children: [
                  Expanded(
                    child: _dateButton(
                      context,
                      'Check-in',
                      _checkIn,
                      (value) => setState(() => _checkIn = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dateButton(
                      context,
                      'Check-out',
                      _checkOut,
                      (value) => setState(() => _checkOut = value),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field(_rooms, 'Rooms', numeric: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_adults, 'Adults', numeric: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_children, 'Children', numeric: true)),
                ],
              ),
              _field(_rate, 'Nightly rate', numeric: true),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'Nights: $nights - Estimated total: ${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  int get _nights => (_checkOut.difference(_checkIn).inDays).clamp(1, 999);

  double _selectedRate(HotelContractModel? contract) {
    if (contract == null || _roomTypeId == null || _mealPlanId == null) {
      return 0;
    }
    return contract.rates
            .where(
              (rate) =>
                  rate.roomTypeId == _roomTypeId &&
                  rate.mealPlanId == _mealPlanId,
            )
            .firstOrNull
            ?.rate ??
        0;
  }

  void _submit() {
    if (_contractId == null ||
        _hotelId == null ||
        _roomTypeId == null ||
        _mealPlanId == null ||
        _number.text.trim().isEmpty ||
        _guest.text.trim().isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      HotelReservationModel(
        id: widget.item?.id ?? '',
        reservationNumber: _number.text.trim(),
        contractId: _contractId!,
        contractNumber: '',
        hotelId: _hotelId!,
        hotelName: '',
        agentId: _agentId,
        agentName: null,
        roomTypeId: _roomTypeId!,
        roomTypeName: '',
        mealPlanId: _mealPlanId!,
        mealPlanName: '',
        guestName: _guest.text.trim(),
        guestPhone: _phone.text.trim(),
        checkIn: _checkIn,
        checkOut: _checkOut.isAfter(_checkIn)
            ? _checkOut
            : _checkIn.add(const Duration(days: 1)),
        nights: _nights,
        rooms: int.tryParse(_rooms.text.trim()) ?? 1,
        adults: int.tryParse(_adults.text.trim()) ?? 1,
        children: int.tryParse(_children.text.trim()) ?? 0,
        nightlyRate: double.tryParse(_rate.text.trim()) ?? 0,
        totalAmount: 0,
        status: widget.item?.status ?? 'confirmed',
        isActive: widget.item?.isActive ?? true,
        availableRooms: widget.item?.availableRooms ?? 0,
      ),
    );
  }
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool numeric = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

Widget _dropdown(
  String label,
  String? value,
  Iterable<MapEntry<String, String>> entries,
  ValueChanged<String?> onChanged, {
  bool allowEmpty = false,
}) {
  final items = entries.toList();
  final safeValue = items.any((item) => item.key == value) ? value : null;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        if (allowEmpty)
          const DropdownMenuItem<String>(value: null, child: Text('None')),
        ...items.map(
          (item) => DropdownMenuItem(value: item.key, child: Text(item.value)),
        ),
      ],
      onChanged: onChanged,
    ),
  );
}

Widget _dateButton(
  BuildContext context,
  String label,
  DateTime value,
  ValueChanged<DateTime> onChanged,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2040),
          initialDate: value,
        );
        if (picked != null) onChanged(picked);
      },
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text('$label: ${_fmt(value)}'),
    ),
  );
}

String _fmt(DateTime value) => value.toIso8601String().substring(0, 10);

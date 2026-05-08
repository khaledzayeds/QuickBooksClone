import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';

final timeEntriesProvider = FutureProvider.autoDispose<TimeEntryList>((ref) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/time-entries');
  return TimeEntryList.fromJson(response.data!);
});

final timeEntryLookupsProvider = FutureProvider.autoDispose<TimeEntryLookups>((ref) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/time-entries/lookups');
  return TimeEntryLookups.fromJson(response.data!);
});

final timeEntriesCommandsProvider = Provider<TimeEntriesCommands>((ref) => TimeEntriesCommands(ref));

class TimeEntriesCommands {
  const TimeEntriesCommands(this.ref);

  final Ref ref;

  Future<void> create({
    required DateTime workDate,
    required String personName,
    required double hours,
    required String activity,
    String? notes,
    String? customerId,
    String? serviceItemId,
    required bool isBillable,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/time-entries',
      data: {
        'workDate': _dateOnly(workDate),
        'personName': personName,
        'hours': hours,
        'activity': activity,
        'notes': notes,
        'customerId': customerId,
        'serviceItemId': serviceItemId,
        'isBillable': isBillable,
      },
    );
    ref.invalidate(timeEntriesProvider);
  }

  Future<void> approve(String id) async {
    await ApiClient.instance.post<Map<String, dynamic>>('/api/time-entries/$id/approve');
    ref.invalidate(timeEntriesProvider);
  }

  Future<void> markBillable(String id) async {
    await ApiClient.instance.post<Map<String, dynamic>>('/api/time-entries/$id/mark-billable');
    ref.invalidate(timeEntriesProvider);
  }

  Future<void> markInvoiced(String id, {String? invoiceId}) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/time-entries/$id/mark-invoiced-with-link',
      data: {'invoiceId': invoiceId},
    );
    ref.invalidate(timeEntriesProvider);
  }

  Future<void> voidEntry(String id) async {
    await ApiClient.instance.patch<Map<String, dynamic>>('/api/time-entries/$id/void');
    ref.invalidate(timeEntriesProvider);
  }
}

class TimeEntryList {
  const TimeEntryList({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalHours,
    required this.billableHours,
    required this.nonBillableHours,
  });

  final List<TimeEntry> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final double totalHours;
  final double billableHours;
  final double nonBillableHours;

  factory TimeEntryList.fromJson(Map<String, dynamic> json) => TimeEntryList(
        items: JsonUtils.asList(json['items'], (row) => TimeEntry.fromJson(row)),
        totalCount: JsonUtils.asInt(json['totalCount']),
        page: JsonUtils.asInt(json['page']),
        pageSize: JsonUtils.asInt(json['pageSize']),
        totalHours: JsonUtils.asDouble(json['totalHours']),
        billableHours: JsonUtils.asDouble(json['billableHours']),
        nonBillableHours: JsonUtils.asDouble(json['nonBillableHours']),
      );
}

class TimeEntryLookups {
  const TimeEntryLookups({required this.customers, required this.serviceItems});

  final List<TimeEntryCustomerLookup> customers;
  final List<TimeEntryServiceItemLookup> serviceItems;

  factory TimeEntryLookups.fromJson(Map<String, dynamic> json) => TimeEntryLookups(
        customers: JsonUtils.asList(json['customers'], (row) => TimeEntryCustomerLookup.fromJson(row)),
        serviceItems: JsonUtils.asList(json['serviceItems'], (row) => TimeEntryServiceItemLookup.fromJson(row)),
      );
}

class TimeEntryCustomerLookup {
  const TimeEntryCustomerLookup({required this.id, required this.displayName});

  final String id;
  final String displayName;

  factory TimeEntryCustomerLookup.fromJson(Map<String, dynamic> json) => TimeEntryCustomerLookup(
        id: JsonUtils.asString(json['id']),
        displayName: JsonUtils.asString(json['displayName']),
      );
}

class TimeEntryServiceItemLookup {
  const TimeEntryServiceItemLookup({required this.id, required this.name});

  final String id;
  final String name;

  factory TimeEntryServiceItemLookup.fromJson(Map<String, dynamic> json) => TimeEntryServiceItemLookup(
        id: JsonUtils.asString(json['id']),
        name: JsonUtils.asString(json['name']),
      );
}

class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.workDate,
    required this.personName,
    required this.hours,
    required this.activity,
    required this.notes,
    required this.customerId,
    required this.customerName,
    required this.serviceItemId,
    required this.serviceItemName,
    required this.invoiceId,
    required this.isBillable,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime workDate;
  final String personName;
  final double hours;
  final String activity;
  final String? notes;
  final String? customerId;
  final String? customerName;
  final String? serviceItemId;
  final String? serviceItemName;
  final String? invoiceId;
  final bool isBillable;
  final TimeEntryStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory TimeEntry.fromJson(Map<String, dynamic> json) => TimeEntry(
        id: JsonUtils.asString(json['id']),
        workDate: _parseDate(json['workDate']),
        personName: JsonUtils.asString(json['personName']),
        hours: JsonUtils.asDouble(json['hours']),
        activity: JsonUtils.asString(json['activity']),
        notes: JsonUtils.asNullableString(json['notes']),
        customerId: JsonUtils.asNullableString(json['customerId']),
        customerName: JsonUtils.asNullableString(json['customerName']),
        serviceItemId: JsonUtils.asNullableString(json['serviceItemId']),
        serviceItemName: JsonUtils.asNullableString(json['serviceItemName']),
        invoiceId: JsonUtils.asNullableString(json['invoiceId']),
        isBillable: JsonUtils.asBool(json['isBillable']),
        status: _status(json['status']),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: json['updatedAt'] == null ? null : _parseDate(json['updatedAt']),
      );
}

enum TimeEntryStatus { open, approved, billable, invoiced, voided }

TimeEntryStatus _status(dynamic value) {
  final text = value.toString().toLowerCase();
  return switch (text) {
    '2' || 'approved' => TimeEntryStatus.approved,
    '3' || 'invoiced' => TimeEntryStatus.invoiced,
    '4' || 'void' || 'voided' => TimeEntryStatus.voided,
    '5' || 'billable' => TimeEntryStatus.billable,
    _ => TimeEntryStatus.open,
  };
}

String _dateOnly(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

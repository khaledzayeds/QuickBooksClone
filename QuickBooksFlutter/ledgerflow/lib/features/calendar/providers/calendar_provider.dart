import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';

final calendarProvider = FutureProvider.autoDispose<CalendarSummary>((ref) async {
  final now = DateTime.now();
  final fromDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
  final toDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 60));

  final response = await ApiClient.instance.get<Map<String, dynamic>>(
    '/api/calendar',
    queryParameters: {
      'fromDate': _dateOnly(fromDate),
      'toDate': _dateOnly(toDate),
    },
  );

  return CalendarSummary.fromJson(response.data!);
});

class CalendarSummary {
  const CalendarSummary({
    required this.fromDate,
    required this.toDate,
    required this.today,
    required this.totalEvents,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.upcomingCount,
    required this.totalReceivableDue,
    required this.totalPayableDue,
    required this.events,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final DateTime today;
  final int totalEvents;
  final int overdueCount;
  final int dueTodayCount;
  final int upcomingCount;
  final double totalReceivableDue;
  final double totalPayableDue;
  final List<CalendarEvent> events;

  factory CalendarSummary.fromJson(Map<String, dynamic> json) => CalendarSummary(
        fromDate: _parseDate(json['fromDate']),
        toDate: _parseDate(json['toDate']),
        today: _parseDate(json['today']),
        totalEvents: JsonUtils.asInt(json['totalEvents']),
        overdueCount: JsonUtils.asInt(json['overdueCount']),
        dueTodayCount: JsonUtils.asInt(json['dueTodayCount']),
        upcomingCount: JsonUtils.asInt(json['upcomingCount']),
        totalReceivableDue: JsonUtils.asDouble(json['totalReceivableDue']),
        totalPayableDue: JsonUtils.asDouble(json['totalPayableDue']),
        events: JsonUtils.asList(
          json['events'],
          (row) => CalendarEvent.fromJson(row),
        ),
      );
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.documentNumber,
    required this.title,
    required this.partyName,
    required this.documentDate,
    required this.dueDate,
    required this.amountDue,
    required this.status,
    required this.severity,
    required this.route,
  });

  final String id;
  final String sourceType;
  final String sourceId;
  final String documentNumber;
  final String title;
  final String partyName;
  final DateTime documentDate;
  final DateTime dueDate;
  final double amountDue;
  final String status;
  final CalendarSeverity severity;
  final String route;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: JsonUtils.asString(json['id']),
        sourceType: JsonUtils.asString(json['sourceType']),
        sourceId: JsonUtils.asString(json['sourceId']),
        documentNumber: JsonUtils.asString(json['documentNumber']),
        title: JsonUtils.asString(json['title']),
        partyName: JsonUtils.asString(json['partyName']),
        documentDate: _parseDate(json['documentDate']),
        dueDate: _parseDate(json['dueDate']),
        amountDue: JsonUtils.asDouble(json['amountDue']),
        status: JsonUtils.asString(json['status']),
        severity: _severity(JsonUtils.asString(json['severity'])),
        route: JsonUtils.asString(json['route']),
      );
}

enum CalendarSeverity { overdue, dueToday, soon, upcoming }

CalendarSeverity _severity(String value) => switch (value) {
      'overdue' => CalendarSeverity.overdue,
      'dueToday' => CalendarSeverity.dueToday,
      'soon' => CalendarSeverity.soon,
      _ => CalendarSeverity.upcoming,
    };

DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

String _dateOnly(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

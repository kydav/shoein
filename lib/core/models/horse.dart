import 'package:cloud_firestore/cloud_firestore.dart';

/// Default trim/shoe cadence, in weeks, when a horse doesn't specify one.
const kDefaultIntervalWeeks = 6;

/// Where a horse sits in its trim cycle.
enum DueStatus { neverServiced, overdue, dueThisWeek, upcoming, ok }

/// A horse belonging to a [Client].
class Horse {
  final String id;
  final String clientId;
  final String name;
  final String breed;
  final String notes;
  final DateTime? lastServiceDate;

  /// Trim/shoe cadence in weeks. Next-due is [lastServiceDate] + this.
  final int intervalWeeks;

  const Horse({
    required this.id,
    required this.clientId,
    required this.name,
    this.breed = '',
    this.notes = '',
    this.lastServiceDate,
    this.intervalWeeks = kDefaultIntervalWeeks,
  });

  /// Days since the last service, or null if never serviced.
  int? get daysSinceService {
    if (lastServiceDate == null) return null;
    return DateTime.now().difference(lastServiceDate!).inDays;
  }

  /// When this horse is next due, or null if never serviced.
  DateTime? get nextDueDate =>
      lastServiceDate?.add(Duration(days: intervalWeeks * 7));

  /// Days until next due (negative = overdue), or null if never serviced.
  int? get daysUntilDue {
    final due = nextDueDate;
    if (due == null) return null;
    final now = DateTime.now();
    return DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  DueStatus get dueStatus {
    final days = daysUntilDue;
    if (days == null) return DueStatus.neverServiced;
    if (days < 0) return DueStatus.overdue;
    if (days <= 7) return DueStatus.dueThisWeek;
    if (days <= 21) return DueStatus.upcoming;
    return DueStatus.ok;
  }

  factory Horse.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final ts = d['lastServiceDate'];
    return Horse(
      id: doc.id,
      clientId: (d['clientId'] ?? '') as String,
      name: (d['name'] ?? '') as String,
      breed: (d['breed'] ?? '') as String,
      notes: (d['notes'] ?? '') as String,
      lastServiceDate: ts is Timestamp ? ts.toDate() : null,
      intervalWeeks:
          (d['intervalWeeks'] as num?)?.toInt() ?? kDefaultIntervalWeeks,
    );
  }

  Map<String, dynamic> toMap() => {
    'clientId': clientId,
    'name': name,
    'breed': breed,
    'notes': notes,
    'lastServiceDate': lastServiceDate == null
        ? null
        : Timestamp.fromDate(lastServiceDate!),
    'intervalWeeks': intervalWeeks,
  };

  Horse copyWith({
    String? id,
    String? clientId,
    String? name,
    String? breed,
    String? notes,
    DateTime? lastServiceDate,
    int? intervalWeeks,
    bool clearServiceDate = false,
  }) => Horse(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    name: name ?? this.name,
    breed: breed ?? this.breed,
    notes: notes ?? this.notes,
    lastServiceDate: clearServiceDate
        ? null
        : (lastServiceDate ?? this.lastServiceDate),
    intervalWeeks: intervalWeeks ?? this.intervalWeeks,
  );
}

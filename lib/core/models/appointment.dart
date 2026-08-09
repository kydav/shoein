import 'package:cloud_firestore/cloud_firestore.dart';

/// A scheduled farrier appointment. Client name/address are denormalized so the
/// calendar list and "add to phone calendar" work without a join.
class Appointment {
  final String id;
  final String clientId;
  final String clientName;
  final String clientAddress;
  final DateTime start;
  final int durationMinutes;
  final String notes;

  const Appointment({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientAddress = '',
    required this.start,
    this.durationMinutes = 60,
    this.notes = '',
  });

  DateTime get end => start.add(Duration(minutes: durationMinutes));

  factory Appointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final ts = d['start'];
    return Appointment(
      id: doc.id,
      clientId: (d['clientId'] ?? '') as String,
      clientName: (d['clientName'] ?? '') as String,
      clientAddress: (d['clientAddress'] ?? '') as String,
      start: ts is Timestamp ? ts.toDate() : DateTime.now(),
      durationMinutes: (d['durationMinutes'] as num?)?.toInt() ?? 60,
      notes: (d['notes'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'clientId': clientId,
    'clientName': clientName,
    'clientAddress': clientAddress,
    'start': Timestamp.fromDate(start),
    'durationMinutes': durationMinutes,
    'notes': notes,
  };

  Appointment copyWith({String? id, DateTime? start}) => Appointment(
    id: id ?? this.id,
    clientId: clientId,
    clientName: clientName,
    clientAddress: clientAddress,
    start: start ?? this.start,
    durationMinutes: durationMinutes,
    notes: notes,
  );
}

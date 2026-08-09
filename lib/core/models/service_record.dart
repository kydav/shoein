import 'package:cloud_firestore/cloud_firestore.dart';

/// A logged farrier visit for a horse.
class ServiceRecord {
  final String id;
  final String clientId;
  final String horseId;
  final DateTime date;
  final String workType; // e.g. "Trim", "Full set", "Reset"
  final String notes;
  final double? cost;
  final bool paid;

  const ServiceRecord({
    required this.id,
    required this.clientId,
    required this.horseId,
    required this.date,
    this.workType = '',
    this.notes = '',
    this.cost,
    this.paid = false,
  });

  factory ServiceRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final ts = d['date'];
    return ServiceRecord(
      id: doc.id,
      clientId: (d['clientId'] ?? '') as String,
      horseId: (d['horseId'] ?? '') as String,
      date: ts is Timestamp ? ts.toDate() : DateTime.now(),
      workType: (d['workType'] ?? '') as String,
      notes: (d['notes'] ?? '') as String,
      cost: (d['cost'] as num?)?.toDouble(),
      paid: (d['paid'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
    'clientId': clientId,
    'horseId': horseId,
    'date': Timestamp.fromDate(date),
    'workType': workType,
    'notes': notes,
    'cost': cost,
    'paid': paid,
  };

  ServiceRecord copyWith({String? id, bool? paid}) => ServiceRecord(
    id: id ?? this.id,
    clientId: clientId,
    horseId: horseId,
    date: date,
    workType: workType,
    notes: notes,
    cost: cost,
    paid: paid ?? this.paid,
  );
}

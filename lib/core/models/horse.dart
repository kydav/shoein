import 'package:cloud_firestore/cloud_firestore.dart';

/// A horse belonging to a [Client].
class Horse {
  final String id;
  final String clientId;
  final String name;
  final String breed;
  final String notes;
  final DateTime? lastServiceDate;

  const Horse({
    required this.id,
    required this.clientId,
    required this.name,
    this.breed = '',
    this.notes = '',
    this.lastServiceDate,
  });

  /// Days since the last service, or null if never serviced.
  int? get daysSinceService {
    if (lastServiceDate == null) return null;
    return DateTime.now().difference(lastServiceDate!).inDays;
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
  };

  Horse copyWith({
    String? id,
    String? clientId,
    String? name,
    String? breed,
    String? notes,
    DateTime? lastServiceDate,
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
  );
}

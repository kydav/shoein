import 'package:cloud_firestore/cloud_firestore.dart';

/// A farrier's client — the person/barn whose horses they service.
class Client {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final double? lat; // geocoded from address, for the map
  final double? lng;
  final String notes;

  const Client({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.lat,
    this.lng,
    this.notes = '',
  });

  bool get hasLocation => lat != null && lng != null;

  factory Client.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Client(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      phone: (d['phone'] ?? '') as String,
      email: (d['email'] ?? '') as String,
      address: (d['address'] ?? '') as String,
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      notes: (d['notes'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'lat': lat,
    'lng': lng,
    'notes': notes,
    'nameLower': name.toLowerCase(),
  };

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? lat,
    double? lng,
    String? notes,
  }) => Client(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    notes: notes ?? this.notes,
  );
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment.dart';
import '../models/client.dart';
import '../models/horse.dart';
import '../models/service_record.dart';

/// Data access for clients and their horses. Two implementations:
/// [FirestoreRepository] (real) and [DemoRepository] (in-memory, for running
/// before Firebase is configured).
abstract class ShoeinRepository {
  Stream<List<Client>> watchClients();
  Stream<Client?> watchClient(String clientId);
  Future<String> upsertClient(Client client);
  Future<void> deleteClient(String clientId);

  Stream<List<Horse>> watchHorses(String clientId);
  Future<void> upsertHorse(Horse horse);
  Future<void> deleteHorse(String clientId, String horseId);

  Stream<List<ServiceRecord>> watchServices(String clientId, String horseId);

  /// Record a visit: writes the service record and rolls the horse's
  /// lastServiceDate forward to the visit date (which reschedules next-due).
  Future<void> logService(ServiceRecord record);

  Stream<List<Appointment>> watchAppointments();
  Future<String> upsertAppointment(Appointment appointment);
  Future<void> deleteAppointment(String id);
}

// ─── Firestore ────────────────────────────────────────────────────────────────
// Layout: users/{uid}/clients/{clientId}
//         users/{uid}/clients/{clientId}/horses/{horseId}

class FirestoreRepository implements ShoeinRepository {
  FirestoreRepository(this._db, this._uid);

  final FirebaseFirestore _db;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _clients =>
      _db.collection('users').doc(_uid).collection('clients');

  CollectionReference<Map<String, dynamic>> _horses(String clientId) =>
      _clients.doc(clientId).collection('horses');

  @override
  Stream<List<Client>> watchClients() => _clients
      .orderBy('nameLower')
      .snapshots()
      .map((s) => s.docs.map(Client.fromDoc).toList());

  @override
  Stream<Client?> watchClient(String clientId) => _clients
      .doc(clientId)
      .snapshots()
      .map((d) => d.exists ? Client.fromDoc(d) : null);

  @override
  Future<String> upsertClient(Client client) async {
    if (client.id.isEmpty) {
      final ref = await _clients.add(client.toMap());
      return ref.id;
    }
    await _clients.doc(client.id).set(client.toMap(), SetOptions(merge: true));
    return client.id;
  }

  @override
  Future<void> deleteClient(String clientId) async {
    final horses = await _horses(clientId).get();
    for (final h in horses.docs) {
      await h.reference.delete();
    }
    await _clients.doc(clientId).delete();
  }

  @override
  Stream<List<Horse>> watchHorses(String clientId) => _horses(
    clientId,
  ).orderBy('name').snapshots().map((s) => s.docs.map(Horse.fromDoc).toList());

  @override
  Future<void> upsertHorse(Horse horse) async {
    final col = _horses(horse.clientId);
    if (horse.id.isEmpty) {
      await col.add(horse.toMap());
    } else {
      await col.doc(horse.id).set(horse.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteHorse(String clientId, String horseId) =>
      _horses(clientId).doc(horseId).delete();

  CollectionReference<Map<String, dynamic>> _services(
    String clientId,
    String horseId,
  ) => _horses(clientId).doc(horseId).collection('services');

  @override
  Stream<List<ServiceRecord>> watchServices(String clientId, String horseId) =>
      _services(clientId, horseId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((s) => s.docs.map(ServiceRecord.fromDoc).toList());

  @override
  Future<void> logService(ServiceRecord record) async {
    await _services(record.clientId, record.horseId).add(record.toMap());
    await _horses(record.clientId).doc(record.horseId).set({
      'lastServiceDate': Timestamp.fromDate(record.date),
    }, SetOptions(merge: true));
  }

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('users').doc(_uid).collection('appointments');

  @override
  Stream<List<Appointment>> watchAppointments() => _appointments
      .orderBy('start')
      .snapshots()
      .map((s) => s.docs.map(Appointment.fromDoc).toList());

  @override
  Future<String> upsertAppointment(Appointment appointment) async {
    if (appointment.id.isEmpty) {
      final ref = await _appointments.add(appointment.toMap());
      return ref.id;
    }
    await _appointments
        .doc(appointment.id)
        .set(appointment.toMap(), SetOptions(merge: true));
    return appointment.id;
  }

  @override
  Future<void> deleteAppointment(String id) => _appointments.doc(id).delete();
}

// ─── In-memory demo ───────────────────────────────────────────────────────────

class DemoRepository implements ShoeinRepository {
  DemoRepository() {
    _seed();
  }

  final List<Client> _clients = [];
  final Map<String, List<Horse>> _horses = {};
  final _clientsChanged = StreamController<void>.broadcast();
  final _horsesChanged = StreamController<void>.broadcast();
  int _seq = 0;

  String _id() => 'demo${_seq++}';

  void _seed() {
    final c1 = Client(
      id: _id(),
      name: 'Willow Creek Ranch',
      phone: '555-0142',
      address: '1200 Ranch Rd, Boulder, CO',
      lat: 40.0150,
      lng: -105.2705,
      notes: 'Gate code 4412. Dogs are friendly.',
    );
    final c2 = Client(
      id: _id(),
      name: 'Dana Whitfield',
      phone: '555-0199',
      address: '55 Meadow Ln, Longmont, CO',
      lat: 40.1672,
      lng: -105.1019,
      notes: 'Prefers early mornings.',
    );
    _clients.addAll([c1, c2]);
    _horses[c1.id] = [
      Horse(
        id: _id(),
        clientId: c1.id,
        name: 'Cash',
        breed: 'Quarter Horse',
        notes: 'Front-left tends to chip. Hot shod.',
        lastServiceDate: DateTime.now().subtract(const Duration(days: 38)),
      ),
      Horse(
        id: _id(),
        clientId: c1.id,
        name: 'Biscuit',
        breed: 'Paint',
        notes: 'Barefoot trim only.',
        lastServiceDate: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ];
    _horses[c2.id] = [
      Horse(
        id: _id(),
        clientId: c2.id,
        name: 'Juniper',
        breed: 'Arabian',
        notes: 'Sensitive; go slow with hinds.',
        lastServiceDate: DateTime.now().subtract(const Duration(days: 51)),
      ),
    ];
  }

  @override
  Stream<List<Client>> watchClients() async* {
    yield _sorted();
    yield* _clientsChanged.stream.map((_) => _sorted());
  }

  List<Client> _sorted() =>
      List.of(_clients)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  @override
  Stream<Client?> watchClient(String clientId) async* {
    yield _find(clientId);
    yield* _clientsChanged.stream.map((_) => _find(clientId));
  }

  Client? _find(String id) {
    for (final c in _clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<String> upsertClient(Client client) async {
    if (client.id.isEmpty) {
      final created = client.copyWith(id: _id());
      _clients.add(created);
      _horses[created.id] = [];
      _clientsChanged.add(null);
      return created.id;
    }
    final i = _clients.indexWhere((c) => c.id == client.id);
    if (i >= 0) _clients[i] = client;
    _clientsChanged.add(null);
    return client.id;
  }

  @override
  Future<void> deleteClient(String clientId) async {
    _clients.removeWhere((c) => c.id == clientId);
    _horses.remove(clientId);
    _clientsChanged.add(null);
  }

  @override
  Stream<List<Horse>> watchHorses(String clientId) async* {
    yield List.of(_horses[clientId] ?? const []);
    yield* _horsesChanged.stream.map(
      (_) => List.of(_horses[clientId] ?? const []),
    );
  }

  @override
  Future<void> upsertHorse(Horse horse) async {
    final list = _horses.putIfAbsent(horse.clientId, () => []);
    if (horse.id.isEmpty) {
      list.add(horse.copyWith(id: _id()));
    } else {
      final i = list.indexWhere((h) => h.id == horse.id);
      if (i >= 0) list[i] = horse;
    }
    _horsesChanged.add(null);
  }

  @override
  Future<void> deleteHorse(String clientId, String horseId) async {
    _horses[clientId]?.removeWhere((h) => h.id == horseId);
    _horsesChanged.add(null);
  }

  final Map<String, List<ServiceRecord>> _services = {};
  final _servicesChanged = StreamController<void>.broadcast();

  @override
  Stream<List<ServiceRecord>> watchServices(
    String clientId,
    String horseId,
  ) async* {
    List<ServiceRecord> current() =>
        List.of(_services[horseId] ?? const [])
          ..sort((a, b) => b.date.compareTo(a.date));
    yield current();
    yield* _servicesChanged.stream.map((_) => current());
  }

  @override
  Future<void> logService(ServiceRecord record) async {
    final list = _services.putIfAbsent(record.horseId, () => []);
    list.add(record.copyWith(id: _id()));
    // Roll the horse's last-service date forward.
    final horses = _horses[record.clientId];
    if (horses != null) {
      final i = horses.indexWhere((h) => h.id == record.horseId);
      if (i >= 0) {
        horses[i] = horses[i].copyWith(lastServiceDate: record.date);
      }
    }
    _servicesChanged.add(null);
    _horsesChanged.add(null);
  }

  final List<Appointment> _appointments = [];
  final _appointmentsChanged = StreamController<void>.broadcast();

  @override
  Stream<List<Appointment>> watchAppointments() async* {
    List<Appointment> current() =>
        List.of(_appointments)..sort((a, b) => a.start.compareTo(b.start));
    yield current();
    yield* _appointmentsChanged.stream.map((_) => current());
  }

  @override
  Future<String> upsertAppointment(Appointment appointment) async {
    if (appointment.id.isEmpty) {
      final created = appointment.copyWith(id: _id());
      _appointments.add(created);
      _appointmentsChanged.add(null);
      return created.id;
    }
    final i = _appointments.indexWhere((a) => a.id == appointment.id);
    if (i >= 0) _appointments[i] = appointment;
    _appointmentsChanged.add(null);
    return appointment.id;
  }

  @override
  Future<void> deleteAppointment(String id) async {
    _appointments.removeWhere((a) => a.id == id);
    _appointmentsChanged.add(null);
  }
}

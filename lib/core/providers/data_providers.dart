import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoein/core/models/client.dart';
import 'package:shoein/core/models/horse.dart';
import 'package:shoein/core/models/service_record.dart';
import 'package:shoein/core/providers/auth_provider.dart';
import 'package:shoein/core/services/firebase_bootstrap.dart';
import 'package:shoein/core/services/shoein_repository.dart';

/// Single demo store so in-memory data persists across provider rebuilds.
final _demo = DemoRepository();

final repositoryProvider = Provider<ShoeinRepository>((ref) {
  if (firebaseReady) {
    final uid = ref.watch(authNotifierProvider).uid;
    return FirestoreRepository(FirebaseFirestore.instance, uid);
  }
  return _demo;
});

final clientsProvider = StreamProvider<List<Client>>(
  (ref) => ref.watch(repositoryProvider).watchClients(),
);

final clientProvider = StreamProvider.family<Client?, String>(
  (ref, id) => ref.watch(repositoryProvider).watchClient(id),
);

final horsesProvider = StreamProvider.family<List<Horse>, String>(
  (ref, clientId) => ref.watch(repositoryProvider).watchHorses(clientId),
);

/// Logged visits for a horse, newest first.
final servicesProvider =
    StreamProvider.family<
      List<ServiceRecord>,
      ({String clientId, String horseId})
    >(
      (ref, key) => ref
          .watch(repositoryProvider)
          .watchServices(key.clientId, key.horseId),
    );

/// A horse paired with its owning client, for the dashboard.
typedef DueHorse = ({Client client, Horse horse});

/// Every horse across every client, paired with its client and sorted by
/// soonest-due first (never-serviced sorts last). Reacts as clients/horses
/// streams update.
final dueHorsesProvider = Provider<List<DueHorse>>((ref) {
  final clients = ref.watch(clientsProvider).valueOrNull ?? const [];
  final out = <DueHorse>[];
  for (final c in clients) {
    final horses = ref.watch(horsesProvider(c.id)).valueOrNull ?? const [];
    for (final h in horses) {
      out.add((client: c, horse: h));
    }
  }
  out.sort((a, b) {
    final da = a.horse.daysUntilDue;
    final db = b.horse.daysUntilDue;
    if (da == null && db == null) return 0;
    if (da == null) return 1; // never-serviced last
    if (db == null) return -1;
    return da.compareTo(db);
  });
  return out;
});

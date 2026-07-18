import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoein/core/models/client.dart';
import 'package:shoein/core/models/horse.dart';
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

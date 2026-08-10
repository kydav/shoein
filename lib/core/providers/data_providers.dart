import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoein/core/models/appointment.dart';
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

/// All scheduled appointments, earliest first.
final appointmentsProvider = StreamProvider<List<Appointment>>(
  (ref) => ref.watch(repositoryProvider).watchAppointments(),
);

/// A billable (unpaid, priced) service paired with its horse's name.
typedef BillableService = ({ServiceRecord service, String horseName});

/// A client's unpaid, priced service records across all their horses — the
/// candidates for an invoice, oldest first.
final clientUnpaidServicesProvider =
    Provider.family<List<BillableService>, String>((ref, clientId) {
      final horses =
          ref.watch(horsesProvider(clientId)).valueOrNull ?? const [];
      final out = <BillableService>[];
      for (final h in horses) {
        final services =
            ref
                .watch(servicesProvider((clientId: clientId, horseId: h.id)))
                .valueOrNull ??
            const [];
        for (final s in services) {
          if (!s.paid && (s.cost ?? 0) > 0) {
            out.add((service: s, horseName: h.name));
          }
        }
      }
      out.sort((a, b) => a.service.date.compareTo(b.service.date));
      return out;
    });

/// Every logged service across all clients/horses, paired with the client's
/// name. Aggregated live from the existing per-horse service streams.
typedef ClientService = ({ServiceRecord service, String clientName});

final allServicesProvider = Provider<List<ClientService>>((ref) {
  final clients = ref.watch(clientsProvider).valueOrNull ?? const [];
  final out = <ClientService>[];
  for (final c in clients) {
    final horses = ref.watch(horsesProvider(c.id)).valueOrNull ?? const [];
    for (final h in horses) {
      final services =
          ref
              .watch(servicesProvider((clientId: c.id, horseId: h.id)))
              .valueOrNull ??
          const [];
      for (final s in services) {
        out.add((service: s, clientName: c.name));
      }
    }
  }
  return out;
});

/// One month's paid earnings, for the earnings chart.
class MonthEarning {
  final DateTime month;
  final double paid;
  const MonthEarning(this.month, this.paid);
}

/// Aggregated income figures for the earnings screen.
class EarningsData {
  final double thisMonthPaid;
  final double outstanding; // unpaid, priced visits
  final double ytdPaid;
  final double lifetimePaid;
  final int visitsThisMonth;
  final List<MonthEarning> monthly; // last 6 months, oldest → newest
  final List<({String name, double total})> topClients; // by paid revenue
  const EarningsData({
    required this.thisMonthPaid,
    required this.outstanding,
    required this.ytdPaid,
    required this.lifetimePaid,
    required this.visitsThisMonth,
    required this.monthly,
    required this.topClients,
  });
}

/// Rolls all service records up into income figures + a 6-month trend.
final earningsProvider = Provider<EarningsData>((ref) {
  final all = ref.watch(allServicesProvider);
  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month);
  final yearStart = DateTime(now.year);

  // Six month buckets ending with the current month (DateTime normalizes the
  // negative-month arithmetic across year boundaries).
  final months = List.generate(
    6,
    (i) => DateTime(now.year, now.month - (5 - i)),
  );
  final monthly = {for (final m in months) m: 0.0};
  final byClient = <String, double>{};

  double thisMonthPaid = 0, outstanding = 0, ytdPaid = 0, lifetimePaid = 0;
  var visitsThisMonth = 0;

  for (final cs in all) {
    final s = cs.service;
    final cost = s.cost ?? 0;
    if (cost <= 0) continue;
    if (!s.paid) {
      outstanding += cost;
      continue;
    }
    lifetimePaid += cost;
    final bucket = DateTime(s.date.year, s.date.month);
    if (monthly.containsKey(bucket)) monthly[bucket] = monthly[bucket]! + cost;
    if (!s.date.isBefore(thisMonthStart)) {
      thisMonthPaid += cost;
      visitsThisMonth++;
    }
    if (!s.date.isBefore(yearStart)) ytdPaid += cost;
    byClient[cs.clientName] = (byClient[cs.clientName] ?? 0) + cost;
  }

  final topClients =
      (byClient.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .map((e) => (name: e.key, total: e.value))
          .toList();

  return EarningsData(
    thisMonthPaid: thisMonthPaid,
    outstanding: outstanding,
    ytdPaid: ytdPaid,
    lifetimePaid: lifetimePaid,
    visitsThisMonth: visitsThisMonth,
    monthly: [for (final m in months) MonthEarning(m, monthly[m] ?? 0)],
    topClients: topClients,
  );
});

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

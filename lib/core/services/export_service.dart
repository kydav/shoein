import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/horse.dart';
import 'shoein_repository.dart';

/// Builds CSV exports of the whole book — one file of clients + horses, and one
/// of the full service history (which doubles as an earnings/tax export). Reads
/// a fresh one-shot snapshot from [repo] so the export is complete regardless of
/// what's currently loaded in the UI. Returns the files to share, or null if
/// there's nothing to export yet.
Future<List<XFile>?> buildShoeinExport(ShoeinRepository repo) async {
  final clients = await repo.watchClients().first;
  if (clients.isEmpty) return null;

  final df = DateFormat('yyyy-MM-dd');
  String cost(double? c) => c == null ? '' : c.toStringAsFixed(2);
  String status(DueStatus s) => switch (s) {
    DueStatus.neverServiced => 'Never serviced',
    DueStatus.overdue => 'Overdue',
    DueStatus.dueThisWeek => 'Due this week',
    DueStatus.upcoming => 'Upcoming',
    DueStatus.ok => 'On schedule',
  };

  final clientRows = <List<dynamic>>[
    [
      'Client',
      'Phone',
      'Email',
      'Address',
      'Client Notes',
      'Horse',
      'Breed',
      'Interval (weeks)',
      'Last Service',
      'Next Due',
      'Status',
      'Horse Notes',
    ],
  ];
  final serviceRows = <List<dynamic>>[
    ['Date', 'Client', 'Horse', 'Work Type', 'Cost', 'Paid', 'Notes'],
  ];

  for (final c in clients) {
    final horses = await repo.watchHorses(c.id).first;
    if (horses.isEmpty) {
      clientRows.add([
        c.name,
        c.phone,
        c.email,
        c.address,
        c.notes,
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ]);
    }
    for (final h in horses) {
      clientRows.add([
        c.name,
        c.phone,
        c.email,
        c.address,
        c.notes,
        h.name,
        h.breed,
        h.intervalWeeks,
        h.lastServiceDate == null ? '' : df.format(h.lastServiceDate!),
        h.nextDueDate == null ? '' : df.format(h.nextDueDate!),
        status(h.dueStatus),
        h.notes,
      ]);
      final services = await repo.watchServices(c.id, h.id).first;
      for (final s in services) {
        serviceRows.add([
          df.format(s.date),
          c.name,
          h.name,
          s.workType,
          cost(s.cost),
          s.paid ? 'Yes' : 'No',
          s.notes,
        ]);
      }
    }
  }

  const converter = ListToCsvConverter();
  final today = df.format(DateTime.now());
  final dir = await getTemporaryDirectory();
  final clientsFile = File('${dir.path}/shoein-clients-$today.csv');
  final servicesFile = File('${dir.path}/shoein-service-history-$today.csv');
  await clientsFile.writeAsString(converter.convert(clientRows));
  await servicesFile.writeAsString(converter.convert(serviceRows));

  return [XFile(clientsFile.path), XFile(servicesFile.path)];
}

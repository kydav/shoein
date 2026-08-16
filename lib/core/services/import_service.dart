import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/client.dart';
import 'geocoding_service.dart';
import 'shoein_repository.dart';

/// Writes the client-import template CSV to a temp file and returns it to share.
/// Farriers fill this in a spreadsheet and import it back.
Future<XFile> buildClientImportTemplate() async {
  const converter = ListToCsvConverter();
  final csv = converter.convert([
    ['name', 'phone', 'email', 'address', 'notes'],
    [
      'Willow Creek Ranch',
      '555-0142',
      'barn@willowcreek.com',
      '1200 Ranch Rd, Boulder, CO',
      'Gate code 4412',
    ],
  ]);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/shoein-client-import-template.csv');
  await file.writeAsString(csv);
  return XFile(file.path);
}

/// The result of parsing an import file against the existing book.
class ImportPlan {
  final List<Client> toImport; // new, unique clients (id empty)
  final int duplicates; // skipped — a client with that name already exists
  final int invalid; // skipped — the row had no name
  final bool headerOk; // false if the file has no recognizable "name" column
  const ImportPlan({
    required this.toImport,
    required this.duplicates,
    required this.invalid,
    required this.headerOk,
  });
}

/// Parses [csvContent] (with a header row: name, phone, email, address, notes)
/// into client rows. Skips rows with no name, and de-dupes case-insensitively
/// against [existing] client names and against earlier rows in the same file.
/// Columns are matched by header name, so their order doesn't matter and extra
/// columns are ignored.
ImportPlan planClientImport(String csvContent, List<Client> existing) {
  final normalized = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final rows = const CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(normalized);
  if (rows.isEmpty) {
    return const ImportPlan(
      toImport: [],
      duplicates: 0,
      invalid: 0,
      headerOk: false,
    );
  }

  final header = rows.first
      .map((c) => c.toString().trim().toLowerCase())
      .toList();
  int col(String name) => header.indexOf(name);
  final iName = col('name');
  final iPhone = col('phone');
  final iEmail = col('email');
  final iAddress = col('address');
  final iNotes = col('notes');

  if (iName < 0) {
    return const ImportPlan(
      toImport: [],
      duplicates: 0,
      invalid: 0,
      headerOk: false,
    );
  }

  String cell(List<dynamic> row, int i) =>
      (i >= 0 && i < row.length) ? row[i].toString().trim() : '';

  final existingNames = existing
      .map((c) => c.name.trim().toLowerCase())
      .toSet();
  final seen = <String>{};
  final toImport = <Client>[];
  var duplicates = 0;
  var invalid = 0;

  for (var r = 1; r < rows.length; r++) {
    final row = rows[r];
    final name = cell(row, iName);
    if (name.isEmpty) {
      invalid++;
      continue;
    }
    final key = name.toLowerCase();
    if (existingNames.contains(key) || seen.contains(key)) {
      duplicates++;
      continue;
    }
    seen.add(key);
    toImport.add(
      Client(
        id: '',
        name: name,
        phone: cell(row, iPhone),
        email: cell(row, iEmail),
        address: cell(row, iAddress),
        notes: cell(row, iNotes),
      ),
    );
  }

  return ImportPlan(
    toImport: toImport,
    duplicates: duplicates,
    invalid: invalid,
    headerOk: true,
  );
}

/// Writes the planned clients, geocoding any address first so they land on the
/// map. Geocode failures don't block the import. Reports progress per client.
Future<void> runClientImport(
  ShoeinRepository repo,
  List<Client> clients, {
  void Function(int done, int total)? onProgress,
}) async {
  for (var i = 0; i < clients.length; i++) {
    var client = clients[i];
    if (client.address.trim().isNotEmpty) {
      try {
        final geo = await geocodeAddress(client.address);
        if (geo != null) client = client.copyWith(lat: geo.lat, lng: geo.lng);
      } catch (_) {
        // A bad address shouldn't stop the rest of the import.
      }
    }
    await repo.upsertClient(client);
    onProgress?.call(i + 1, clients.length);
  }
}

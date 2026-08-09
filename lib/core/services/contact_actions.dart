import 'dart:io';

import 'package:shoein/core/models/client.dart';
import 'package:url_launcher/url_launcher.dart';

/// Phone / text / directions actions for a client, shared by the dashboard and
/// the client detail screen.

Future<void> callNumber(String phone) => _launch('tel:$phone');

Future<void> textNumber(String phone) => _launch('sms:$phone');

Future<void> openDirections(Client client) async {
  final scheme = Platform.isIOS ? 'maps' : 'geo';
  if (client.hasLocation) {
    final q = '${client.lat},${client.lng}';
    await _launch('$scheme:$q?q=$q');
  } else if (client.address.isNotEmpty) {
    await _launch('$scheme:0,0?q=${Uri.encodeComponent(client.address)}');
  }
}

Future<void> _launch(String uri) async {
  final u = Uri.parse(uri);
  if (await canLaunchUrl(u)) await launchUrl(u);
}

import 'dart:math';

import 'package:shoein/core/models/client.dart';

/// Great-circle distance between two clients, in kilometers.
double _distanceKm(Client a, Client b) {
  const earthKm = 6371.0;
  final dLat = _rad(b.lat! - a.lat!);
  final dLng = _rad(b.lng! - a.lng!);
  final h =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(a.lat!)) * cos(_rad(b.lat!)) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * earthKm * asin(min(1, sqrt(h)));
}

double _rad(double deg) => deg * pi / 180;

/// Total driving-ish length (straight-line sum) of a route in kilometers.
double routeLengthKm(List<Client> route) {
  var total = 0.0;
  for (var i = 0; i < route.length - 1; i++) {
    total += _distanceKm(route[i], route[i + 1]);
  }
  return total;
}

/// Orders [clients] into a short path visiting each once. Uses
/// nearest-neighbor from the best starting point, then 2-opt refinement.
/// Clients without a location are dropped.
List<Client> optimizeRoute(List<Client> clients) {
  final pts = clients.where((c) => c.hasLocation).toList();
  if (pts.length <= 3) return pts;

  List<Client> best = pts;
  var bestLen = double.infinity;
  for (var start = 0; start < pts.length; start++) {
    final route = _nearestNeighbor(pts, start);
    final len = routeLengthKm(route);
    if (len < bestLen) {
      bestLen = len;
      best = route;
    }
  }
  return _twoOpt(best);
}

List<Client> _nearestNeighbor(List<Client> pts, int start) {
  final remaining = List.of(pts);
  final route = <Client>[remaining.removeAt(start)];
  while (remaining.isNotEmpty) {
    final last = route.last;
    var bestIdx = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < remaining.length; i++) {
      final d = _distanceKm(last, remaining[i]);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    route.add(remaining.removeAt(bestIdx));
  }
  return route;
}

List<Client> _twoOpt(List<Client> route) {
  var best = List.of(route);
  var improved = true;
  while (improved) {
    improved = false;
    for (var i = 1; i < best.length - 1; i++) {
      for (var k = i + 1; k < best.length; k++) {
        final candidate = [
          ...best.sublist(0, i),
          ...best.sublist(i, k + 1).reversed,
          ...best.sublist(k + 1),
        ];
        if (routeLengthKm(candidate) < routeLengthKm(best) - 1e-9) {
          best = candidate;
          improved = true;
        }
      }
    }
  }
  return best;
}

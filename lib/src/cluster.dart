import 'package:google_maps_cluster_manager/src/cluster_item.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Cluster<T extends ClusterItem> {
  final List<T> items;

  Cluster._(this.items);

  factory Cluster.fromItems(List<T> items) => Cluster._(items);

  bool get isMultiple => items.length > 1;

  int get count => items.length;

  LatLng get location => items.first.location;

  List<T> get clusterItems => items;

  LatLngBounds get bounds {
    double? minLat, maxLat, minLng, maxLng;
    for (final item in items) {
      final p = item.location;
      if (minLat == null || p.latitude < minLat) minLat = p.latitude;
      if (maxLat == null || p.latitude > maxLat) maxLat = p.latitude;
      if (minLng == null || p.longitude < minLng) minLng = p.longitude;
      if (maxLng == null || p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  String getId() {
    final ids = items.map((i) => i.geohash).toList()..sort();
    return ids.join('|');
  }
}

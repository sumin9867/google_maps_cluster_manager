import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Minimal ClusterItem contract compatible with google_maps_cluster_manager usage in this app.
abstract class ClusterItem {
  ClusterItem(LatLng position);

  LatLng get location;

  /// Some package code expects a `geohash` getter; provide it here.
  String get geohash;
}

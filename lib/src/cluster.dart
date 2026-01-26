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

  String getId() => items.map((i) => i.geohash).join('|');
}

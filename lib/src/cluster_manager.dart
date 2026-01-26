import 'dart:async';
import 'dart:math' as math;

import 'package:google_maps_cluster_manager/src/cluster.dart';
import 'package:google_maps_cluster_manager/src/cluster_item.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Cluster;

class ClusterManager<T extends ClusterItem> {
  static const int precision = 12;

  final FutureOr<void> Function(Set<Marker>) _updateMarkers;
  Future<Marker> Function(dynamic)? markerBuilder;
  List<T> _items = [];
  int? _mapId;
  CameraPosition? _lastCameraPosition;

  ClusterManager(List<T> items, this._updateMarkers, {this.markerBuilder}) {
    _items = List<T>.from(items);
  }

  void setMapId(int id) {
    _mapId = id;
  }

  void setItems(List<T> items) {
    _items = List<T>.from(items);
  }

  void onCameraMove(CameraPosition position) {
    _lastCameraPosition = position;
  }

  Future<void> updateMap() async {
    if (_items.isEmpty) {
      await _updateMarkers(<Marker>{});
      return;
    }

    final double zoom = _lastCameraPosition?.zoom ?? 13.0;
    final double scale = (256 * math.pow(2, zoom)).toDouble();
    const double clusterSize = 100.0; // Distance threshold in pixels

    double lonToX(double lon) => (lon + 180) / 360 * scale;
    double latToY(double lat) {
      final latRad = lat * math.pi / 180;
      return (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * scale;
    }

    // Spatial Hashing: Grid Map
    final Map<String, List<List<T>>> grid = {};
    final List<List<T>> clusterItems = [];

    for (final item in _items) {
      final x = lonToX(item.location.longitude);
      final y = latToY(item.location.latitude);

      final int gx = (x / clusterSize).floor();
      final int gy = (y / clusterSize).floor();

      List<T>? bestC;
      double minDistance = double.infinity;

      // Check including 8 neighbors
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          final String key = '${gx + i}:${gy + j}';
          final clustersInCell = grid[key];

          if (clustersInCell != null) {
            for (final c in clustersInCell) {
              final seed = c.first;
              final seedX = lonToX(seed.location.longitude);
              final seedY = latToY(seed.location.latitude);
              final distance = math.sqrt(
                math.pow(x - seedX, 2) + math.pow(y - seedY, 2),
              );

              if (distance < clusterSize && distance < minDistance) {
                minDistance = distance;
                bestC = c;
              }
            }
          }
        }
      }

      if (bestC != null) {
        bestC.add(item);
      } else {
        final newCluster = [item];
        clusterItems.add(newCluster);
        final String key = '$gx:$gy';
        grid.putIfAbsent(key, () => []).add(newCluster);
      }
    }

    // Parallel Marker Generation
    final markerFutures = clusterItems.map((group) async {
      final Cluster<T> cluster = Cluster<T>.fromItems(group);
      if (markerBuilder != null) {
        try {
          return await markerBuilder!(cluster);
        } catch (_) {
          return Marker(
            markerId: MarkerId(cluster.getId()),
            position: cluster.location,
          );
        }
      } else {
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
        );
      }
    });

    final markers = (await Future.wait(markerFutures)).toSet();
    await _updateMarkers(markers);
  }
}

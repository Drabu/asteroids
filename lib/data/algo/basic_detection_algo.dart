import 'dart:math';
import 'dart:ui';

import '../../domain/models/collision_algo.dart';

class RayCastingAlgorithm implements CollisionDetectionAlgorithm {
  @override
  bool isCollisionDetected(final List<Offset> vertices,
      final Offset polygonPosition, final Offset point) {
    int intersections = 0;
    for (int i = 0; i < vertices.length; i++) {
      final Offset vertex1 = vertices[i] + polygonPosition;
      final Offset vertex2 =
          vertices[(i + 1) % vertices.length] + polygonPosition;
      if (_rayIntersectsSegment(point, vertex1, vertex2)) {
        intersections++;
      }
    }
    return (intersections % 2) == 1;
  }

  @override
  bool hasCollided(final List<Offset> polygon, final List<Offset> arrow) {
    for (final Offset point in arrow) {
      if (_polygonContainsPoint(polygon, point)) {
        return true;
      }
    }
    return false;
  }

  bool _rayIntersectsSegment(Offset p, Offset v1, Offset v2) {
    if (v1.dy > v2.dy) {
      final Offset temp = v1;
      v1 = v2;
      v2 = temp;
    }
    if (p.dy == v1.dy || p.dy == v2.dy) {
      p = Offset(p.dx, p.dy + 0.1);
    }
    if (p.dy < v1.dy || p.dy > v2.dy || p.dx > max(v1.dx, v2.dx)) {
      return false;
    }
    if (p.dx < min(v1.dx, v2.dx)) {
      return true;
    }
    final double mEdge = (v2.dx - v1.dx) / (v2.dy - v1.dy);
    final double mPoint = (p.dx - v1.dx) / (p.dy - v1.dy);
    return mPoint >= mEdge;
  }

  bool _polygonContainsPoint(final List<Offset> polygon, final Offset point) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length; j++) {
      int i = j == 0 ? polygon.length - 1 : j - 1;
      if (_rayIntersectsSegment(point, polygon[i], polygon[j])) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }
}

import 'dart:ui';

abstract class CollisionDetectionAlgorithm {
  bool isCollisionDetected(final List<Offset> vertices,
      final Offset polygonPosition, final Offset point);

  bool hasCollided(final List<Offset> polygon, final List<Offset> arrow);
}

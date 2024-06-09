import 'dart:ui';

abstract class CollisionDetectionAlgorithm {
  bool hasCollidedWithBullets(final List<Offset> vertices,
      final Offset polygonPosition, final Offset point);

  bool hasCollidedWithPlayer(
      final List<Offset> polygon, final List<Offset> arrow);
}

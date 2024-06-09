import 'dart:ui';

abstract class CollisionDetection {
  bool isCollisionDetected(
      List<Offset> vertices, Offset polygonPosition, Offset point);

  bool hasCollided(List<Offset> polygon, List<Offset> arrow);
}

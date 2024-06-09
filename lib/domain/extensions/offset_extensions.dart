import 'dart:ui';

extension NormalizeOffset on Offset {
  Offset normalize() {
    final double length = distance;
    return this / length;
  }
}

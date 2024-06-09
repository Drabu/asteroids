import 'dart:ui';

extension NormalizeOffset on Offset {
  Offset normalize() {
    final length = distance;
    return this / length;
  }
}

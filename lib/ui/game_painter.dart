import 'dart:math';
import 'package:flutter/material.dart';
import '../domain/models/bullets.dart';
import '../domain/models/particle.dart';

class GamePainter extends CustomPainter {
  final Offset mousePosition;
  final List<Particle> particles;
  final List<Bullet> bullets;
  final bool gameOver;

  GamePainter(
      {required this.mousePosition,
      required this.particles,
      required this.bullets,
      required this.gameOver});

  @override
  void paint(final Canvas canvas, final Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    if (!gameOver) {
      final Paint particlePaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      final Paint bulletPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // Draw particles
      // Draw particles (polygons)
      for (final Particle particle in particles) {
        final Path path = Path();
        for (int i = 0; i < particle.vertices.length; i++) {
          final Offset vertex = particle.vertices[i];
          if (i == 0) {
            path.moveTo(particle.position.dx + vertex.dx,
                particle.position.dy + vertex.dy);
          } else {
            path.lineTo(particle.position.dx + vertex.dx,
                particle.position.dy + vertex.dy);
          }
        }
        path.close();
        canvas.drawPath(path, particlePaint);
      }

      // Draw bullets
      for (final Bullet bullet in bullets) {
        canvas.drawCircle(
            bullet.position, 3, bulletPaint); // Bullet radius set to 5.0
      }

      // Calculate the angle to rotate the cursor
      final double dx = mousePosition.dx - center.dx;
      final double dy = mousePosition.dy - center.dy;
      final double angle = atan2(dy, dx);

      // Define the cursor points
      final Path path = Path()
        ..moveTo(center.dx + 20 * cos(angle), center.dy + 20 * sin(angle))
        ..lineTo(center.dx + 10 * cos(angle + pi * 2 / 3),
            center.dy + 10 * sin(angle + pi * 2 / 3))
        ..lineTo(center.dx, center.dy)
        ..lineTo(center.dx + 10 * cos(angle - pi * 2 / 3),
            center.dy + 10 * sin(angle - pi * 2 / 3))
        ..close();

      // Draw cursor (triangle with connected center line)
      final Paint cursorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawPath(path, cursorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant final GamePainter oldDelegate) {
    return true;
  }
}

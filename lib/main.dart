import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asteriods',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MouseTracker(
        numberOfParticles: 20,
        averageSpeed: 2.0,
      ),
    );
  }
}

class MouseTracker extends StatefulWidget {
  final int numberOfParticles;
  final double averageSpeed;

  const MouseTracker({
    super.key,
    required this.numberOfParticles,
    required this.averageSpeed,
  });

  @override
  MouseTrackerState createState() => MouseTrackerState();
}

class MouseTrackerState extends State<MouseTracker> {
  final List<Bullet> _bullets = [];
  Offset _mousePosition = Offset(50, 50); // Set initial position to be visible
  final List<Particle> _particles = [];
  bool _particlesGenerated = false;
  Timer? _timer;
  bool _gameOver = false;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_particlesGenerated) {
      _generateParticles();
      _particlesGenerated = true;

      // Start a timer to update particle and bullet positions
      _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        _updateParticlesAndBullets();
      });

      // Start the stopwatch
      _stopwatch.start();
    }
  }

  void _generateParticles() {
    final random = Random();
    final screenSize = MediaQuery.of(context).size;

    for (int i = 0; i < widget.numberOfParticles; i++) {
      double size = 20.0 + random.nextDouble() * 30.0;
      Offset position = Offset(
        random.nextDouble() * screenSize.width,
        random.nextDouble() * screenSize.height,
      );
      Offset velocity = Offset(
        (random.nextDouble() - 0.5) * widget.averageSpeed * 2,
        (random.nextDouble() - 0.5) * widget.averageSpeed * 2,
      );
      int numVertices =
          5 + random.nextInt(5); // Random number of vertices between 5 and 10
      List<Offset> vertices = generateRandomPolygon(numVertices, size);
      _particles.add(Particle(vertices, position, velocity));
    }
  }

  List<Offset> generateRandomPolygon(int numVertices, double radius) {
    final random = Random();
    List<Offset> vertices = [];

    for (int i = 0; i < numVertices; i++) {
      double angle = 2 * pi * i / numVertices;
      double distance =
          radius + random.nextDouble() * radius / 2; // Randomize distance
      vertices.add(Offset(distance * cos(angle), distance * sin(angle)));
    }

    return vertices;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatElapsedTime() {
    final elapsed = _stopwatch.elapsed;
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _updateParticlesAndBullets() {
    final screenSize = MediaQuery.of(context).size;
    final center = Offset(screenSize.width / 2, screenSize.height / 2);

    setState(() {
      // Update particles
      for (int i = 0; i < _particles.length; i++) {
        var particle = _particles[i];
        particle.position += particle.velocity;

        // Check bounds and reverse velocity if out of bounds to keep particles on screen
        if (particle.position.dx < 0 ||
            particle.position.dx > screenSize.width) {
          particle.velocity =
              Offset(-particle.velocity.dx, particle.velocity.dy);
        }
        if (particle.position.dy < 0 ||
            particle.position.dy > screenSize.height) {
          particle.velocity =
              Offset(particle.velocity.dx, -particle.velocity.dy);
        }

        // Check for collision with the triangle cursor
        final angle =
            atan2(_mousePosition.dy - center.dy, _mousePosition.dx - center.dx);
        final cursorSize = 20.0;
        final cursorPoints = [
          Offset(center.dx + cursorSize * cos(angle),
              center.dy + cursorSize * sin(angle)),
          Offset(center.dx + cursorSize * cos(angle + 2 * pi / 3),
              center.dy + cursorSize * sin(angle + 2 * pi / 3)),
          Offset(center.dx + cursorSize * cos(angle - 2 * pi / 3),
              center.dy + cursorSize * sin(angle - 2 * pi / 3)),
        ];

        for (var particle in _particles) {
          if (polygonContainsPointArrow(cursorPoints, particle.position)) {
            _gameOver = true;
            _timer?.cancel();
            _stopwatch.stop();
            break;
          }
        }

        // Check for collision with bullets
        for (int j = 0; j < _bullets.length; j++) {
          var bullet = _bullets[j];
          if (polygonContainsPoint(
              particle.vertices, particle.position, bullet.position)) {
            _particles.removeAt(i);
            _bullets.removeAt(j);
            break;
          }
        }
      }

      // Update bullets
      for (var bullet in _bullets) {
        bullet.position += bullet.velocity;
      }
    });
  }

  bool polygonContainsPointArrow(List<Offset> polygon, Offset point) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length; j++) {
      int i = j == 0 ? polygon.length - 1 : j - 1;
      if (rayIntersectsSegment(point, polygon[i], polygon[j])) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  bool polygonContainsPoint(
      List<Offset> vertices, Offset polygonPosition, Offset point) {
    int intersections = 0;
    for (int i = 0; i < vertices.length; i++) {
      final vertex1 = vertices[i] + polygonPosition;
      final vertex2 = vertices[(i + 1) % vertices.length] + polygonPosition;
      if (rayIntersectsSegment(point, vertex1, vertex2)) {
        intersections++;
      }
    }
    return (intersections % 2) == 1;
  }

  bool rayIntersectsSegment(Offset p, Offset v1, Offset v2) {
    if (v1.dy > v2.dy) {
      final temp = v1;
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
    final m_edge = (v2.dx - v1.dx) / (v2.dy - v1.dy);
    final m_point = (p.dx - v1.dx) / (p.dy - v1.dy);
    return m_point >= m_edge;
  }

  void _resetGame() {
    setState(() {
      _mousePosition = Offset(50, 50);
      _particles.clear();
      _particlesGenerated = false;
      _gameOver = false;
      _stopwatch.reset();
      didChangeDependencies();
    });
  }

  void _updateMousePosition(PointerEvent details) {
    setState(() {
      _mousePosition = details.localPosition;
    });
  }

  void _shootBullet() {
    final screenSize = MediaQuery.of(context).size;
    final center = Offset(screenSize.width / 2, screenSize.height / 2);

    // Calculate the direction of the bullet
    final direction = (_mousePosition - center).normalize();

    // Create a new bullet
    final bullet =
        Bullet(center, direction * 5.0); // Adjust the speed as necessary
    setState(() {
      _bullets.add(bullet);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.black, // Set background color to black
            child: MouseRegion(
              onHover: _updateMousePosition,
              onExit: (_) => _mousePosition =
                  Offset.zero, // Reset position when mouse leaves the area
              child: GestureDetector(
                onTap: _shootBullet, // Shoot a bullet on mouse click
                child: CustomPaint(
                  painter: GamePainter(
                      _mousePosition, _particles, _bullets, _gameOver),
                  child: Container(),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Text(
              "Timer : ${_formatElapsedTime()}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_gameOver)
            Container(
              color: Colors.black, // Make the background completely black
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'You lasted for : ${_formatElapsedTime()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 24,
                        ),
                        foregroundColor:
                            Colors.white, // Set text color to white
                      ),
                      onPressed: _resetGame,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Particle {
  List<Offset> vertices;
  Offset position;
  Offset velocity;

  Particle(this.vertices, this.position, this.velocity);
}

class BallPainter extends CustomPainter {
  final Offset mousePosition;
  final List<Particle> particles;
  final bool gameOver;

  BallPainter(this.mousePosition, this.particles, this.gameOver);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    if (!gameOver) {
      final particlePaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      // Draw particles
      for (final particle in particles) {
        canvas.drawCircle(particle.position, 3.0, particlePaint);
      }

      // Draw cursor
      final cursorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // Calculate the angle between the center and the mouse position
      final angle =
          atan2(mousePosition.dy - center.dy, mousePosition.dx - center.dx);

      // Draw a triangle as the cursor
      const double cursorSize = 20.0;
      final path = Path()
        ..moveTo(center.dx + cursorSize * cos(angle),
            center.dy + cursorSize * sin(angle))
        ..lineTo(center.dx + cursorSize * cos(angle + 2 * pi / 3),
            center.dy + cursorSize * sin(angle + 2 * pi / 3))
        ..lineTo(center.dx + cursorSize * cos(angle - 2 * pi / 3),
            center.dy + cursorSize * sin(angle - 2 * pi / 3))
        ..close();

      canvas.drawPath(path, cursorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class GamePainter extends CustomPainter {
  final Offset mousePosition;
  final List<Particle> particles;
  final List<Bullet> bullets;
  final bool gameOver;

  GamePainter(this.mousePosition, this.particles, this.bullets, this.gameOver);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    if (!gameOver) {
      final particlePaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      final bulletPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // Draw particles
      // Draw particles (polygons)
      for (final particle in particles) {
        final path = Path();
        for (int i = 0; i < particle.vertices.length; i++) {
          final vertex = particle.vertices[i];
          final nextVertex =
              particle.vertices[(i + 1) % particle.vertices.length];
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
      for (final bullet in bullets) {
        canvas.drawCircle(
            bullet.position, 3.0, bulletPaint); // Bullet radius set to 5.0
      }

      // Draw the player's triangle
      final angle =
          atan2(mousePosition.dy - center.dy, mousePosition.dx - center.dx);
      final cursorSize = 20.0;
      final path = Path()
        ..moveTo(
          center.dx + cursorSize * cos(angle),
          center.dy + cursorSize * sin(angle),
        )
        ..lineTo(
          center.dx + cursorSize * cos(angle + 2 * pi / 3),
          center.dy + cursorSize * sin(angle + 2 * pi / 3),
        )
        ..lineTo(
          center.dx + cursorSize * cos(angle - 2 * pi / 3),
          center.dy + cursorSize * sin(angle - 2 * pi / 3),
        )
        ..close();

      final playerPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, playerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Bullet {
  Offset position;
  final Offset velocity;

  Bullet(this.position, this.velocity);
}

extension NormalizeOffset on Offset {
  Offset normalize() {
    final length = this.distance;
    return this / length;
  }
}

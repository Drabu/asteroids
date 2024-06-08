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

      // Start a timer to update particle positions
      _timer = Timer.periodic(Duration(milliseconds: 16), (timer) {
        _updateParticles();
      });

      // Start the stopwatch
      _stopwatch.start();
    }
  }

  void _generateParticles() {
    final random = Random();
    const double minSize = 5.0;
    const double maxSize = 30.0;
    final screenSize = MediaQuery.of(context).size;

    for (int i = 0; i < widget.numberOfParticles; i++) {
      double size = minSize + random.nextDouble() * (maxSize - minSize);
      Offset position = Offset(
        random.nextDouble() * screenSize.width,
        random.nextDouble() * screenSize.height,
      );
      Offset velocity = Offset(
        (random.nextDouble() - 0.5) * widget.averageSpeed * 2,
        (random.nextDouble() - 0.5) * widget.averageSpeed * 2,
      );
      _particles.add(Particle(position, size, velocity));
    }
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

  void _updateParticles() {
    final screenSize = MediaQuery.of(context).size;
    final center = Offset(screenSize.width / 2, screenSize.height / 2);

    setState(() {
      for (var particle in _particles) {
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

        if (cursorPoints.any(
            (point) => (point - particle.position).distance < particle.size)) {
          _gameOver = true;
          _timer?.cancel();
          _stopwatch.stop();
        }
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.black, // Set background color to black
            child: MouseRegion(
              onHover: _updateMousePosition,
              child: CustomPaint(
                painter: BallPainter(_mousePosition, _particles, _gameOver),
                child: Container(),
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
  Offset position;
  final double size;
  Offset velocity;

  Particle(this.position, this.size, this.velocity);
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
        canvas.drawCircle(particle.position, particle.size, particlePaint);
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

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

  void _updateParticles() {
    final screenSize = MediaQuery.of(context).size;
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

        // Check for collision with player
        if ((particle.position - _mousePosition).distance <
            particle.size + 10.0) {
          _gameOver = true;
          _timer?.cancel();
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
  final Offset position;
  final List<Particle> particles;
  final bool gameOver;

  BallPainter(this.position, this.particles, this.gameOver);

  @override
  void paint(Canvas canvas, Size size) {
    if (!gameOver) {
      final ballPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final particlePaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      // Draw particles
      for (final particle in particles) {
        canvas.drawCircle(particle.position, particle.size, particlePaint);
      }

      // Draw tracking ball
      canvas.drawCircle(position, 10.0, ballPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

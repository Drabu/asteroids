import 'dart:async';
import 'dart:math';
import 'package:asteriods/domain/extensions/offset_extensions.dart';
import 'package:flutter/material.dart';
import 'data/algo/basic_detection_algo.dart';
import 'domain/models/bullets.dart';
import 'domain/models/collision_algo.dart';
import 'domain/models/particle.dart';
import 'ui/game_painter.dart';

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
      home: MouseTracker(
        numberOfParticles: 30,
        averageSpeed: 2.0,
        cDection: BasicCollisionDetectionImpl(),
      ),
    );
  }
}

class MouseTracker extends StatefulWidget {
  final int numberOfParticles;
  final double averageSpeed;
  final CollisionDetection cDection;

  const MouseTracker({
    super.key,
    required this.numberOfParticles,
    required this.averageSpeed,
    required this.cDection,
  });

  @override
  MouseTrackerState createState() => MouseTrackerState();
}

class MouseTrackerState extends State<MouseTracker> {
  final List<Bullet> _bullets = [];
  Offset _mousePosition = const Offset(50, 50); // Set position
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
          4 + random.nextInt(4); // Random number of vertices between 4 and 8
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
        const cursorSize = 20.0;
        final cursorPoints = [
          Offset(center.dx + cursorSize * cos(angle),
              center.dy + cursorSize * sin(angle)),
          Offset(center.dx + cursorSize * cos(angle + 2 * pi / 3),
              center.dy + cursorSize * sin(angle + 2 * pi / 3)),
          Offset(center.dx + cursorSize * cos(angle - 2 * pi / 3),
              center.dy + cursorSize * sin(angle - 2 * pi / 3)),
        ];

        // Check for collision with player triangle
        if (widget.cDection.hasCollided(
            particle.vertices.map((v) => v + particle.position).toList(),
            cursorPoints)) {
          _gameOver = true;
          _timer?.cancel();
          _stopwatch.stop();
        }

        // Check for collision with bullets
        for (int j = 0; j < _bullets.length; j++) {
          var bullet = _bullets[j];
          if (widget.cDection.isCollisionDetected(
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

  void _resetGame() {
    setState(() {
      _mousePosition = const Offset(50, 50);
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
                      mousePosition: _mousePosition,
                      particles: _particles,
                      bullets: _bullets,
                      gameOver: _gameOver),
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

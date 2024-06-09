import 'dart:async';
import 'dart:math';
import 'package:asteriods/domain/config.dart';
import 'package:asteriods/domain/extensions/offset_extensions.dart';
import 'package:asteriods/domain/models/bullets.dart';
import 'package:asteriods/domain/models/collision_algo.dart';
import 'package:asteriods/domain/models/particle.dart';
import 'package:asteriods/ui/game_painter.dart';
import 'package:flutter/material.dart';

class Playground extends StatefulWidget {
  final int numberOfParticles;
  final double averageSpeed;
  final CollisionDetectionAlgorithm cDection;

  const Playground({
    required this.numberOfParticles,
    required this.averageSpeed,
    required this.cDection,
    super.key,
  });

  @override
  PlaygroundState createState() => PlaygroundState();
}

class PlaygroundState extends State<Playground> {
  final List<Bullet> _bullets = <Bullet>[];
  Offset _mousePosition = const Offset(50, 50); // Set position
  final List<Particle> _particles = <Particle>[];
  bool _particlesGenerated = false;
  Timer? _timer;
  bool _gameOver = false;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            color: Colors.black, // Set background color to black
            child: MouseRegion(
              onHover: _updateMousePosition,
              onExit: (final _) => _mousePosition =
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
              'Timer : ${_formatElapsedTime()}',
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
                  children: <Widget>[
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
                      _getGameTime(),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_particlesGenerated) {
      _generateParticles();
      _particlesGenerated = true;
      // Start a timer to update particle and bullet positions
      _timer =
          Timer.periodic(const Duration(milliseconds: 16), (final Timer timer) {
        _updateParticlesAndBullets();
      });

      // Start the stopwatch
      _stopwatch.start();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateParticles() {
    for (int i = 0; i < widget.numberOfParticles; i++) {
      _particles.add(_genrateParticle());
    }
  }

  List<Offset> generateRandomPolygon(
      final int numVertices, final double radius) {
    final Random random = Random();
    List<Offset> vertices = <Offset>[];

    for (int i = 0; i < numVertices; i++) {
      double angle = 2 * pi * i / numVertices;
      double distance =
          radius + random.nextDouble() * radius / 2; // Randomize distance
      vertices.add(Offset(distance * cos(angle), distance * sin(angle)));
    }

    return vertices;
  }

  void _updateParticlesAndBullets() {
    final Size screenSize = MediaQuery.of(context).size;
    final Offset center = Offset(screenSize.width / 2, screenSize.height / 2);
    setState(() {
      // Update particles
      for (int i = 0; i < _particles.length; i++) {
        Particle particle = _particles[i];
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
        final double angle =
            atan2(_mousePosition.dy - center.dy, _mousePosition.dx - center.dx);
        const double cursorSize = 20;
        final List<Offset> cursorPoints = <Offset>[
          Offset(center.dx + cursorSize * cos(angle),
              center.dy + cursorSize * sin(angle)),
          Offset(center.dx + cursorSize * cos(angle + 2 * pi / 3),
              center.dy + cursorSize * sin(angle + 2 * pi / 3)),
          Offset(center.dx + cursorSize * cos(angle - 2 * pi / 3),
              center.dy + cursorSize * sin(angle - 2 * pi / 3)),
        ];

        // Check for collision with player triangle
        if (widget.cDection.hasCollidedWithPlayer(
            particle.vertices
                .map((final Offset v) => v + particle.position)
                .toList(),
            cursorPoints)) {
          _gameOver = true;
          _timer?.cancel();
          _stopwatch.stop();
        }

        // Check for collision with bullets
        for (int j = 0; j < _bullets.length; j++) {
          Bullet bullet = _bullets[j];
          if (widget.cDection.hasCollidedWithBullets(
              particle.vertices, particle.position, bullet.position)) {
            _particles.removeAt(i);
            _bullets.removeAt(j);
            _particles.add(_genrateParticle());
            break;
          }
        }
      }

      // Update bullets
      for (final Bullet bullet in _bullets) {
        bullet.position += bullet.velocity;
      }
    });
  }

  Particle _genrateParticle() {
    final Random random = Random();
    final Size screenSize = MediaQuery.of(context).size;
    double size =
        PlaygroundConfiguration.particleBaseSize + random.nextDouble() * 30.0;
    final Offset center = Offset(screenSize.width / 2, screenSize.height / 2);

    Offset position;
    do {
      position = Offset(
        random.nextDouble() * screenSize.width,
        random.nextDouble() * screenSize.height,
      );
    } while (
        (position - center).distance < PlaygroundConfiguration.safeZoneRadius);

    Offset velocity = Offset(
      (random.nextDouble() - 0.5) * widget.averageSpeed * 2,
      (random.nextDouble() - 0.5) * widget.averageSpeed * 2,
    );
    int numVertices =
        4 + random.nextInt(4); // Random number of vertices between 4 and 8
    List<Offset> vertices = generateRandomPolygon(numVertices, size);
    return Particle(vertices, position, velocity);
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

  void _updateMousePosition(final PointerEvent details) {
    setState(() {
      _mousePosition = details.localPosition;
    });
  }

  void _shootBullet() {
    final Size screenSize = MediaQuery.of(context).size;
    final Offset center = Offset(screenSize.width / 2, screenSize.height / 2);

    // Calculate the direction of the bullet
    final Offset direction = (_mousePosition - center).normalize();

    // Create a new bullet
    final Bullet bullet = Bullet(
        center,
        direction *
            PlaygroundConfiguration
                .bulletVelocity); // Adjust the speed as necessary
    setState(() {
      _bullets.add(bullet);
    });
  }

  String _formatElapsedTime() {
    final Duration elapsed = _stopwatch.elapsed;
    final int minutes = elapsed.inMinutes;
    final int seconds = elapsed.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getGameTime() {
    final Duration elapsed = _stopwatch.elapsed;
    final int minutes = elapsed.inMinutes;
    final int seconds = elapsed.inSeconds % 60;

    if (minutes > 0) {
      return 'You lasted for $minutes minute${minutes > 1 ? 's' : ''} and $seconds second${seconds != 1 ? 's' : ''}';
    } else {
      return 'You lasted for $seconds second${seconds != 1 ? 's' : ''}';
    }
  }
}

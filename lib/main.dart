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
      home: const MouseTracker(),
    );
  }
}

class MouseTracker extends StatefulWidget {
  const MouseTracker({super.key});

  @override
  MouseTrackerState createState() => MouseTrackerState();
}

class MouseTrackerState extends State<MouseTracker> {
  Offset _mousePosition = Offset(50, 50); // Set initial position to be visible
  final List<Particle> _particles = [];
  bool _particlesGenerated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_particlesGenerated) {
      _generateParticles();
      _particlesGenerated = true;
    }
  }

  void _generateParticles() {
    final random = Random();
    const int particleCount = 30;
    const double minSize = 5.0;
    const double maxSize = 30.0;

    for (int i = 0; i < particleCount; i++) {
      double size = minSize + random.nextDouble() * (maxSize - minSize);
      Offset position = Offset(
        random.nextDouble() * MediaQuery.of(context).size.width,
        random.nextDouble() * MediaQuery.of(context).size.height,
      );
      _particles.add(Particle(position, size));
    }
  }

  void _updateMousePosition(PointerEvent details) {
    setState(() {
      _mousePosition = details.localPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black, // Set background color to black
        child: MouseRegion(
          onHover: _updateMousePosition,
          child: CustomPaint(
            painter: BallPainter(_mousePosition, _particles),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class Particle {
  final Offset position;
  final double size;

  Particle(this.position, this.size);
}

class BallPainter extends CustomPainter {
  final Offset position;
  final List<Particle> particles;

  BallPainter(this.position, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

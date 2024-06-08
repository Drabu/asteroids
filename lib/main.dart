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
  Offset _mousePosition = Offset.zero;

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
            painter: BallPainter(_mousePosition),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class BallPainter extends CustomPainter {
  final Offset position;

  BallPainter(this.position);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 10.0, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

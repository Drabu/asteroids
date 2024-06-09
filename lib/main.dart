import 'package:asteriods/domain/config.dart';
import 'package:asteriods/ui/widgets/playground_widget.dart';
import 'package:flutter/material.dart';
import 'data/algo/ray_casting_algo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      title: 'Asteriods',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Playground(
        numberOfParticles: PlaygroundConfiguration.numberOfParticles,
        averageSpeed: PlaygroundConfiguration.particleAverageSpeed,
        cDection: PlaygroundConfiguration.rayCastingAlgo,
      ),
    );
  }
}

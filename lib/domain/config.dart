import 'package:asteriods/data/algo/ray_casting_algo.dart';
import 'package:asteriods/domain/models/collision_algo.dart';
import 'package:flutter/material.dart';

class PlaygroundConfiguration {
  static const int numberOfParticles = 30;
  static const double particleAverageSpeed = 2;
  static const double particleBaseSize = 30;

  static const MaterialColor particleColor = Colors.red;
  static const Color bulletColor = Colors.white;

  static const double bulletRadius = 3;
  static const double bulletVelocity = 5;

  static const double safeZoneRadius = 100;
  static CollisionDetectionAlgorithm rayCastingAlgo = RayCastingAlgorithm();
}

import 'package:flutter/material.dart';

class DetectionResult {
  final int id;
  final String pose;
  final double confidence;
  final Color poseColor;

  const DetectionResult({
    required this.id,
    required this.pose,
    required this.confidence,
    required this.poseColor,
  });
}

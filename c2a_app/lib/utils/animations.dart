// Simple no-op animation wrappers replacing animate_do package
// These just display the child widget directly without animation
import 'package:flutter/material.dart';

class FadeInUp extends StatelessWidget {
  final Widget child;
  final Duration? delay;
  final Duration? duration;
  const FadeInUp({super.key, required this.child, this.delay, this.duration});
  @override
  Widget build(BuildContext context) => child;
}

class FadeInDown extends StatelessWidget {
  final Widget child;
  final Duration? delay;
  final Duration? duration;
  const FadeInDown({super.key, required this.child, this.delay, this.duration});
  @override
  Widget build(BuildContext context) => child;
}

class FadeInRight extends StatelessWidget {
  final Widget child;
  final Duration? delay;
  final Duration? duration;
  const FadeInRight({super.key, required this.child, this.delay, this.duration});
  @override
  Widget build(BuildContext context) => child;
}

class FadeInLeft extends StatelessWidget {
  final Widget child;
  final Duration? delay;
  final Duration? duration;
  const FadeInLeft({super.key, required this.child, this.delay, this.duration});
  @override
  Widget build(BuildContext context) => child;
}

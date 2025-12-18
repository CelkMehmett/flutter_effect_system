import 'package:flutter/material.dart';
import '../effect.dart';

/// TrailEffect - creates a trailing effect behind the widget
/// Useful for motion-based UI elements
class TrailEffect implements Effect {
  @override
  final Duration duration;
  
  final int trailLength;
  final Color trailColor;
  final double opacity;

  const TrailEffect({
    this.trailLength = 5,
    this.trailColor = Colors.white,
    this.opacity = 0.5,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  void apply(EffectContext context, double t) {
    // Trail fades out as t progresses
    final fadeOut = 1.0 - t;
    final trailOpacity = opacity * fadeOut;

    context.addOpacity(1.0 - trailOpacity * 0.3);

    // Add slight offset based on progress
    final dx = -10.0 * t * fadeOut;
    context.addOffset(Offset(dx, 0));
  }
}

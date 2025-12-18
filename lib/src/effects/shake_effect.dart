import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../effect.dart';

/// ShakeEffect: randomized offset shake with intensity decay (ease-out).
///
/// Produces short randomized translation offsets. `intensity` is in logical
/// pixels; `duration` is the effect lifetime.
class ShakeEffect implements Effect {
  @override
  final Duration duration;

  /// Peak intensity in logical pixels.
  final double intensity;

  /// Frequency multiplier controls jitter speed.
  final double frequency;

  /// Optional seed for deterministic shakes.
  final int seed;

  ShakeEffect({
    this.intensity = 8.0,
    this.duration = const Duration(milliseconds: 300),
    this.frequency = 40.0,
    this.seed = 0,
  });

  double _easeOut(double t) => 1 - math.pow(1 - t, 2).toDouble();

  @override
  void apply(EffectContext context, double t) {
    if (t <= 0.0) return;
    final e = _easeOut(t);
    // time-based pseudo-random but deterministic using sin/cos
    final progress = t * frequency * math.pi * 2;
    final dx = math.sin(progress * 1.0 + seed) * (intensity * (1 - e));
    final dy = math.cos(progress * 1.3 + seed * 7) * (intensity * (1 - e));

    context.addOffset(Offset(dx, dy));
  }
}

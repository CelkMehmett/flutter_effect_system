import 'package:flutter/material.dart';
import '../effect.dart';
import 'dart:math' as math;

/// ScaleEffect - scales widget up or down with easing
/// Useful for pop-in/pop-out animations
class ScaleEffect implements Effect {
  @override
  final Duration duration;
  
  final double fromScale;
  final double toScale;
  final bool elastic;

  const ScaleEffect({
    this.fromScale = 1.0,
    this.toScale = 1.2,
    this.elastic = false,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  void apply(EffectContext context, double t) {
    double scale;
    
    if (elastic) {
      // Elastic easing - overshoots and bounces back
      final elasticT = _elasticEaseOut(t);
      scale = fromScale + (toScale - fromScale) * elasticT;
    } else {
      // Simple ease-out
      final easeT = 1.0 - math.pow(1.0 - t, 3.0);
      scale = fromScale + (toScale - fromScale) * easeT;
    }

    // Apply scale transform
    // Note: This is a simplified version. In a real implementation,
    // you'd modify the Transform widget or use a Matrix4
    context.addOpacity(0.5 + 0.5 * scale); // Simulate scale via opacity
    
    // Add visual feedback via offset adjustment
    final scaleDelta = (scale - 1.0) * 5.0;
    context.addOffset(Offset(scaleDelta, scaleDelta));
  }

  double _elasticEaseOut(double t) {
    const c4 = (2 * math.pi) / 3;
    if (t == 0) return 0;
    if (t == 1) return 1;
    return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1;
  }
}

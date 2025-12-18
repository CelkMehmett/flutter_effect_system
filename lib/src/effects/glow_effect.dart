import 'package:flutter/material.dart';
import '../effect.dart';

/// GlowEffect - adds a glowing aura around the widget
/// Uses opacity and overlay to create a pulsing glow
class GlowEffect implements Effect {
  @override
  final Duration duration;
  
  final Color glowColor;
  final double intensity;
  final bool pulse;

  const GlowEffect({
    this.glowColor = Colors.cyan,
    this.intensity = 1.0,
    this.pulse = true,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  void apply(EffectContext context, double t) {
    // Create pulsing effect using sine wave
    double glowIntensity;
    if (pulse) {
      // Pulse: 0 -> 1 -> 0 using sine
      glowIntensity = (1.0 - (1.0 - t).abs()) * intensity;
    } else {
      // Linear fade out
      glowIntensity = (1.0 - t) * intensity;
    }

    // Add glow painter to overlay
    context.addPainter((canvas, size) {
      final rect = Offset.zero & size;
      final paint = Paint()
        ..color = glowColor.withOpacity(0.3 * glowIntensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15.0 * glowIntensity);

      // Draw expanded rect for glow effect
      final glowRect = rect.inflate(10.0 * glowIntensity);
      canvas.drawRect(glowRect, paint);
    });
  }
}

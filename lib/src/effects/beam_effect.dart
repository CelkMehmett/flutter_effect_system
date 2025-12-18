import 'package:flutter/material.dart';
import '../effect.dart';
import 'dart:math' as math;

/// BeamEffect - creates a beam/laser effect from center
/// Useful for hit effects or laser animations
class BeamEffect implements Effect {
  @override
  final Duration duration;
  
  final Color beamColor;
  final double width;
  final Offset direction;

  const BeamEffect({
    this.beamColor = Colors.yellowAccent,
    this.width = 4.0,
    this.direction = const Offset(1.0, 0.0), // right by default
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  void apply(EffectContext context, double t) {
    // Beam extends and fades out
    final beamLength = t;
    final beamOpacity = 1.0 - t;

    context.addPainter((canvas, size) {
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      final center = Offset(centerX, centerY);

      // Normalize direction
      final dirLength = math.sqrt(
        direction.dx * direction.dx + direction.dy * direction.dy,
      );
      final normalizedDir = direction / dirLength;

      // Calculate beam end point
      final maxLength = math.max<double>(size.width, size.height);
      final endPoint = center + normalizedDir * maxLength * beamLength;

      final paint = Paint()
        ..color = beamColor.withOpacity(beamOpacity)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Draw beam with glow
      final glowPaint = Paint()
        ..color = beamColor.withOpacity(beamOpacity * 0.3)
        ..strokeWidth = width * 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

      canvas.drawLine(center, endPoint, glowPaint);
      canvas.drawLine(center, endPoint, paint);
    });
  }
}

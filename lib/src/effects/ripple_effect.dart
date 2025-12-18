import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../effect.dart';

/// RippleEffect: expanding circle from a center point with opacity falloff.
///
/// Draws a filled expanding circle at a given normalized center (or canvas
/// center by default). The effect eases out and fades the overlay color as
/// it expands. Designed to be lightweight and use an overlay painter.
class RippleEffect implements Effect {
  @override
  final Duration duration;

  /// Center in normalized coordinates (0..1). If null, center of the canvas is used.
  final Offset? center;

  final Color color;
  final double maxRadiusFraction; // fraction of max(size.width,size.height)

  final int seed;

  RippleEffect({
    this.duration = const Duration(milliseconds: 600),
    this.center,
    this.color = Colors.white,
    this.maxRadiusFraction = 0.9,
    this.seed = 0,
  });

  double _easeOut(double t) => 1 - math.pow(1 - t, 2).toDouble();

  @override
  void apply(EffectContext context, double t) {
    if (t <= 0) return;
    final e = _easeOut(t);
    final alpha = (1.0 - e).clamp(0.0, 1.0);

    // add a painter that draws the expanding ring / filled circle with falloff
    context.addPainter((canvas, size) {
      final centerPoint = center != null
          ? Offset(center!.dx * size.width, center!.dy * size.height)
          : size.center(Offset.zero);

      final maxR = math.max(size.width, size.height) * maxRadiusFraction;
      final r = e * maxR;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withAlpha((alpha * 200).clamp(0, 255).toInt());

      // draw soft circle by using drawCircle; for more soft falloff a shader or
      // radial gradient could be used — keep MVP simple and fast.
      canvas.drawCircle(centerPoint, r, paint);
    });
  }
}

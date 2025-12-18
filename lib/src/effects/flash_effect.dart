import 'package:flutter/material.dart';
import '../effect.dart';

/// FlashEffect: draws a full-screen colored overlay that fades out.
///
/// Use to show short hit/flash feedback. Supports configurable [color]
/// and [blendMode].
class FlashEffect implements Effect {
  @override
  final Duration duration;

  final Color color;
  final BlendMode blendMode;

  FlashEffect({
    this.color = Colors.white,
    this.duration = const Duration(milliseconds: 120),
    this.blendMode = BlendMode.srcOver,
  });

  double _easeOut(double t) => 1 - (1 - t) * (1 - t);

  @override
  void apply(EffectContext context, double t) {
    if (t <= 0) return;
    final alpha = (1.0 - _easeOut(t)).clamp(0.0, 1.0);

    // Add a painter that fills the whole canvas with color * alpha.
    context.addPainter((canvas, size) {
      final a = (alpha * 255).clamp(0, 255).toInt();
      final paint = Paint()
        ..color = color.withAlpha(a)
        ..blendMode = blendMode;
      canvas.drawRect(Offset.zero & size, paint);
    });
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../effect.dart';

/// ParticleEffect (MVP): lightweight particle burst with deterministic seed.
///
/// A minimal particle burst effect suitable for UI hits and impacts. Particles
/// parameters are precomputed deterministically from the supplied [seed] so
/// visuals are stable and cheap at runtime. Rendering uses an overlay painter
/// and a small blur for softer visuals.
class ParticleEffect implements Effect {
  @override
  final Duration duration;

  final int count;
  final Color color;
  final double minSize;
  final double maxSize;
  final double speed; // pixels per normalized lifetime
  final int seed;

  ParticleEffect({
    this.duration = const Duration(milliseconds: 800),
    this.count = 24,
    this.color = Colors.orange,
    this.minSize = 2.0,
    this.maxSize = 6.0,
    this.speed = 300.0,
    this.seed = 0,
  });

  /// Global cap for particles per-effect. Lower this to reduce rendering
  /// cost when many particle effects may be stacked. This is intentionally
  /// a simple per-effect clamp to avoid cross-effect coordination complexity
  /// in the MVP. Set to a lower value on low-end devices.
  static int globalParticleCap = 200;

  /// Global shared particle budget per frame. `EffectLayer` resets this at
  /// the start of each frame. Particle effects will `consumeBudget` when
  /// they apply so stacked effects share this budget.
  static int globalParticleBudget = 400;
  static int _budgetRemaining = globalParticleBudget;

  /// Called by host to reset the per-frame budget. EffectLayer calls this
  /// at the start of each tick.
  static void resetBudget() {
    _budgetRemaining = globalParticleBudget;
  }

  static int consumeBudget(int want) {
    final gave = math.min(want, _budgetRemaining);
    _budgetRemaining -= gave;
    return gave;
  }

  // Precompute per-particle immutable parameters for performance and
  // deterministic visuals.
  late final List<_Particle> _particles = List.generate(math.min(count, globalParticleCap), (i) {
    final rng = _SimpleRng(seed + i + 1);
    final ang = rng.nextDouble() * math.pi * 2;
    final sizePx = minSize + rng.nextDouble() * (maxSize - minSize);
    final speedFactor = 0.5 + rng.nextDouble() * 0.5;
    return _Particle(angle: ang, size: sizePx, speedFactor: speedFactor);
  });

  double _easeOut(double t) => 1 - math.pow(1 - t, 2).toDouble();

  @override
  void apply(EffectContext context, double t) {
    if (t <= 0) return;
    final e = _easeOut(t);

    // Determine how many particles we may draw this frame by consuming from
    // the shared per-frame budget. This ensures stacked particle effects
    // don't explode render cost.
    final allowed = consumeBudget(_particles.length);
    if (allowed <= 0) return;

    final seconds = duration.inMilliseconds / 1000.0;

    // Create a painter that draws up to [allowed] particles from the
    // precomputed list.
    context.addPainter((canvas, size) {
      final center = size.center(Offset.zero);
      for (int i = 0; i < allowed; i++) {
        final p = _particles[i];
        final sp = p.speedFactor * speed;
        final distance = sp * e * seconds;
        final dx = math.cos(p.angle) * distance;
        final dy = math.sin(p.angle) * distance;

        // particles shrink slightly and fade out over time
        final drawSize = p.size * (1.0 - 0.4 * e);
        final alpha = ((1.0 - e) * 255).clamp(0, 255).toInt();
        final paint = Paint()
          ..color = color.withAlpha(alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

        canvas.drawCircle(center + Offset(dx, dy), drawSize, paint);
      }
    });
  }
}

/// Very small deterministic RNG. Not cryptographic — used to generate
/// deterministic per-effect particle initial directions and sizes.
class _SimpleRng {
  int _state;
  _SimpleRng(int seed) : _state = seed == 0 ? 0xC0FFEE : seed & 0x7FFFFFFF;

  int nextInt() {
    // 32-bit LCG
    _state = (1664525 * _state + 1013904223) & 0x7FFFFFFF;
    return _state;
  }

  double nextDouble() => (nextInt() & 0x7FFFFFFF) / 0x7FFFFFFF;
}

class _Particle {
  final double angle;
  final double size;
  final double speedFactor;
  const _Particle({required this.angle, required this.size, required this.speedFactor});
}

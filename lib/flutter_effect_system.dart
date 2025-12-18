/// flutter_effect_system
///
/// A small, declarative effect orchestration package for Flutter. Exposes a
/// compact public API for defining, composing and triggering frame-driven
/// visual effects (shake, flash, ripple, particles) without relying on an
/// external game loop or physics engine.
library flutter_effect_system;

/// Public API for flutter_effect_system
export 'src/effect.dart';
export 'src/effect_layer.dart';
export 'src/effects/shake_effect.dart';
export 'src/effects/flash_effect.dart';
export 'src/effects/ripple_effect.dart';
export 'src/effects/particle_effect.dart';
export 'src/effects/trail_effect.dart';
export 'src/effects/glow_effect.dart';
export 'src/effects/beam_effect.dart';
export 'src/effects/scale_effect.dart';

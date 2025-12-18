import 'package:flutter/widgets.dart';

/// Base Effect abstraction.
///
/// Effects are stateless, frame-driven visual modifiers. Each effect exposes
/// a [duration] and an [apply] method that the host will call every frame
/// with a normalized progress value `t` in [0,1]. Effects should be
/// allocation-conscious and use the provided [EffectContext] to request
/// transforms, opacity, and overlay painters.
abstract class Effect {
  /// Total duration of the effect.
  Duration get duration;

  /// Apply effect logic for the given normalized progress `t` in [0,1].
  ///
  /// The implementation must be idempotent for the same `t` and should only
  /// mutate the passed [EffectContext]. Keep logic fast and avoid per-frame
  /// allocations where possible.
  void apply(EffectContext context, double t);
}

/// Context passed into effects each frame.
///
/// Effects mutate this context to request visual changes that the host will
/// composite when painting. The host will call [clear] at the start of each
/// frame; effects should only call the `add*` helpers.
class EffectContext {
  Offset _offset = Offset.zero;
  double _opacity = 1.0;
  final List<OverlayPainter> _painters = [];

  /// Adds a translation offset requested by the effect.
  void addOffset(Offset offset) {
    _offset = _offset + offset;
  }

  /// Multiplies the current opacity by [opacity]. Values are clamped to 0..1.
  void addOpacity(double opacity) {
    _opacity = (_opacity * opacity).clamp(0.0, 1.0);
  }

  /// Adds a custom overlay painter. The painter will be invoked during the
  /// overlay paint pass with the canvas and size.
  void addPainter(OverlayPainter painter) {
    _painters.add(painter);
  }

  /// Snapshot of the current accumulated offset (internal use by host).
  Offset get accumulatedOffset => _offset;

  /// Snapshot of the current accumulated opacity (internal use by host).
  double get accumulatedOpacity => _opacity;

  /// List of painters to run this frame (internal use by host).
  List<OverlayPainter> get painters => _painters;

  /// Clears internal accumulators. Called by the host each frame.
  void clear() {
    _offset = Offset.zero;
    _opacity = 1.0;
    _painters.clear();
  }
}

/// Painter type used by effects to draw overlays above the child.
typedef OverlayPainter = void Function(Canvas canvas, Size size);

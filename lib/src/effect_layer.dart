import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'effect.dart';
// Import the particle implementation to reset the shared per-frame budget.
// We import the internal src file because the budget manager is an
// implementation detail of ParticleEffect.
import 'effects/particle_effect_clean.dart';
import 'performance_utils.dart';

/// Controller to trigger effects at runtime.
///
/// Use [play] to trigger a one-shot effect at runtime. The controller is
/// attached to a single [EffectLayer] via an internal attach/detach API.
class EffectController {
  void Function(Effect)? _playHandler;
  void Function()? _clearHandler;

  /// Attach internal play handler (used by EffectLayer).
  @protected
  void attach(void Function(Effect) handler, void Function() clearHandler) {
    _playHandler = handler;
    _clearHandler = clearHandler;
  }

  @protected
  void detach() {
    _playHandler = null;
    _clearHandler = null;
  }

  /// Trigger an effect to play immediately.
  void play(Effect effect) {
    _playHandler?.call(effect);
  }

  /// Clear all active effects immediately.
  void clearAll() {
    _clearHandler?.call();
  }
}

class _ActiveEffect {
  final Effect effect;
  final Duration start;

  _ActiveEffect(this.effect, this.start);
}

/// Widget that wraps a child and applies declarative, frame-driven effects.
///
/// The layer accepts a set of declarative `effects` that will be scheduled
/// when the widget is first built, and an optional [EffectController] for
/// runtime triggers. It composes transform and overlay requests produced by
/// effects each frame.
class EffectLayer extends StatefulWidget {
  final Widget child;
  final List<Effect> effects;
  final EffectController? controller;

  const EffectLayer({
    Key? key,
    required this.child,
    this.effects = const [],
    this.controller,
  }) : super(key: key);

  @override
  State<EffectLayer> createState() => _EffectLayerState();
}

class _EffectLayerState extends State<EffectLayer>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final Ticker _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  final List<_ActiveEffect> _active = [];
  final EffectContext _context = EffectContext();
  int _tickId = 0; // simple repaint trigger

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    // seed initial effects
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = _stopwatch.isRunning ? _stopwatch.elapsed : Duration.zero;
      for (final e in widget.effects) {
        _startEffect(e, now);
      }
    });
    widget.controller?.attach(_startEffectFromController, _clearAllEffects);
  }

  void _startEffectFromController(Effect e) {
    _startEffect(e, _stopwatch.elapsed);
  }

  void _clearAllEffects() {
    _active.clear();
    setState(() {});
  }

  void _startEffect(Effect effect, Duration now) {
    // start stopwatch + ticker if needed
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
    if (!_ticker.isActive) _ticker.start();
    _active.add(_ActiveEffect(effect, now));
    // quick repaint
    setState(() {});
  }

  void _onTick(Duration tick) {
    // tick is time since ticker started; we rely on _stopwatch for timebase
    // Reset per-frame shared particle budget so stacked ParticleEffects
    // fairly share the budget each frame.
    ParticleEffect.resetBudget();

    // Record frame time for adaptive quality management
    final frameStart = DateTime.now();

    if (_active.isEmpty) {
      _ticker.stop();
      _stopwatch.stop();
      _stopwatch.reset();
      return;
    }

    _context.clear();
    final now = _stopwatch.elapsed;
    final toRemove = <_ActiveEffect>[];

    for (final ae in _active) {
      final elapsed = now - ae.start;
      final dur = ae.effect.duration;
      final t = dur.inMilliseconds > 0
          ? (elapsed.inMilliseconds / dur.inMilliseconds)
          : 1.0;
      final tc = t.clamp(0.0, 1.0);
      try {
        ae.effect.apply(_context, tc);
      } catch (err, st) {
        // swallow effect errors to avoid crashing the layer
        FlutterError.reportError(FlutterErrorDetails(exception: err, stack: st));
      }
      if (t >= 1.0) toRemove.add(ae);
    }

    // remove finished
    for (final r in toRemove) {
      _active.remove(r);
    }

    // Record frame time for performance monitoring
    final frameTime = DateTime.now().difference(frameStart);
    AdaptiveQualityManager.recordFrameTime(frameTime);

    // trigger repaint with new accumulators
    _tickId = (_tickId + 1) & 0x3fffffff;
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant EffectLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(_startEffectFromController, _clearAllEffects);
    }
    // If provided effects list changed we start any new ones.
    if (!listEquals(oldWidget.effects, widget.effects)) {
      final now = _stopwatch.isRunning ? _stopwatch.elapsed : Duration.zero;
      for (final e in widget.effects) {
        // simple: always (re)start provided effects on update
        _startEffect(e, now);
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.controller?.detach();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => _active.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Compose child with transform + overlay painters.
    final offset = _context.accumulatedOffset;
    final opacity = _context.accumulatedOpacity;
    final painters = List<OverlayPainter>.from(_context.painters);

    Widget content = widget.child;

    // apply translation (shake) cheaply
    if (offset != Offset.zero) {
      content = Transform.translate(offset: offset, child: content);
    }

    // apply opacity if needed
    if (opacity < 0.9999) {
      content = Opacity(opacity: opacity, child: content);
    }

    // overlay painters via CustomPaint
    if (painters.isNotEmpty) {
      content = Stack(children: [content, Positioned.fill(child: _Overlay(painters: painters, tickId: _tickId))]);
    }

    // RepaintBoundary to minimize repaints in ancestor tree.
    return RepaintBoundary(child: content);
  }
}

class _Overlay extends LeafRenderObjectWidget {
  final List<OverlayPainter> painters;
  final int tickId;

  const _Overlay({Key? key, required this.painters, required this.tickId}) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderOverlay(painters, tickId);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderOverlay renderObject) {
    renderObject..painters = painters..tickId = tickId;
  }
}

class _RenderOverlay extends RenderBox {
  List<OverlayPainter> painters;
  int tickId;

  _RenderOverlay(this.painters, this.tickId);

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    for (final p in painters) {
      try {
        p(canvas, size);
      } catch (err, st) {
        FlutterError.reportError(FlutterErrorDetails(exception: err, stack: st));
      }
    }
  }
}

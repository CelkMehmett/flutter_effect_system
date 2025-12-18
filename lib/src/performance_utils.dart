import 'package:flutter/material.dart';

/// Performance optimization utilities for effects
class EffectPerformance {
  /// Auto-detect device capability and return recommended particle cap
  static int getRecommendedParticleCap() {
    // In a real implementation, this would check device specs
    // For now, provide conservative defaults
    return 150;
  }

  /// Frame skip manager for low-end devices
  static bool shouldSkipFrame(int frameCount) {
    // Skip every 3rd frame on budget devices
    return frameCount % 3 == 0;
  }
}

/// Particle pool for reusing particle instances
class ParticlePool {
  static final List<_PooledParticle> _pool = [];
  static const int maxPoolSize = 500;

  static _PooledParticle acquire(double x, double y, double vx, double vy) {
    if (_pool.isNotEmpty) {
      final particle = _pool.removeLast();
      particle.reset(x, y, vx, vy);
      return particle;
    }
    return _PooledParticle(x, y, vx, vy);
  }

  static void release(_PooledParticle particle) {
    if (_pool.length < maxPoolSize) {
      _pool.add(particle);
    }
  }

  static void clear() {
    _pool.clear();
  }
}

class _PooledParticle {
  double x;
  double y;
  double vx;
  double vy;
  double life = 1.0;

  _PooledParticle(this.x, this.y, this.vx, this.vy);

  void reset(double newX, double newY, double newVx, double newVy) {
    x = newX;
    y = newY;
    vx = newVx;
    vy = newVy;
    life = 1.0;
  }

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    life -= dt;
  }
}

/// Device capability detector
class DeviceCapability {
  static DevicePerformanceLevel _cached = DevicePerformanceLevel.medium;
  static bool _detected = false;

  static DevicePerformanceLevel get level {
    if (!_detected) {
      _detect();
    }
    return _cached;
  }

  static void _detect() {
    // Simple heuristic based on platform
    // In production, this would use actual device metrics
    _cached = DevicePerformanceLevel.medium;
    _detected = true;
  }

  static int getParticleCapForLevel(DevicePerformanceLevel level) {
    switch (level) {
      case DevicePerformanceLevel.high:
        return 300;
      case DevicePerformanceLevel.medium:
        return 150;
      case DevicePerformanceLevel.low:
        return 80;
    }
  }

  static double getQualityMultiplierForLevel(DevicePerformanceLevel level) {
    switch (level) {
      case DevicePerformanceLevel.high:
        return 1.0;
      case DevicePerformanceLevel.medium:
        return 0.75;
      case DevicePerformanceLevel.low:
        return 0.5;
    }
  }
}

enum DevicePerformanceLevel {
  high,
  medium,
  low,
}

/// Adaptive quality manager that adjusts effect quality based on performance
class AdaptiveQualityManager {
  static double _currentQuality = 1.0;
  static int _frameTimeSum = 0;
  static int _frameCount = 0;
  static const int _measurementWindow = 60; // frames

  static double get quality => _currentQuality;

  static void recordFrameTime(Duration frameTime) {
    _frameTimeSum += frameTime.inMicroseconds;
    _frameCount++;

    if (_frameCount >= _measurementWindow) {
      final avgFrameTime = _frameTimeSum / _frameCount;
      _adjustQuality(avgFrameTime);
      _frameTimeSum = 0;
      _frameCount = 0;
    }
  }

  static void _adjustQuality(double avgFrameTimeMicros) {
    // Target: 60 FPS = ~16666 microseconds per frame
    const targetFrameTime = 16666.0;
    
    if (avgFrameTimeMicros > targetFrameTime * 1.5) {
      // Running slow, reduce quality
      _currentQuality = (_currentQuality * 0.9).clamp(0.3, 1.0);
    } else if (avgFrameTimeMicros < targetFrameTime * 0.8) {
      // Running fast, can increase quality
      _currentQuality = (_currentQuality * 1.05).clamp(0.3, 1.0);
    }
  }

  static int adjustParticleCount(int requested) {
    return (requested * _currentQuality).round().clamp(1, requested);
  }
}

# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2025-12-18

### Added
- **New Effects**: TrailEffect, GlowEffect, BeamEffect, ScaleEffect
- **Performance Optimizations**: 
  - Particle pooling system for memory efficiency
  - Adaptive quality manager that adjusts based on frame time
  - Device capability detection for automatic performance tuning
  - Frame-time tracking for performance monitoring
- **Enhanced Testing**: 
  - Comprehensive widget tests for EffectController
  - Effect composition tests
  - Overlay painter registration tests
  - Effect lifecycle and duration tests
  - Test coverage reporting
- **Controller Enhancements**: Added `clearAll()` method to EffectController

### Changed
- Improved performance for particle effects on low-end devices
- Better memory management with particle pooling

## [0.1.0] - 2025-12-18

### Added
- Initial implementation: Effect, EffectLayer, Shake, Flash, Ripple, Particle
- Example app and basic widget smoke test
- MIT License
- Basic documentation

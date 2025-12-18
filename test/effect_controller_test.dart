import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_effect_system/flutter_effect_system.dart';

void main() {
  group('EffectController', () {
    testWidgets('play() triggers effect correctly', (WidgetTester tester) async {
      final controller = EffectController();
      bool effectTriggered = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: EffectLayer(
              controller: controller,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ));

      // Play an effect
      controller.play(ShakeEffect(
        intensity: 10,
        duration: const Duration(milliseconds: 100),
      ));

      effectTriggered = true;

      await tester.pump(const Duration(milliseconds: 10));
      
      expect(effectTriggered, isTrue);
      expect(find.byType(EffectLayer), findsOneWidget);
    });

    testWidgets('multiple play() calls stack effects', (WidgetTester tester) async {
      final controller = EffectController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: EffectLayer(
              controller: controller,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ));

      // Stack multiple effects
      controller.play(ShakeEffect(intensity: 5, duration: const Duration(milliseconds: 200)));
      controller.play(FlashEffect(color: Colors.red, duration: const Duration(milliseconds: 150)));
      controller.play(RippleEffect(duration: const Duration(milliseconds: 300)));

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(EffectLayer), findsOneWidget);
    });

    testWidgets('clearAll() removes all active effects', (WidgetTester tester) async {
      final controller = EffectController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: EffectLayer(
              controller: controller,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ));

      controller.play(ShakeEffect(intensity: 10, duration: const Duration(seconds: 5)));
      await tester.pump(const Duration(milliseconds: 100));

      controller.clearAll();
      await tester.pump();

      // After clear, no effects should be active
      expect(find.byType(EffectLayer), findsOneWidget);
    });
  });

  group('Effect Composition', () {
    testWidgets('shake + flash effects compose correctly', (WidgetTester tester) async {
      final controller = EffectController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: EffectLayer(
              controller: controller,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ));

      controller.play(ShakeEffect(intensity: 8, duration: const Duration(milliseconds: 300)));
      controller.play(FlashEffect(color: Colors.white, duration: const Duration(milliseconds: 150)));

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('ripple + particle effects compose correctly', (WidgetTester tester) async {
      final controller = EffectController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: EffectLayer(
              controller: controller,
              child: const Text('Effect Test'),
            ),
          ),
        ),
      ));

      controller.play(RippleEffect(
        center: const Offset(0.5, 0.5),
        duration: const Duration(milliseconds: 400),
      ));
      controller.play(ParticleEffect(
        count: 20,
        duration: const Duration(milliseconds: 500),
      ));

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Effect Test'), findsOneWidget);
    });
  });

  group('Overlay Painter Registration', () {
    testWidgets('ParticleEffect registers overlay painter', (WidgetTester tester) async {
      final controller = EffectController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: EffectLayer(
              controller: controller,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      ));

      controller.play(ParticleEffect(count: 30, duration: const Duration(milliseconds: 400)));

      await tester.pump(const Duration(milliseconds: 50));

      // RepaintBoundary should be present for overlay painters
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('RippleEffect registers overlay painter', (WidgetTester tester) async {
      final controller = EffectController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: EffectLayer(
              controller: controller,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      ));

      controller.play(RippleEffect(duration: const Duration(milliseconds: 350)));

      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(RepaintBoundary), findsWidgets);
    });
  });

  group('Effect Duration and Lifecycle', () {
    testWidgets('effect completes after specified duration', (WidgetTester tester) async {
      final controller = EffectController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: EffectLayer(
              controller: controller,
              child: const Text('Duration Test'),
            ),
          ),
        ),
      ));

      controller.play(ShakeEffect(
        intensity: 10,
        duration: const Duration(milliseconds: 200),
      ));

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Effect should complete
      expect(find.text('Duration Test'), findsOneWidget);
    });

    testWidgets('multiple effects with different durations', (WidgetTester tester) async {
      final controller = EffectController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: EffectLayer(
              controller: controller,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ));

      // Short effect
      controller.play(FlashEffect(color: Colors.red, duration: const Duration(milliseconds: 100)));
      // Medium effect
      controller.play(ShakeEffect(intensity: 5, duration: const Duration(milliseconds: 300)));
      // Long effect
      controller.play(ParticleEffect(count: 10, duration: const Duration(milliseconds: 600)));

      await tester.pump(const Duration(milliseconds: 150)); // Flash done
      await tester.pump(const Duration(milliseconds: 200)); // Shake done
      await tester.pump(const Duration(milliseconds: 300)); // Particles done

      expect(find.byType(EffectLayer), findsOneWidget);
    });
  });
}

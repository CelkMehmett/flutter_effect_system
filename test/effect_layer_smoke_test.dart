import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_effect_system/flutter_effect_system.dart';

void main() {
  testWidgets('EffectLayer smoke test - shake runs without errors', (WidgetTester tester) async {
    final controller = EffectController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: EffectLayer(
            controller: controller,
            child: const SizedBox(width: 100, height: 50),
          ),
        ),
      ),
    ));

    // trigger a shake effect and advance time
    controller.play(ShakeEffect(intensity: 10, duration: const Duration(milliseconds: 300)));

    // advance a few frames
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // if we reach here without exceptions it's a basic smoke pass
    expect(find.byType(EffectLayer), findsOneWidget);
  });

  testWidgets('EffectLayer stacking multiple effects', (WidgetTester tester) async {
    final controller = EffectController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: EffectLayer(
            controller: controller,
            child: const SizedBox(width: 100, height: 50),
          ),
        ),
      ),
    ));

    // stack multiple effects in rapid succession
    controller.play(ShakeEffect(intensity: 6, duration: const Duration(milliseconds: 250)));
    controller.play(FlashEffect(color: Colors.white, duration: const Duration(milliseconds: 120)));
    controller.play(RippleEffect(duration: const Duration(milliseconds: 500)));
    controller.play(ParticleEffect(count: 16, duration: const Duration(milliseconds: 600)));

  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 200));
  // advance time by a comfortable margin (avoid pumpAndSettle which may
  // hang if a ticker remains alive). Sum of longest effect duration + buffer.
  await tester.pump(const Duration(milliseconds: 1000));

    expect(find.byType(EffectLayer), findsOneWidget);
  });
}

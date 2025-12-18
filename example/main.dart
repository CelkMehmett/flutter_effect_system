import 'package:flutter/material.dart';
import 'package:flutter_effect_system/flutter_effect_system.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Effect System Example',
      theme: ThemeData.dark(),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  final EffectController _controller = EffectController();
  double _intensity = 8.0;
  int _stackCount = 1;

  void _playShake() {
    _controller.play(ShakeEffect(intensity: _intensity, duration: const Duration(milliseconds: 350)));
  }

  void _playStacked() {
    for (int i = 0; i < _stackCount; i++) {
      _controller.play(ShakeEffect(intensity: _intensity * (1.0 + i * 0.3), duration: const Duration(milliseconds: 300 + 60)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_effect_system — Example')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EffectLayer(
              controller: _controller,
              child: GestureDetector(
                onTap: _playShake,
                child: Container(
                  width: 220,
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade800,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: const Text('Tap to shake', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(mainAxisSize: MainAxisSize.min, children: [
              ElevatedButton(onPressed: _playShake, child: const Text('Play Shake')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: _playStacked, child: const Text('Stack')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () => _controller.play(FlashEffect(color: Colors.white, duration: const Duration(milliseconds: 120))), child: const Text('Flash')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () => _controller.play(RippleEffect(color: Colors.white, duration: const Duration(milliseconds: 700), center: Offset(0.5, 0.5))), child: const Text('Ripple')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () => _controller.play(ParticleEffect(color: Colors.orangeAccent, count: 28, duration: const Duration(milliseconds: 800))), child: const Text('Particles')),
            ]),

            const SizedBox(height: 16),

            SizedBox(
              width: 320,
              child: Column(children: [
                Row(children: [const Text('Intensity'), Expanded(child: const SizedBox()) , Text(_intensity.toStringAsFixed(0))]),
                Slider(value: _intensity, min: 0, max: 40, onChanged: (v) => setState(() => _intensity = v)),

                Row(children: [const Text('Stack count'), Expanded(child: const SizedBox()), Text('$_stackCount')]),
                Slider(value: _stackCount.toDouble(), min: 1, max: 5, divisions: 4, onChanged: (v) => setState(() => _stackCount = v.toInt())),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

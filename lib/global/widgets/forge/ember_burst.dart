import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:auto_admin_app/global/theme/forge_palette.dart';
import 'package:auto_admin_app/global/widgets/forge/forge_completion_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Embers thrown by the edge of the sweep.
///
/// Every ember is decided when the burst starts and its position only depends
/// on the time, so nothing grows while it runs.
class EmberBurst extends StatefulWidget {
  static const int minEmbers = 8;
  static const int maxEmbers = 15;
  static const Duration emberLife = Duration(milliseconds: 800);

  const EmberBurst({super.key});

  @override
  State<EmberBurst> createState() => _EmberBurstState();
}

class _Ember {
  final double bornMs;

  /// Where it is born, as a fraction of the card.
  final double x;
  final double y;
  final double rise;
  final double drift;
  final double radius;

  const _Ember({
    required this.bornMs,
    required this.x,
    required this.y,
    required this.rise,
    required this.drift,
    required this.radius,
  });
}

class _EmberBurstState extends State<EmberBurst>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _elapsedMs = ValueNotifier(0);
  late List<_Ember> _embers;

  @override
  void initState() {
    super.initState();
    final random = Random();
    final sweepMs = ForgeTimings.sweep.inMilliseconds;
    final count = EmberBurst.minEmbers +
        random.nextInt(EmberBurst.maxEmbers - EmberBurst.minEmbers + 1);
    _embers = List.generate(count, (_) {
      final born = 0.05 + random.nextDouble() * 0.85;
      return _Ember(
        bornMs: born * sweepMs,
        x: Curves.easeInOutCubic.transform(born),
        y: 0.2 + random.nextDouble() * 0.7,
        rise: 40 + random.nextDouble() * 50,
        drift: (random.nextDouble() - 0.5) * 48,
        radius: 1.4 + random.nextDouble() * 1.6,
      );
    }, growable: false);
    final lastDeath = sweepMs + EmberBurst.emberLife.inMilliseconds;
    _ticker = createTicker((elapsed) {
      _elapsedMs.value = elapsed.inMicroseconds / 1000;
      if (_elapsedMs.value >= lastDeath) {
        _ticker.stop();
        _embers = const [];
      }
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsedMs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EmberPainter(state: this),
      size: Size.infinite,
    );
  }
}

class _EmberPainter extends CustomPainter {
  final _EmberBurstState state;

  _EmberPainter({required this.state}) : super(repaint: state._elapsedMs);

  @override
  void paint(Canvas canvas, Size size) {
    final now = state._elapsedMs.value;
    final lifeMs = EmberBurst.emberLife.inMilliseconds;
    final paint = Paint();
    for (final ember in state._embers) {
      final age = (now - ember.bornMs) / lifeMs;
      if (age < 0 || age >= 1) continue;
      final center = Offset(
        ember.x * size.width + ember.drift * age,
        ember.y * size.height - ember.rise * Curves.easeOut.transform(age),
      );
      paint.color = Color.lerp(
        ForgePalette.emberHot,
        ForgePalette.emberCold,
        age,
      )!
          .withValues(alpha: 1 - age * age);
      canvas.drawCircle(center, lerpDouble(ember.radius, 0.3, age)!, paint);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter oldDelegate) => oldDelegate.state != state;
}

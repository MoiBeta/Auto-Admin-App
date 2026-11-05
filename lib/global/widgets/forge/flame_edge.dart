import 'dart:ui' as ui;

import 'package:auto_admin_app/global/theme/forge_palette.dart';
import 'package:auto_admin_app/global/widgets/forge/forge_completion_animation.dart';
import 'package:auto_admin_app/global/widgets/forge/forge_fire_shader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Fire on the edge of a running sweep.
class FlameEdge extends StatefulWidget {
  final ForgeSweep sweep;

  /// How far above the card the flames may reach.
  static const double overflowTop = 14;

  static const Duration ignition = Duration(milliseconds: 100);
  static const Duration extinction = Duration(milliseconds: 150);

  const FlameEdge({super.key, required this.sweep});

  /// Grows at the start of the sweep and fades at its end.
  static double intensityAt(double linearProgress) {
    final total = ForgeTimings.sweep.inMilliseconds;
    final elapsed = linearProgress * total;
    final up = elapsed / ignition.inMilliseconds;
    final down = (total - elapsed) / extinction.inMilliseconds;
    return up.clamp(0.0, 1.0) * down.clamp(0.0, 1.0);
  }

  @override
  State<FlameEdge> createState() => _FlameEdgeState();
}

class _FlameEdgeState extends State<FlameEdge>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _seconds = ValueNotifier(0);
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _shader = ForgeFireShader.program?.fragmentShader();
    _ticker = createTicker((elapsed) {
      if (widget.sweep.linear.isCompleted) {
        _ticker.stop();
      }
      _seconds.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: -FlameEdge.overflowTop,
          child: CustomPaint(
            painter: _FlamePainter(
              sweep: widget.sweep,
              seconds: _seconds,
              shader: _shader,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlamePainter extends CustomPainter {
  final ForgeSweep sweep;
  final ValueNotifier<double> seconds;
  final ui.FragmentShader? shader;

  _FlamePainter({
    required this.sweep,
    required this.seconds,
    required this.shader,
  }) : super(repaint: seconds);

  @override
  void paint(Canvas canvas, Size size) {
    final intensity = FlameEdge.intensityAt(sweep.linear.value);
    if (intensity <= 0) return;

    final t = sweep.progress.value;
    final shader = this.shader;
    if (shader == null) {
      _paintFallback(canvas, size, t, intensity);
      return;
    }
    // In the order they are declared in forge_fire.frag.
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, seconds.value)
      ..setFloat(3, t)
      ..setFloat(4, intensity);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  void _paintFallback(Canvas canvas, Size size, double t, double intensity) {
    const halfWidth = 16.0;
    final x = size.width * (1 - t);
    final rect = Rect.fromLTRB(
        x - halfWidth, FlameEdge.overflowTop, x + halfWidth, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.centerLeft,
          rect.centerRight,
          [
            ForgePalette.flameFallback.withValues(alpha: 0),
            ForgePalette.flameFallbackCore.withValues(alpha: intensity),
            ForgePalette.flameFallback.withValues(alpha: 0),
          ],
          const [0, 0.5, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_FlamePainter oldDelegate) =>
      oldDelegate.sweep != sweep || oldDelegate.shader != shader;
}

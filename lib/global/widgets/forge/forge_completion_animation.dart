import 'package:auto_admin_app/global/theme/forge_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Durations of the forge animation.
abstract final class ForgeTimings {
  static const Duration sweep = Duration(milliseconds: 900);
  static const Duration cooling = Duration(milliseconds: 400);
  static const Duration unforge = Duration(milliseconds: 180);

  /// Effects stay this long after the sweep; embers are still falling off.
  static const Duration afterglow = Duration(milliseconds: 800);
}

/// The running sweep, for effects that follow its edge.
class ForgeSweep {
  /// Time progress, 0 to 1.
  final Animation<double> linear;

  /// Curved progress `t`. The edge is at `x = width * (1 - t)`.
  final Animation<double> progress;

  const ForgeSweep({required this.linear, required this.progress});
}

/// Forges a card from right to left when [forged] becomes true.
///
/// The controllers only exist while something is animating. The change is
/// purely visual: whoever owns [forged] has already saved it.
class ForgeCompletionAnimation extends StatefulWidget {
  final bool forged;

  /// Whether the next change of [forged] animates or is applied right away.
  final bool animate;

  /// Builds the card with a look. Called for two layers during an animation;
  /// the upper one ignores touches and is hidden from accessibility services.
  final Widget Function(BuildContext context, ForgeLook look) cardBuilder;

  /// Effects over the card. They may paint outside of it.
  final Widget Function(BuildContext context, ForgeSweep sweep)? effectBuilder;

  const ForgeCompletionAnimation({
    super.key,
    required this.forged,
    required this.cardBuilder,
    this.animate = true,
    this.effectBuilder,
  });

  @override
  State<ForgeCompletionAnimation> createState() =>
      _ForgeCompletionAnimationState();
}

enum _Phase { idle, sweeping, afterglow, unforging }

class _ForgeCompletionAnimationState extends State<ForgeCompletionAnimation>
    with TickerProviderStateMixin {
  _Phase _phase = _Phase.idle;
  AnimationController? _sweep;
  CurvedAnimation? _progress;
  AnimationController? _settle;
  Animation<double>? _overlayOpacity;
  ForgeLook _overlayLook = ForgeLook.hot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_phase != _Phase.idle && MediaQuery.disableAnimationsOf(context)) {
      _stop();
    }
  }

  @override
  void didUpdateWidget(ForgeCompletionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.forged == widget.forged) return;
    final fromLook = _visibleLook(oldWidget.forged);
    _stop();
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) return;
    if (widget.forged) {
      _startSweep();
    } else {
      _startUnforge(fromLook);
    }
  }

  ForgeLook _visibleLook(bool wasForged) => switch (_phase) {
        _Phase.sweeping || _Phase.afterglow => ForgeLook.hot,
        _ => wasForged ? ForgeLook.forged : ForgeLook.pending,
      };

  void _startSweep() {
    final sweep = AnimationController(vsync: this, duration: ForgeTimings.sweep)
      ..addStatusListener(_onSweepStatus);
    _sweep = sweep;
    _progress = CurvedAnimation(parent: sweep, curve: Curves.easeInOutCubic);
    _overlayLook = ForgeLook.hot;
    _phase = _Phase.sweeping;
    sweep.forward();
  }

  void _onSweepStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    HapticFeedback.mediumImpact();
    final settle = _newSettle(ForgeTimings.afterglow);
    final coolingEnd = ForgeTimings.cooling.inMilliseconds /
        ForgeTimings.afterglow.inMilliseconds;
    setState(() {
      _phase = _Phase.afterglow;
      _overlayOpacity = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(
          parent: settle,
          curve: Interval(0, coolingEnd, curve: Curves.easeOut),
        ),
      );
    });
    settle.forward();
  }

  void _startUnforge(ForgeLook fromLook) {
    if (fromLook == ForgeLook.pending) return;
    final settle = _newSettle(ForgeTimings.unforge);
    _overlayLook = fromLook;
    _overlayOpacity = Tween<double>(begin: 1, end: 0).animate(settle);
    _phase = _Phase.unforging;
    settle.forward();
  }

  AnimationController _newSettle(Duration duration) {
    final settle = AnimationController(vsync: this, duration: duration);
    settle.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(_stop);
      }
    });
    return _settle = settle;
  }

  /// Back to idle. The layers still listen to the controllers until the next
  /// build, so these are disposed after it.
  void _stop() {
    final progress = _progress;
    final sweep = _sweep;
    final settle = _settle;
    _phase = _Phase.idle;
    _progress = null;
    _sweep = null;
    _settle = null;
    _overlayOpacity = null;
    sweep?.stop();
    settle?.stop();
    if (sweep == null && settle == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      progress?.dispose();
      sweep?.dispose();
      settle?.dispose();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    _progress?.dispose();
    _sweep?.dispose();
    _settle?.dispose();
    super.dispose();
  }

  ForgeLook get _baseLook => switch (_phase) {
        _Phase.sweeping || _Phase.unforging => ForgeLook.pending,
        _Phase.afterglow => ForgeLook.forged,
        _Phase.idle => widget.forged ? ForgeLook.forged : ForgeLook.pending,
      };

  Widget _overlayCard(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: widget.cardBuilder(context, _overlayLook),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final sweep = _sweep;
    final progress = _progress;
    final opacity = _overlayOpacity;
    final effectBuilder = widget.effectBuilder;

    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Always first, so the card keeps its state between animations.
          RepaintBoundary(child: widget.cardBuilder(context, _baseLook)),
          if (_phase == _Phase.sweeping)
            ClipRect(
              clipper: _RevealClipper(progress!),
              child: _overlayCard(context),
            )
          else if (opacity != null)
            FadeTransition(opacity: opacity, child: _overlayCard(context)),
          if (effectBuilder != null && sweep != null && progress != null)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: effectBuilder(
                    context,
                    ForgeSweep(linear: sweep, progress: progress),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  final Animation<double> t;

  _RevealClipper(this.t) : super(reclip: t);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(size.width * (1 - t.value), 0, size.width, size.height);

  @override
  bool shouldReclip(_RevealClipper oldClipper) => oldClipper.t != t;
}

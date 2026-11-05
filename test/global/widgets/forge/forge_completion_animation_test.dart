import 'package:auto_admin_app/global/theme/forge_palette.dart';
import 'package:auto_admin_app/global/widgets/forge/ember_burst.dart';
import 'package:auto_admin_app/global/widgets/forge/flame_edge.dart';
import 'package:auto_admin_app/global/widgets/forge/forge_completion_animation.dart';
import 'package:auto_admin_app/global/widgets/forge/forge_fire_shader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({
  required bool forged,
  bool animate = true,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            height: 80,
            child: ForgeCompletionAnimation(
              forged: forged,
              animate: animate,
              cardBuilder: (context, look) => Text(look.name),
              effectBuilder: (context, sweep) => Stack(
                fit: StackFit.expand,
                children: [FlameEdge(sweep: sweep), const EmberBurst()],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late List<String> haptics;

  setUp(() {
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  int runningTickers(WidgetTester tester) =>
      tester.binding.transientCallbackCount;

  testWidgets('a task already completed is forged without animating',
      (tester) async {
    await tester.pumpWidget(_harness(forged: true));

    expect(find.text('forged'), findsOneWidget);
    expect(find.text('hot'), findsNothing);
    expect(find.byType(FlameEdge), findsNothing);
    expect(runningTickers(tester), 0);
  });

  testWidgets('completing sweeps, vibrates at its end and ends forged',
      (tester) async {
    await tester.pumpWidget(_harness(forged: false));
    await tester.pumpWidget(_harness(forged: true));

    expect(find.text('pending'), findsOneWidget);
    expect(find.text('hot'), findsOneWidget);
    expect(find.byType(FlameEdge), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 440));
    expect(haptics, isEmpty);

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(haptics, ['HapticFeedbackType.mediumImpact']);
    expect(find.text('forged'), findsOneWidget);
    expect(find.text('pending'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('forged'), findsOneWidget);
    expect(find.text('hot'), findsNothing);
    expect(find.byType(EmberBurst), findsNothing);
    expect(runningTickers(tester), 0);
  });

  testWidgets('the reveal goes from the right edge to the left one',
      (tester) async {
    await tester.pumpWidget(_harness(forged: false));
    await tester.pumpWidget(_harness(forged: true));
    await tester.pump();

    final clip = tester.renderObject<RenderClipRect>(
      find.ancestor(of: find.text('hot'), matching: find.byType(ClipRect)),
    );
    expect(clip.clipper!.getClip(const Size(300, 80)).right, 300);
    final atStart = clip.clipper!.getClip(const Size(300, 80)).left;

    await tester.pump(const Duration(milliseconds: 450));
    final halfway = clip.clipper!.getClip(const Size(300, 80)).left;
    expect(halfway, lessThan(atStart));
    expect(halfway, closeTo(150, 10));
  });

  testWidgets('with animations disabled it changes at once', (tester) async {
    await tester.pumpWidget(_harness(forged: false, disableAnimations: true));
    await tester.pumpWidget(_harness(forged: true, disableAnimations: true));

    expect(find.text('forged'), findsOneWidget);
    expect(find.text('hot'), findsNothing);
    expect(find.byType(FlameEdge), findsNothing);
    expect(runningTickers(tester), 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a change that must not animate is applied right away',
      (tester) async {
    await tester.pumpWidget(_harness(forged: false, animate: false));
    await tester.pumpWidget(_harness(forged: true, animate: false));

    expect(find.text('forged'), findsOneWidget);
    expect(runningTickers(tester), 0);
    expect(haptics, isEmpty);
  });

  testWidgets('unmarking fades to pending without a sweep', (tester) async {
    await tester.pumpWidget(_harness(forged: true));
    await tester.pumpWidget(_harness(forged: false));

    expect(find.text('pending'), findsOneWidget);
    expect(find.text('forged'), findsOneWidget);
    expect(find.byType(FlameEdge), findsNothing);

    await tester.pump(ForgeTimings.unforge);
    await tester.pumpAndSettle();
    expect(find.text('pending'), findsOneWidget);
    expect(find.text('forged'), findsNothing);
    expect(runningTickers(tester), 0);
    expect(haptics, isEmpty);
  });

  testWidgets('it can be toggled fast and removed while it runs',
      (tester) async {
    await tester.pumpWidget(_harness(forged: false));
    for (var i = 0; i < 6; i++) {
      await tester.pumpWidget(_harness(forged: i.isEven));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pumpWidget(_harness(forged: true));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(runningTickers(tester), 0);
  });

  test('the flame lights up in 100 ms and goes out in the last 150 ms', () {
    const total = 900;
    expect(FlameEdge.intensityAt(0), 0);
    expect(FlameEdge.intensityAt(50 / total), closeTo(0.5, 0.001));
    expect(FlameEdge.intensityAt(100 / total), closeTo(1, 0.001));
    expect(FlameEdge.intensityAt(0.5), 1);
    expect(FlameEdge.intensityAt(825 / total), closeTo(0.5, 0.001));
    expect(FlameEdge.intensityAt(1), 0);
  });

  testWidgets('the shader compiles and loads', (tester) async {
    final program = await tester.runAsync(ForgeFireShader.load);
    expect(program, isNotNull);
  });

  test('text stays readable over the forge colors', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      return (la > lb ? la + 0.05 : lb + 0.05) /
          (la > lb ? lb + 0.05 : la + 0.05);
    }

    expect(contrast(ForgePalette.onHot, ForgePalette.hot),
        greaterThanOrEqualTo(4.5));
    expect(contrast(ForgePalette.onSteel, ForgePalette.steel),
        greaterThanOrEqualTo(4.5));
    expect(contrast(ForgePalette.steelAccent, ForgePalette.steel),
        greaterThanOrEqualTo(3));
  });
}

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// The fire program, loaded once and shared by every card.
abstract final class ForgeFireShader {
  static const String assetKey = 'shaders/forge_fire.frag';

  static Future<ui.FragmentProgram?>? _loading;
  static ui.FragmentProgram? _program;

  /// Null until it loads, and forever if it could not.
  static ui.FragmentProgram? get program => _program;

  static Future<ui.FragmentProgram?> load() => _loading ??= _load();

  static Future<ui.FragmentProgram?> _load() async {
    try {
      return _program = await ui.FragmentProgram.fromAsset(assetKey);
    } catch (error) {
      debugPrint('Could not load $assetKey, using a gradient: $error');
      return null;
    }
  }
}

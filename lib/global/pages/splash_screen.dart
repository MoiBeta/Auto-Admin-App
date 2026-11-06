import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/core/errors/error_handler.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto_admin_app/global/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LoginState> authState = ref.watch(authNotifierProvider);

    if (authState.isLoading) return const _ForgeSplash();

    if (authState.hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ErrorHandler.extractAppError(authState.error!).message,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.md),
                FilledButton(
                  onPressed: () => ref.invalidate(authNotifierProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (authState.value?.credentials != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(Routes.home);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(Routes.auth);
      });
    }

    return const _ForgeSplash();
  }
}

/// The forge animation placed exactly over the icon of the native splash, so
/// the change from one to the other cannot be seen.
class _ForgeSplash extends StatelessWidget {
  const _ForgeSplash();

  // Color of the native splash (ic_launcher_background).
  static const Color _background = Color(0xFF011334);

  // On Android 12+ the native splash draws the 108 dp adaptive icon at 240 dp.
  // The animation covers the icon's 72 dp safe zone, i.e. 160 dp, slightly
  // left and above the center, just like the anvil in the icon.
  static const double _size = 160;
  static const Offset _offset = Offset(-1.4, -6.4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: Transform.translate(
          offset: _offset,
          child: Lottie.asset(
            'assets/animations/forge_splash.json',
            width: _size,
            height: _size,
          ),
        ),
      ),
    );
  }
}

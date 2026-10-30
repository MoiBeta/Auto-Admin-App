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

    if (authState.isLoading) {
      return Scaffold(
        body: Center(
          child: Lottie.asset('assets/animations/task-login.json'),
        ),
      );
    }

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

    return Scaffold(
      body: Center(
        child: Lottie.asset('assets/animations/task-login.json'),
      ),
    );
  }
}

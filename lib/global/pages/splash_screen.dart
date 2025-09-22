import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/auth/injection/auth_injection.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LoginState authState = ref.watch(authNotifierProvider);
    if (authState.isLoading) {
      return Scaffold(
        body: Center(
          child: Lottie.asset(
            'assets/animations/task-login.json',
          ),
        ),
      );
    }

    if (authState.hasError) {
      return Scaffold(
          body: Center(child: Text('Error: ${authState.errorMessage}')));
    }

    if (authState.credentials != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (authState.credentials == null) {
          context.go(Routes.auth);
        } else {
          context.go(Routes.home);
        }
      });
    }
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/animations/task-login.json',
        ),
      ),
    );
  }
}

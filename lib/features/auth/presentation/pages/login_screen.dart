import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/global/widgets/loading_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final loginState = ref.watch(authNotifierProvider).value;
    final isLoading = loginState?.isLoading ?? false;

    ref.listen(authNotifierProvider, (previous, next) {
      final credentials = next.value?.credentials;
      if (credentials != null && context.mounted) {
        context.go(Routes.home);
      }
    });

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 50, bottom: 40),
              child: Lottie.asset('assets/animations/task-login.json'),
            ),
            TextFormField(
              controller: authNotifier.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Correo'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: authNotifier.passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Contraseña'),
            ),
            const SizedBox(height: 16),
            LoadingButton(
              isLoading: isLoading,
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).login();
              },
              label: 'Iniciar sesión',
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () => context.pushReplacementNamed(Routes.register),
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}

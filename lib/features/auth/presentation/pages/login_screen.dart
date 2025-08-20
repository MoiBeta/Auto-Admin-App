import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/auth/injection/auth_injection.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AuthNotifier authNotifier = ref.read(authNotifierProvider.notifier);
    LoginState? loginState = ref.watch(authNotifierProvider);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: ListView(
          children: [
            Container(
              margin: EdgeInsets.only(
                top: 50,
                bottom: 40,
              ),
              child: Lottie.asset(
                'assets/animations/task-login.json',
              ),
            ),
            TextFormField(
              controller: authNotifier.emailController,
              decoration: InputDecoration(
                hintText: 'Correo',
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              controller: authNotifier.passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Contraseña',
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).login();
                if (context.mounted) {
                  context.pushReplacementNamed(Routes.home);
                }
              },
              child: (loginState?.isLoading ?? false)
                  ? SizedBox(
                height: 20,
                  child: CircularProgressIndicator(),
              )
                  : Text('Iniciar sesión'),
            ),
            FilledButton(
              onPressed: () async {
                context.pushReplacementNamed(Routes.register);
              },
              child: Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}

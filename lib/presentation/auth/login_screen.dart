import 'package:auto_admin_app/router/routes.dart';
import 'package:auto_admin_app/state/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AuthNotifier authNotifier = ref.read(authNotifierProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text('Iniciar sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: authNotifier.emailController,
              decoration: InputDecoration(
                hintText: 'Correo',
              ),
            ),
            TextFormField(
              controller: authNotifier.passwordController,
              decoration: InputDecoration(
                hintText: 'Contraseña',
              ),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).login();
                if (context.mounted) {
                  context.pushReplacementNamed(Routes.home);
                }
              },
              child: Text('Iniciar sesión'),
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

import 'package:auto_admin_app/router/routes.dart';
import 'package:auto_admin_app/state/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Correo',
              ),
            ),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                hintText: 'Contraseña',
              ),
            ),
            FilledButton(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).login(
                      emailAddress: emailController.text,
                      password: passwordController.text,
                  );
                  if(context.mounted){
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

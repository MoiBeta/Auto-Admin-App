import 'package:auto_admin_app/auth/auth_provider.dart';
import 'package:auto_admin_app/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro'),
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
                await ref.read(authNotifierProvider.notifier).register(
                  emailAddress: emailController.text,
                  password: passwordController.text,
                );
                if(context.mounted){
                  context.pushReplacementNamed(Routes.home);
                }
              },
              child: Text('Registrarse'),
            ),
            FilledButton(
              onPressed: () async {
                context.pushReplacementNamed(Routes.login);
              },
              child: Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

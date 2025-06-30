import 'package:auto_admin_app/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Toma el control de tu vida',
                  textAlign: TextAlign.start,
                ),
                Text('Empieza ahora...',
                  textAlign: TextAlign.start,
                ),
              ],
            ),
            Lottie.asset(
              'assets/animations/task-login.json',
            ),
            FilledButton(
              onPressed: () async {
                context.pushReplacementNamed(Routes.login);
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

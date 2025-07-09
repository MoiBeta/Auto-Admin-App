import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  LoginState? build() {
    listenUserChanges();
    return LoginState(
      user: FirebaseAuth.instance.currentUser,
    );
  }

  void listenUserChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      state = state?.copyWith(
        user: user,
      );
    });
  }

  Future<void> register({
    required String emailAddress,
    required String password,
  }) async {
    try {
      state = state?.copyWith(
        isLoading: true,
      );
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAddress.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        state = state?.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: 'The password provided is too weak.',
        );
      } else if (e.code == 'email-already-in-use') {
        state = state?.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: 'The account already exists for that email.',
        );
      }
    } catch (e) {
      state = state?.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
    state = state?.copyWith(
      isLoading: false,
    );
  }

  Future<void> login() async {
    try {
      state = state?.copyWith(
        isLoading: true,
      );
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        state = state?.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: 'No user found for that email.',
        );
      } else if (e.code == 'wrong-password') {
        state = state?.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: 'Wrong password provided for that user.',
        );
      }
    }
    state = state?.copyWith(
      isLoading: false,
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  bool isAuthenticated() => state?.user != null;
}

class LoginState {
  final User? user;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const LoginState({
    this.isLoading = false,
    this.hasError = false,
    this.user,
    this.errorMessage,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    User? user,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

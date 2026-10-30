String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
      ? null
      : 'Escribe un correo válido';
}

String? validateRequired(String? value, String message) =>
    (value?.trim().isEmpty ?? true) ? message : null;

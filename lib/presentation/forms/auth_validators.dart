class AuthValidators {
  AuthValidators._();

  static final RegExp _emailPattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu correo electrónico.';
    if (!_emailPattern.hasMatch(text)) {
      return 'Ingresa un correo válido, por ejemplo usuario@correo.com.';
    }
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña.';
    return null;
  }

  static String? displayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Escribe al menos 2 caracteres.';
    return null;
  }

  static String? registrationPassword(String? value) {
    final text = value ?? '';
    if (text.length < 10) {
      return 'La contraseña debe tener al menos 10 caracteres.';
    }
    return null;
  }
}

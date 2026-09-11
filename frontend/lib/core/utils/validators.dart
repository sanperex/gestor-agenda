/// Validaciones de formularios. Devuelven el mensaje de error, o null si el valor es valido.
/// Siguen las mismas reglas del backend para que el usuario vea el error antes de enviar.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static const int minPasswordLength = 6;

  static String? required(String? value, String message) {
    return (value == null || value.trim().isEmpty) ? message : null;
  }

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu nombre';
    if (text.length < 2 || text.length > 50) return 'El nombre debe tener entre 2 y 50 caracteres';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu correo';
    if (!_emailRegex.hasMatch(text)) return 'El correo no tiene un formato válido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña';
    if (value.length < minPasswordLength) {
      return 'La contraseña debe tener al menos $minPasswordLength caracteres';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? resetCode(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^\d{6}$').hasMatch(text)) return 'El código debe tener 6 dígitos';
    return null;
  }
}

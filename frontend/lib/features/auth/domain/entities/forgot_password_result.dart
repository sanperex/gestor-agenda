/// Resultado de pedir un codigo de recuperacion.
class ForgotPasswordResult {
  const ForgotPasswordResult({required this.message, this.demoCode});

  final String message;

  /// Solo llega cuando el backend esta en modo demo (RESET_CODE_DEMO=true).
  final String? demoCode;
}

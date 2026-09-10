/// Error "entendible" para mostrar al usuario.
///
/// El [ApiClient] convierte cualquier falla (sin conexion, 401, 409...) en esta clase,
/// asi las pantallas solo tienen que mostrar [message].
class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;

  /// Codigo HTTP que devolvio la API (null si ni siquiera hubo respuesta).
  final int? statusCode;

  @override
  String toString() => message;
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el token JWT en el almacenamiento seguro del dispositivo.
/// Android: cifrado con el Keystore del sistema. Web: cifrado en el navegador.
class AuthLocalDataSource {
  AuthLocalDataSource([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../errors/app_exception.dart';

/// Respuesta exitosa de la API: `{ success: true, message, data }`.
class ApiResponse {
  const ApiResponse({required this.message, required this.data});

  final String message;
  final Map<String, dynamic> data;
}

/// Funcion que entrega el token guardado (o null si no hay sesion).
typedef TokenGetter = Future<String?> Function();

/// Cliente HTTP COMPARTIDO por A y B.
///
/// - Agrega solo el header `Authorization: Bearer <token>` si hay sesion.
/// - Devuelve [ApiResponse] si todo sale bien.
/// - Lanza [AppException] con un mensaje claro si algo falla.
class ApiClient {
  ApiClient({required this._getToken, http.Client? client}) : _client = client ?? http.Client();

  final TokenGetter _getToken;
  final http.Client _client;

  Future<ApiResponse> get(String path) => _send('GET', path);
  Future<ApiResponse> post(String path, [Map<String, dynamic>? body]) => _send('POST', path, body);
  Future<ApiResponse> put(String path, [Map<String, dynamic>? body]) => _send('PUT', path, body);
  Future<ApiResponse> delete(String path) => _send('DELETE', path);

  Future<ApiResponse> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final request = http.Request(method, Uri.parse('${ApiConstants.baseUrl}$path'))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json';

    final token = await _getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    // 1. Enviar. Aqui solo fallan problemas de red.
    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(ApiConstants.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const AppException('El servidor tardó demasiado en responder. Intenta de nuevo');
    } on Exception {
      throw const AppException('No se pudo conectar con el servidor. Revisa tu conexión');
    }

    // 2. Leer el JSON.
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw AppException('Respuesta inesperada del servidor', statusCode: response.statusCode);
    }

    // 3. Exito o error segun el formato comun de la API.
    final ok = response.statusCode >= 200 && response.statusCode < 300 && json['success'] == true;
    if (!ok) {
      throw AppException(
        json['message'] as String? ?? 'Ocurrió un error (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return ApiResponse(
      message: json['message'] as String? ?? '',
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }
}

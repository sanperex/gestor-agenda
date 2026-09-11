import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/forgot_password_result.dart';
import '../models/user_model.dart';

/// Habla con los endpoints /api/auth/* del backend.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._api);

  final ApiClient _api;

  Future<({UserModel user, String token})> login({required String email, required String password}) async {
    final res = await _api.post(ApiConstants.login, {'email': email, 'password': password});
    return _readSession(res.data);
  }

  Future<({UserModel user, String token})> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.post(ApiConstants.register, {'name': name, 'email': email, 'password': password});
    return _readSession(res.data);
  }

  /// Usa el token guardado (lo agrega el ApiClient) para pedir el usuario actual.
  Future<UserModel> me() async {
    final res = await _api.get(ApiConstants.me);
    return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    final res = await _api.post(ApiConstants.forgotPassword, {'email': email});
    return ForgotPasswordResult(message: res.message, demoCode: res.data['demoCode'] as String?);
  }

  Future<String> resetPassword({required String email, required String code, required String newPassword}) async {
    final res = await _api.post(ApiConstants.resetPassword, {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
    return res.message;
  }

  ({UserModel user, String token}) _readSession(Map<String, dynamic> data) {
    return (
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
  }
}

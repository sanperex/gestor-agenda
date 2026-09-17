import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/forgot_password_usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/reset_password_usecase.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Aqui se "arman" las piezas de Clean Architecture, de adentro hacia afuera.
  final authLocal = AuthLocalDataSource();
  final apiClient = ApiClient(getToken: authLocal.readToken);
  final authRepository = AuthRepositoryImpl(remote: AuthRemoteDataSource(apiClient), local: authLocal);

  final authProvider = AuthProvider(
    login: LoginUseCase(authRepository),
    register: RegisterUseCase(authRepository),
    getCurrentUser: GetCurrentUserUseCase(authRepository),
    forgotPassword: ForgotPasswordUseCase(authRepository),
    resetPassword: ResetPasswordUseCase(authRepository),
    logout: LogoutUseCase(authRepository),
  )..checkSession();

  runApp(
    MultiProvider(
      providers: [
        // Compartido: el Aprendiz B lo obtiene con context.read<ApiClient>().
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        // Aprendiz B: agregar aqui su provider de agenda.
      ],
      child: const GestorAgendaApp(),
    ),
  );
}

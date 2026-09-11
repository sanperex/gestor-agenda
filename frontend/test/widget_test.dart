import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gestor_agenda/app/app.dart';
import 'package:gestor_agenda/core/errors/app_exception.dart';
import 'package:gestor_agenda/features/auth/domain/entities/forgot_password_result.dart';
import 'package:gestor_agenda/features/auth/domain/entities/user.dart';
import 'package:gestor_agenda/features/auth/domain/repositories/auth_repository.dart';
import 'package:gestor_agenda/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:gestor_agenda/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:gestor_agenda/features/auth/domain/usecases/login_usecase.dart';
import 'package:gestor_agenda/features/auth/domain/usecases/logout_usecase.dart';
import 'package:gestor_agenda/features/auth/domain/usecases/register_usecase.dart';
import 'package:gestor_agenda/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:gestor_agenda/features/auth/presentation/providers/auth_provider.dart';

/// Repositorio falso: permite probar las pantallas sin backend.
class FakeAuthRepository implements AuthRepository {
  static const validEmail = 'ana@test.com';
  static const validPassword = '123456';

  @override
  Future<User> login({required String email, required String password}) async {
    if (email == validEmail && password == validPassword) {
      return const User(id: '1', name: 'Ana', email: validEmail);
    }
    throw const AppException('Correo o contraseña incorrectos', statusCode: 401);
  }

  @override
  Future<User> register({required String name, required String email, required String password}) async {
    if (email == validEmail) throw const AppException('El correo ya está registrado', statusCode: 409);
    return User(id: '2', name: name, email: email);
  }

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<ForgotPasswordResult> forgotPassword({required String email}) async =>
      const ForgotPasswordResult(message: 'Código enviado', demoCode: '123456');

  @override
  Future<String> resetPassword({required String email, required String code, required String newPassword}) async =>
      'Contraseña actualizada';

  @override
  Future<void> logout() async {}
}

Future<void> pumpApp(WidgetTester tester) async {
  final repo = FakeAuthRepository();
  final provider = AuthProvider(
    login: LoginUseCase(repo),
    register: RegisterUseCase(repo),
    getCurrentUser: GetCurrentUserUseCase(repo),
    forgotPassword: ForgotPasswordUseCase(repo),
    resetPassword: ResetPasswordUseCase(repo),
    logout: LogoutUseCase(repo),
  );
  await provider.checkSession();
  await tester.pumpWidget(ChangeNotifierProvider.value(value: provider, child: const GestorAgendaApp()));
  await tester.pumpAndSettle();
}

Finder field(String label) => find.widgetWithText(TextFormField, label);

/// Hace scroll hasta el widget (como haria el usuario) y lo toca.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  testWidgets('Sin sesión muestra el Login', (tester) async {
    await pumpApp(tester);
    expect(find.text('Iniciar sesión'), findsWidgets);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });

  testWidgets('Login con campos vacíos muestra errores de validación', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pump();
    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('Login con correo mal escrito muestra error de formato', (tester) async {
    await pumpApp(tester);
    await tester.enterText(field('Correo electrónico'), 'ana@');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pump();
    expect(find.text('El correo no tiene un formato válido'), findsOneWidget);
  });

  testWidgets('Login con contraseña incorrecta muestra el error de la API', (tester) async {
    await pumpApp(tester);
    await tester.enterText(field('Correo electrónico'), FakeAuthRepository.validEmail);
    await tester.enterText(field('Contraseña'), 'mala123');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
  });

  testWidgets('Login correcto entra a la agenda y logout vuelve al login', (tester) async {
    await pumpApp(tester);
    await tester.enterText(field('Correo electrónico'), FakeAuthRepository.validEmail);
    await tester.enterText(field('Contraseña'), FakeAuthRepository.validPassword);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ana'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
  });

  testWidgets('Registro valida que las contraseñas coincidan', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('Regístrate'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Nombre'), 'Luis');
    await tester.enterText(field('Correo electrónico'), 'luis@test.com');
    await tester.enterText(field('Contraseña'), '123456');
    await tester.enterText(field('Confirmar contraseña'), '654321');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });

  testWidgets('Registro correcto entra a la agenda', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('Regístrate'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Nombre'), 'Luis');
    await tester.enterText(field('Correo electrónico'), 'luis@test.com');
    await tester.enterText(field('Contraseña'), '123456');
    await tester.enterText(field('Confirmar contraseña'), '123456');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Luis'), findsOneWidget);
  });

  testWidgets('Recuperación: pide código y muestra el código demo', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Correo electrónico'), 'ana@test.com');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Enviar código'));
    await tester.pumpAndSettle();
    expect(find.text('Modo demo: tu código es 123456'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Cambiar contraseña'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

/// Recuperacion en 2 pasos:
/// 1. El usuario escribe su correo y pide un codigo.
/// 2. Escribe el codigo de 6 digitos y su nueva contrasena.
class ForgotPassPage extends StatefulWidget {
  const ForgotPassPage({super.key});

  @override
  State<ForgotPassPage> createState() => _ForgotPassPageState();
}

class _ForgotPassPageState extends State<ForgotPassPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeSent = false;
  String? _demoCode;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);

    final result = await auth.forgotPassword(email: _emailController.text.trim());
    if (!mounted) return;

    if (result == null) {
      showMessage(messenger, auth.errorMessage!, isError: true);
      return;
    }
    setState(() {
      _codeSent = true;
      _demoCode = result.demoCode;
    });
    showMessage(messenger, result.message);
  }

  Future<void> _resetPassword() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final message = await auth.resetPassword(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
      newPassword: _passwordController.text,
    );

    if (message == null) {
      showMessage(messenger, auth.errorMessage!, isError: true);
    } else {
      navigator.pop(); // vuelve al login
      showMessage(messenger, message);
    }
  }

  void _changeEmail() {
    setState(() {
      _codeSent = false;
      _demoCode = null;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return AuthLayout(
      title: 'Recuperar contraseña',
      subtitle: _codeSent
          ? 'Escribe el código de 6 dígitos y tu nueva contraseña'
          : 'Te enviaremos un código para crear una nueva contraseña',
      icon: Icons.lock_reset_rounded,
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _emailController,
              label: 'Correo electrónico',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: _codeSent ? TextInputAction.next : TextInputAction.done,
              onFieldSubmitted: _codeSent ? null : (_) => _requestCode(),
              validator: Validators.email,
              enabled: !isLoading && !_codeSent,
            ),
            if (_codeSent) ...[
              if (_demoCode != null) ...[
                const SizedBox(height: 16),
                _DemoCodeBox(code: _demoCode!),
              ],
              const SizedBox(height: 16),
              AuthTextField(
                controller: _codeController,
                label: 'Código de 6 dígitos',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                validator: Validators.resetCode,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'Nueva contraseña',
                icon: Icons.lock_outline,
                isPassword: true,
                validator: Validators.password,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _confirmController,
                label: 'Confirmar nueva contraseña',
                icon: Icons.lock_reset_outlined,
                isPassword: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _resetPassword(),
                validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                enabled: !isLoading,
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              text: _codeSent ? 'Cambiar contraseña' : 'Enviar código',
              isLoading: isLoading,
              onPressed: _codeSent ? _resetPassword : _requestCode,
            ),
            if (_codeSent) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading ? null : _changeEmail,
                child: const Text('Usar otro correo o pedir un código nuevo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Aviso que solo aparece si el backend esta en modo demo.
class _DemoCodeBox extends StatelessWidget {
  const _DemoCodeBox({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.info, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text('Modo demo: tu código es $code')),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (ok) {
      // Queda con la sesion iniciada: se cierra esta pantalla y AuthGate muestra la agenda.
      navigator.popUntil((route) => route.isFirst);
      showMessage(messenger, 'Cuenta creada. ¡Bienvenido, ${auth.user!.name}!');
    } else {
      showMessage(messenger, auth.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return AuthLayout(
      title: 'Crear cuenta',
      subtitle: 'Regístrate para organizar tu agenda',
      icon: Icons.person_add_alt_1_outlined,
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _nameController,
                label: 'Nombre',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                autofillHints: const [AutofillHints.name],
                validator: Validators.name,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _emailController,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'Contraseña',
                icon: Icons.lock_outline,
                isPassword: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _confirmController,
                label: 'Confirmar contraseña',
                icon: Icons.lock_reset_outlined,
                isPassword: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),
              PrimaryButton(text: 'Crear cuenta', isLoading: isLoading, onPressed: _submit),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Ya tengo cuenta, iniciar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

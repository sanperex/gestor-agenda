import 'package:flutter/material.dart';

/// Campo de texto de los formularios de auth.
/// Si [isPassword] es true, oculta el texto y agrega el boton del "ojito".
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.isPassword = false,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.autofillHints,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool isPassword;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      // Revisa el campo mientras el usuario escribe (despues de tocarlo).
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon),
        suffixIcon: widget.isPassword
            ? IconButton(
                tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}

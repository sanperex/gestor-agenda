/// Usuario de la app. Clase pura: no sabe nada de JSON, HTTP ni Flutter.
class User {
  const User({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;
}

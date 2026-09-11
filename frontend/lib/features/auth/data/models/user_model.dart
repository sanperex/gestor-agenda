import '../../domain/entities/user.dart';

/// Version de [User] que sabe leerse desde el JSON de la API.
class UserModel extends User {
  const UserModel({required super.id, required super.name, required super.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

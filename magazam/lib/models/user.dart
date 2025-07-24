import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? token;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle nested user data structure
    final userData = json['user'] ?? json; // If 'user' key exists, use it, otherwise use root

    return User(
      id: userData['id']?.toString() ?? '',
      fullName: userData['fullName'] ?? '',
      email: userData['email'] ?? '',
      token: json['token'] ?? '', // Token is at root level
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'token': token,
    };
  }

  @override
  String toString() {
    return 'User($id, $fullName, $email, $token)';
  }

  @override
  List<Object?> get props => [id, fullName, email, token];
}
// lib/models/user.dart

class User {
  final String id;
  final String username;
  final String firstName;
  final String email;

  User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      email: json['email'],
    );
  }
}

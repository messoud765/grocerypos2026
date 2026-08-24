// Represents a user account (Admin or Cashier)
class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String fullName;
  final String role; // 'admin' or 'cashier'

  UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': passwordHash,
      'fullName': fullName,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password'] as String,
      fullName: map['fullName'] as String,
      role: map['role'] as String,
    );
  }
}

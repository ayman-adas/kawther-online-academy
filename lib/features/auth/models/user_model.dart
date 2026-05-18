enum UserRole {
  admin,
  student,
}

class User {
  final String id;
  final String username;
  final String displayName;
  final UserRole role;
  final String? profileImage;
  final String? deviceName; // New field for device binding
  final String? password; // Admin-visible password (stored in Firestore)
  final String? email; // Stored email for admin reference

  User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    this.profileImage,
    this.deviceName,
    this.password,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? id}) {
    return User(
      id: json['id'] ?? id ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.student,
      ),
      profileImage: json['profileImage'],
      deviceName: json['deviceName'],
      password: json['password'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'role': role.name,
      'profileImage': profileImage,
      'deviceName': deviceName,
      'password': password,
      'email': email,
    };
  }
}

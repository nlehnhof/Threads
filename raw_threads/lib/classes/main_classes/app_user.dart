class AppUser {
  final String id;
  final String email;
  final String username;
  final String role; // 'admin' or 'user'
  final String? phoneNumber;
  final String? photoURL;
  final Map<String, String> sizes; // key = size type, value = measurement

  AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.phoneNumber,
    this.photoURL,
    this.sizes = const {},
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final sizesMap = (json['sizes'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {};
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
      phoneNumber: json['phoneNumber'],
      photoURL: json['photoURL'],
      sizes: sizesMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role': role,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'sizes': sizes,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? username,
    String? role,
    String? phoneNumber,
    String? photoURL,
    Map<String, String>? sizes,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      sizes: sizes ?? this.sizes,
    );
  }
}

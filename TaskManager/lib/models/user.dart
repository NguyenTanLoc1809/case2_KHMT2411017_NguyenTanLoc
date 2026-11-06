class User {
  final String id;
  final String fullName;
  final String email;
  final String avatarUrl;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl = '',
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        fullName: (json['fullName'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        avatarUrl: (json['avatarUrl'] ?? '').toString(),
      );

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.last.substring(0, 1).toUpperCase();
  }
}

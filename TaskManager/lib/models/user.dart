class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String avatarUrl;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl = '',
  });

  /// Nhận Map (đã populate) hoặc String (chỉ có id).
  factory AppUser.fromJson(dynamic json) {
    if (json is Map) {
      return AppUser(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        fullName: (json['fullName'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        avatarUrl: (json['avatarUrl'] ?? '').toString(),
      );
    }
    return AppUser(id: json.toString(), fullName: '(Không rõ)', email: '');
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.last.substring(0, 1).toUpperCase();
  }
}

class Validators {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? required(String? v, [String field = 'Trường này']) {
    if (v == null || v.trim().isEmpty) return '$field không được để trống';
    return null;
  }

  static String? fullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Họ tên không được để trống';
    if (v.trim().length > 100) return 'Họ tên tối đa 100 ký tự';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email không được để trống';
    if (!_emailRegex.hasMatch(v.trim())) return 'Email không hợp lệ';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Mật khẩu không được để trống';
    if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (v) {
      if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
      if (v != original()) return 'Mật khẩu xác nhận không khớp';
      return null;
    };
  }
}

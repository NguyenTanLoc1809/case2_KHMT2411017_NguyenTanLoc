class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? v, [String label = 'Trường này']) =>
      (v == null || v.trim().isEmpty) ? '$label không được để trống' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email không được để trống';
    if (!_email.hasMatch(v.trim())) return 'Email không hợp lệ';
    return null;
  }

  static String? password(String? v, [String label = 'Mật khẩu']) {
    if (v == null || v.isEmpty) return '$label không được để trống';
    if (v.length < 6) return '$label phải có ít nhất 6 ký tự';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (v != original) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  static String? fullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Họ tên không được để trống';
    if (v.trim().length > 100) return 'Họ tên tối đa 100 ký tự';
    return null;
  }
}

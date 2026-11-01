import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('password', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('123'), isNotNull);
    });

    test('confirmPassword', () {
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
      expect(Validators.confirmPassword('abc', 'abc123'), isNotNull);
    });
  });
}

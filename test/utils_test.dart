import 'package:flutter_test/flutter_test.dart';
import 'package:arrendaoco/utils/validators.dart';
import 'package:arrendaoco/utils/password_hasher.dart';

void main() {
  group('Validators Tests', () {
    test('Email validation', () {
      expect(Validators.isValidEmail('user@gmail.com'), true);
      expect(Validators.isValidEmail('invalid'), false);
      expect(Validators.isValidEmail('user@'), false);
      expect(Validators.isValidEmail('@gmail.com'), false);
    });

    test('Password validation', () {
      expect(Validators.isValidPassword('Password123'), true);
      expect(Validators.isValidPassword('weak'), false);
      expect(Validators.isValidPassword('PASSWORD123'), false);
      expect(Validators.isValidPassword('password123'), false);
    });

    test('XSS detection', () {
      expect(Validators.containsXSS('<script>alert("xss")</script>'), true);
      expect(Validators.containsXSS('Normal text'), false);
      expect(Validators.containsXSS('<img onerror="hack()">'), true);
    });

    test('Price validation', () {
      expect(Validators.isValidPrice(5000), true);
      expect(Validators.isValidPrice(-100), false);
      expect(Validators.isValidPrice('12500.50'), true);
      expect(Validators.isValidPrice('abc'), false);
    });

    test('Name validation', () {
      expect(Validators.isValidName('Juan Pérez'), true);
      expect(Validators.isValidName("O'Connor"), true);
      expect(Validators.isValidName('J'), false);
      expect(Validators.isValidName('123'), false);
    });
  });

  group('PasswordHasher Tests', () {
    test('Hash generation', () {
      final hash1 = PasswordHasher.hashPassword('MyPassword123');
      final hash2 = PasswordHasher.hashPassword('MyPassword123');

      // Same password should generate same hash
      expect(hash1, hash2);

      // Hash should be different from password
      expect(hash1, isNot('MyPassword123'));

      // Hash should be 64 characters (SHA-256)
      expect(hash1.length, 64);
    });

    test('Password verification', () {
      final password = 'SecurePass123';
      final hash = PasswordHasher.hashPassword(password);

      // Correct password should verify
      expect(PasswordHasher.verifyPassword(password, hash), true);

      // Wrong password should not verify
      expect(PasswordHasher.verifyPassword('WrongPass', hash), false);
    });

    test('Reset token generation', () {
      final token1 = PasswordHasher.generateResetToken('user@gmail.com');

      // Token should be generated
      expect(token1, isNotEmpty);
      expect(token1.length, 64);

      // Different calls should generate different tokens (due to timestamp)
      Future.delayed(Duration(milliseconds: 10), () {
        final token2 = PasswordHasher.generateResetToken('user@gmail.com');
        expect(token1, isNot(token2));
      });
    });
  });
}

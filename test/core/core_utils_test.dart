import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/core/security/password_hasher.dart';
import 'package:medilink/core/utils/validators.dart';

void main() {
  group('PasswordHasher', () {
    const hasher = PasswordHasher(iterations: 1000);

    test('vérifie le bon mot de passe et rejette un mauvais', () {
      final stored = hasher.hash('Medilink123');
      expect(stored, isNot(contains('Medilink123')));
      expect(hasher.verify('Medilink123', stored), isTrue);
      expect(hasher.verify('medilink123', stored), isFalse);
    });

    test('deux hachages du même mot de passe sont différents (sel aléatoire)', () {
      expect(hasher.hash('abc12345'), isNot(hasher.hash('abc12345')));
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email('a@b.tn'), isNull);
      expect(Validators.email('pas-un-email'), isNotNull);
    });

    test('téléphone tunisien', () {
      expect(Validators.phone('22 345 678'), isNull);
      expect(Validators.phone('+21622345678'), isNull);
      expect(Validators.phone('1234'), isNotNull);
    });

    test('mot de passe', () {
      expect(Validators.password('abcdefgh'), isNotNull);
      expect(Validators.password('abcdefg1'), isNull);
    });
  });
}

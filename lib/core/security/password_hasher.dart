import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hachage des mots de passe : PBKDF2-HMAC-SHA256 + sel aléatoire.
///
/// Cahier des charges §13.1 : les mots de passe ne sont jamais stockés en clair.
/// Format stocké dans `users.password_hash` : `pbkdf2$<iterations>$<sel>$<hash>`
/// (sel et hash en base64).
class PasswordHasher {
  const PasswordHasher({this.iterations = 10000});

  final int iterations;

  static const int _saltLength = 16;
  static const int _keyLength = 32;

  String hash(String password) {
    final random = Random.secure();
    final salt = Uint8List.fromList(List.generate(_saltLength, (_) => random.nextInt(256)));
    final key = _pbkdf2(utf8.encode(password), salt, iterations);
    return 'pbkdf2\$$iterations\$${base64Encode(salt)}\$${base64Encode(key)}';
  }

  bool verify(String password, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null) return false;
    final salt = base64Decode(parts[2]);
    final expected = base64Decode(parts[3]);
    final actual = _pbkdf2(utf8.encode(password), salt, rounds);
    return _constantTimeEquals(actual, expected);
  }

  static Uint8List _pbkdf2(List<int> password, List<int> salt, int rounds) {
    final hmac = Hmac(sha256, password);
    final blocks = (_keyLength / 32).ceil();
    final output = BytesBuilder();
    for (var block = 1; block <= blocks; block++) {
      final blockIndex = Uint8List(4)..buffer.asByteData().setUint32(0, block);
      var u = hmac.convert([...salt, ...blockIndex]).bytes;
      final t = Uint8List.fromList(u);
      for (var i = 1; i < rounds; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      output.add(t);
    }
    return Uint8List.fromList(output.toBytes().sublist(0, _keyLength));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

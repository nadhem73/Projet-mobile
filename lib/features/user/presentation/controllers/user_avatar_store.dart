import 'package:flutter/foundation.dart';
import 'package:medilink/features/user/data/repositories/profile_repository.dart';

/// Cache des photos de profil. Les en-têtes et l'écran profil l'écoutent, ce qui
/// les met à jour dès qu'une nouvelle photo est enregistrée.
class UserAvatarStore extends ChangeNotifier {
  UserAvatarStore(this._profiles);

  final ProfileRepository _profiles;
  final Map<int, Uint8List?> _cache = {};
  final Set<int> _loading = {};

  /// Photo déjà chargée (sinon null et le chargement est lancé en arrière-plan).
  Uint8List? peek(int userId) {
    if (!_cache.containsKey(userId) && !_loading.contains(userId)) load(userId);
    return _cache[userId];
  }

  Future<Uint8List?> load(int userId) async {
    _loading.add(userId);
    try {
      _cache[userId] = await _profiles.avatar(userId);
    } finally {
      _loading.remove(userId);
    }
    notifyListeners();
    return _cache[userId];
  }

  Future<void> set(int userId, Uint8List? bytes) async {
    await _profiles.setAvatar(userId, bytes);
    _cache[userId] = bytes;
    notifyListeners();
  }

  void clear() => _cache.clear();
}
